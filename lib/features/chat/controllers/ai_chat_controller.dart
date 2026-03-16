import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
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
  final OnboardingController _onboardingCtrl = Get.find();
  final StorageService _storageService = Get.find();

  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final isChatComplete = false.obs;
  final progress = 0.0.obs;

  // Voice recording state
  final isRecording = false.obs;
  final recordingDuration = 0.obs;
  Timer? _recordingTimer;

  final ScrollController scrollController = ScrollController();
  final TextEditingController textEditingController = TextEditingController();

  String? _sessionToken;

  @override
  void onInit() {
    super.onInit();
    _startSession();
  }

  Future<void> _startSession() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.post<OnboardingSession>(
        ApiEndpoints.onboardingStart,
        data: {
          'nativeLanguage': _onboardingCtrl.selectedNativeLanguage.value,
          'targetLanguage': _onboardingCtrl.selectedLearningLanguage.value,
        },
        fromJson: (data) => OnboardingSession.fromJson(data as Map<String, dynamic>),
      );
      if (response.isSuccess && response.data != null) {
        final session = response.data!;
        _sessionToken = session.sessionToken;
        await _storageService.setPreference('onboarding_session_token', _sessionToken);
        _onboardingCtrl.sessionToken = _sessionToken;

        _addAiMessage(session.reply ?? '');
        if (session.quickReplies.isNotEmpty) {
          _addQuickReplies(session.quickReplies);
        }
      } else {
        errorMessage.value = response.message;
      }
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;
    } catch (_) {
      errorMessage.value = 'unknown_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retrySession() => _startSession();

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sessionToken == null || isChatComplete.value) return;

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
        data: {'sessionToken': _sessionToken, 'message': trimmed},
        fromJson: (data) => OnboardingSession.fromJson(data as Map<String, dynamic>),
      );
      if (response.isSuccess && response.data != null) {
        final session = response.data!;
        progress.value = (session.turnNumber / 10).clamp(0.0, 1.0);

        _addAiMessage(session.reply ?? '', messageId: session.messageId);
        if (session.quickReplies.isNotEmpty) {
          _addQuickReplies(session.quickReplies);
        }

        if (session.isLastTurn) {
          await _completeOnboarding();
        }
      } else {
        errorMessage.value = response.message;
      }
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;
    } catch (_) {
      errorMessage.value = 'unknown_error'.tr;
    } finally {
      isTyping.value = false;
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
      return;
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.translate,
        data: {
          'type': 'sentence',
          'messageId': messageId,
          'sourceLang': _onboardingCtrl.selectedLearningLanguage.value,
          'targetLang': _onboardingCtrl.selectedNativeLanguage.value,
          'sessionToken': _sessionToken,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        msg.translatedText = response.data!['translation'] as String?;
        msg.showTranslation = true;
        messages.refresh();
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
    final cleanWord = word.replaceAll(RegExp(r"[^\w'\-]"), '').trim();
    if (cleanWord.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordTranslationSheetLoader(
        word: cleanWord,
        sessionToken: _sessionToken,
      ),
    );
  }

  /// Placeholder for TTS playback
  void playAudio(String messageId) {
    // TODO: Integrate TTS service
  }

  /// Skip onboarding and navigate directly to scenario gift
  void skipOnboarding() {
    Get.toNamed(AppRoutes.onboardingScenarioGift);
  }

  // Voice recording methods
  void startRecording() {
    isRecording.value = true;
    recordingDuration.value = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      recordingDuration.value++;
    });
  }

  void stopRecording() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    isRecording.value = false;
    // TODO: Process recorded audio and send as message
  }

  void cancelRecording() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    isRecording.value = false;
    recordingDuration.value = 0;
  }

  /// Toggle grammar correction visibility for a user message
  void toggleCorrection(String messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    messages[index].showCorrection = !messages[index].showCorrection;
    messages.refresh();
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
          'previousAiMessage': previousAiMessage,
          'userMessage': userText,
          'targetLanguage': _onboardingCtrl.selectedLearningLanguage.value,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        final corrected = response.data!['correctedText'] as String?;
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
        data: {'sessionToken': _sessionToken},
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
    messages.add(ChatMessage(
      id: messageId ?? 'ai_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatMessageType.aiText,
      text: text,
      timestamp: DateTime.now(),
    ));
    _scrollToBottom();
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
    _recordingTimer?.cancel();
    scrollController.dispose();
    textEditingController.dispose();
    super.onClose();
  }
}
