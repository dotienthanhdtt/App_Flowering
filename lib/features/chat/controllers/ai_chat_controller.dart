import 'package:dio/dio.dart' hide Options;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/audio/tts-service.dart';
import '../../../core/services/audio/voice-input-service.dart';
import '../../../core/services/storage_service.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../../onboarding/models/onboarding_profile_model.dart';
import '../../onboarding/models/onboarding_session_model.dart';
import '../models/chat_message_model.dart';
import '../widgets/word-translation-sheet-loader.dart';

/// Manages the AI onboarding chat flow using real /onboarding/* endpoints.
/// Session lifecycle: start → chat turns → complete → navigate to scenario gift.
class AiChatController extends BaseController {
  final ApiClient _apiClient = Get.find();
  final TtsService _ttsService = Get.find();
  final VoiceInputService _voiceInputService = Get.find();
  final OnboardingController _onboardingCtrl = Get.find();
  final StorageService _storageService = Get.find();

  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final isChatComplete = false.obs;
  final progress = 0.0.obs;

  // Chat metadata from route arguments
  final chatTitle = 'Chat'.obs;
  final contextDescription = ''.obs;

  // Voice input state (delegated to VoiceInputService)
  RxBool get isRecording => _voiceInputService.isListening;
  RxDouble get recordingAmplitude => _voiceInputService.amplitude;
  Rx<Duration> get recordingDuration => _voiceInputService.listeningDuration;

  // TTS state (delegated to TtsService)
  TtsService get ttsService => _ttsService;
  VoiceInputService get voiceInputService => _voiceInputService;

  final ScrollController scrollController = ScrollController();
  final TextEditingController textEditingController = TextEditingController();

  String? _conversationId;

  String get _targetLanguage =>
      _onboardingCtrl.selectedLearningLanguage.value;

  @override
  void onInit() {
    super.onInit();
    chatTitle.value = Get.arguments?['chatTitle'] ?? 'Chat';
    contextDescription.value = Get.arguments?['contextDescription'] ?? '';
    _createSession();
  }

  /// Creates the onboarding session via unified /onboarding/chat endpoint
  /// (Mode A — no conversationId). Response includes greeting + conversationId
  /// in a single round-trip.
  Future<void> _createSession() async {
    isTyping.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.post<OnboardingSession>(
        ApiEndpoints.onboardingChat,
        data: {
          'nativeLanguage': _onboardingCtrl.selectedNativeLanguage.value,
          'targetLanguage': _onboardingCtrl.selectedLearningLanguage.value,
        },
        fromJson: (data) => OnboardingSession.fromJson(data as Map<String, dynamic>),
      );
      if (response.isSuccess && response.data != null) {
        final session = response.data!;
        _conversationId = session.conversationId;
        await _storageService.setPreference('onboarding_conversation_id', _conversationId);
        _onboardingCtrl.conversationId = _conversationId;
        await _handleChatResponse(session);
      } else {
        errorMessage.value = response.message;
      }
    } on ApiException catch (e) {
      errorMessage.value = _mapOnboardingError(e, isCreate: true);
    } catch (_) {
      errorMessage.value = 'unknown_error'.tr;
    } finally {
      isTyping.value = false;
    }
  }

  Future<void> retrySession() => _createSession();

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (_conversationId == null || isChatComplete.value) return;

    textEditingController.clear();
    messages.removeWhere((m) => m.type == ChatMessageType.quickReplies);
    errorMessage.value = '';

    final lastAiMessage = _getLastAiMessageText();
    final userMessageId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _addUserMessage(trimmed, messageId: userMessageId);
    isTyping.value = true;

    // Fire grammar check in parallel (non-blocking)
    _checkGrammar(userMessageId, trimmed, lastAiMessage);

    try {
      final response = await _apiClient.post<OnboardingSession>(
        ApiEndpoints.onboardingChat,
        data: {'conversationId': _conversationId, 'message': trimmed},
        fromJson: (data) => OnboardingSession.fromJson(data as Map<String, dynamic>),
      );
      if (response.isSuccess && response.data != null) {
        await _handleChatResponse(response.data!);
      } else {
        errorMessage.value = response.message;
      }
    } on ApiException catch (e) {
      errorMessage.value = _mapOnboardingError(e, isCreate: false);
    } catch (_) {
      errorMessage.value = 'unknown_error'.tr;
    } finally {
      isTyping.value = false;
    }
  }

  /// Maps onboarding API errors to user-facing copy.
  /// 429 differentiates create (5/hr) vs chat (30/hr) rate limits.
  /// 404 → invalid conversationId; 400 → expired or max turns reached.
  String _mapOnboardingError(ApiException e, {required bool isCreate}) {
    switch (e.statusCode) {
      case 429:
        return isCreate
            ? 'chat_rate_limit_create'.tr
            : 'chat_rate_limit_chat'.tr;
      case 404:
        _clearSession();
        return 'chat_session_invalid'.tr;
      case 400:
        _clearSession();
        return 'chat_session_expired'.tr;
      default:
        return e.userMessage;
    }
  }

  /// Clears local session state so the user can restart onboarding cleanly.
  void _clearSession() {
    _conversationId = null;
    _storageService.setPreference('onboarding_conversation_id', null);
    _onboardingCtrl.conversationId = null;
    isChatComplete.value = false;
  }

  /// Shared handler for chat API responses — updates progress, adds AI message, handles completion.
  Future<void> _handleChatResponse(OnboardingSession session) async {
    progress.value = (session.turnNumber / 10).clamp(0.0, 1.0);
    _addAiMessage(session.reply ?? '', messageId: session.messageId);
    if (session.quickReplies.isNotEmpty) {
      _addQuickReplies(session.quickReplies);
    }
    if (session.isLastTurn) {
      await _completeOnboarding();
    }
  }

  /// Toggle sentence translation. First tap calls API; subsequent taps toggle.
  Future<void> toggleTranslation(String messageId) async {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final msg = messages[index];

    // Already has translation — just toggle visibility
    if (msg.translatedText != null) {
      msg.showTranslation = !msg.showTranslation;
      messages.refresh();
      if (msg.showTranslation) _scrollToBottom();
      return;
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.translate,
        data: {
          'type': 'SENTENCE',
          'message_id': messageId,
          'source_lang': _onboardingCtrl.selectedLearningLanguage.value,
          'target_lang': _onboardingCtrl.selectedNativeLanguage.value,
          if (_conversationId != null) 'conversation_id': _conversationId,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        msg.translatedText = response.data!['translated_content'] as String? ??
            response.data!['translation'] as String?;
        msg.showTranslation = true;
        messages.refresh();
        _scrollToBottom();
      } else {
        Get.snackbar('', response.message,
            snackPosition: SnackPosition.BOTTOM);
      }
    } on ApiException catch (e) {
      Get.snackbar('', e.userMessage,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Open word translation bottom sheet for tapped word
  void onWordTap(String word, BuildContext context) {
    final cleanWord = word.replaceAll(RegExp(r"[^\p{L}\p{N}'\-]", unicode: true), '').trim();
    if (cleanWord.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordTranslationSheetLoader(
        word: cleanWord,
        conversationId: _conversationId,
        onSave: () => saveWord(cleanWord),
      ),
    );
  }

  /// Speak an AI message via TTS
  void playAudio(String messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final text = messages[index].text;
    if (text == null || text.trim().isEmpty) return;
    _ttsService.speak(text, language: _targetLanguage);
  }

  /// Stop TTS playback
  void stopSpeaking() => _ttsService.stop();

  /// Save word to vocabulary list
  void saveWord(String word) {
    // TODO: Implement save word to vocabulary list via API
  }

  /// Skip onboarding and navigate directly to scenario gift
  void skipOnboarding() {
    Get.toNamed(AppRoutes.onboardingScenarioGift);
  }

  // ─────────────────────────────────────────────────────────────────
  // Voice Input
  // ─────────────────────────────────────────────────────────────────

  Future<void> startRecording() async {
    if (isChatComplete.value) return;
    await _voiceInputService.startVoiceInput(language: _targetLanguage);
  }

  Future<void> stopRecording() async {
    final result = await _voiceInputService.stopVoiceInput();
    if (result.transcribedText.isNotEmpty) {
      sendMessage(result.transcribedText);
      // iOS: fire-and-forget backend transcription for better accuracy
      if (result.audioFilePath != null) {
        _sendAudioForTranscription(result.audioFilePath!);
      }
    }
  }

  Future<void> cancelRecording() async {
    await _voiceInputService.cancelVoiceInput();
  }

  /// Fire-and-forget: upload audio to /ai/transcribe, update last user message if successful
  Future<void> _sendAudioForTranscription(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath, filename: 'voice.m4a'),
        if (_conversationId != null) 'conversation_id': _conversationId,
      });
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.transcribeAudio,
        data: formData,
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        final accurate = response.data!['text'] as String?;
        if (accurate != null && accurate.isNotEmpty) {
          // Update the last user message with accurate transcription
          for (int i = messages.length - 1; i >= 0; i--) {
            if (messages[i].type == ChatMessageType.userText) {
              messages[i].text = accurate;
              messages.refresh();
              break;
            }
          }
        }
      }
    } catch (_) {
      // Silent fail — STT text already sent, backend transcription is best-effort
    }
  }

  /// Toggle grammar correction visibility for a user message
  void toggleCorrection(String messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    messages[index].showCorrection = !messages[index].showCorrection;
    messages.refresh();
    if (messages[index].showCorrection) _scrollToBottom();
  }

  /// Get the last AI message text for grammar correction context
  String? _getLastAiMessageText() {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].type == ChatMessageType.aiText) {
        return messages[i].text;
      }
    }
    return null;
  }

  /// Fire-and-forget grammar check in parallel with chat API
  Future<void> _checkGrammar(
    String messageId,
    String userText,
    String? previousAiMessage,
  ) async {
    if (previousAiMessage == null) return;
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.chatCorrect,
        data: {
          'previous_ai_message': previousAiMessage,
          'user_message': userText,
          'target_language': _onboardingCtrl.selectedLearningLanguage.value,
          if (_conversationId != null) 'conversation_id': _conversationId,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        final corrected = response.data!['corrected_text'] as String?;
        if (corrected != null) {
          final idx = messages.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            messages[idx].correctedText = corrected;
            messages[idx].showCorrection = true;
            messages.refresh();
          }
        }
      }
    } catch (_) {
      // Silent fail — grammar check is non-critical
    }
  }

  Future<void> _completeOnboarding() async {
    isChatComplete.value = true;
    try {
      final response = await _apiClient.post<OnboardingProfile>(
        ApiEndpoints.onboardingComplete,
        data: {'conversation_id': _conversationId},
        fromJson: (data) => OnboardingProfile.fromJson(data as Map<String, dynamic>),
      );
      if (response.isSuccess && response.data != null) {
        _onboardingCtrl.onboardingProfile = response.data;
      }
    } on ApiException {
      // Non-fatal: navigate regardless so user is not stuck
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      Get.toNamed(AppRoutes.onboardingScenarioGift);
    }
  }

  void _addAiMessage(String text, {String? messageId}) {
    if (text.trim().isEmpty) return;
    messages.add(ChatMessage(
      id: messageId ?? 'ai_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.aiText,
      text: text,
      timestamp: DateTime.now(),
    ));
    _scrollToBottom();

    // Auto-play AI messages if enabled
    if (_ttsService.autoPlayEnabled) {
      _ttsService.speak(text, language: _targetLanguage);
    }
  }

  void _addUserMessage(String text, {String? messageId}) {
    messages.add(ChatMessage(
      id: messageId ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.userText,
      text: text,
      timestamp: DateTime.now(),
    ));
    _scrollToBottom();
  }

  void _addQuickReplies(List<String> replies) {
    messages.add(ChatMessage(
      id: 'qr_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.quickReplies,
      quickReplies: replies,
      timestamp: DateTime.now(),
    ));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    textEditingController.dispose();
    super.onClose();
  }
}
