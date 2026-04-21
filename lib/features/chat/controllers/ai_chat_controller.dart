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
import '../../../core/services/language-context-service.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../../onboarding/models/onboarding_profile_model.dart';
import '../../onboarding/models/onboarding_session_model.dart';
import '../../onboarding/services/onboarding_progress_service.dart';
import '../models/chat_message_model.dart';
import '../widgets/word-translation-sheet-loader.dart';

part 'ai_chat_controller_session.dart';
part 'ai_chat_controller_messaging.dart';
part 'ai_chat_controller_voice.dart';
part 'ai_chat_controller_grammar_translation.dart';

/// Manages the AI onboarding chat flow using real /onboarding/* endpoints.
/// Session lifecycle: start → chat turns → complete → navigate to scenario gift.
class AiChatController extends BaseController {
  final ApiClient _apiClient = Get.find();
  final TtsService _ttsService = Get.find();
  final VoiceInputService _voiceInputService = Get.find();
  final OnboardingController _onboardingCtrl = Get.find();
  final OnboardingProgressService _progressSvc = Get.find<OnboardingProgressService>();
  final LanguageContextService _langCtx = Get.find();

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

  String get _targetLanguage => _langCtx.activeCode.value ?? '';

  @override
  void onInit() {
    super.onInit();
    chatTitle.value = Get.arguments?['chatTitle'] ?? 'Chat';
    contextDescription.value = Get.arguments?['contextDescription'] ?? '';
    _bootstrapSession();
  }

  @override
  void onClose() {
    scrollController.dispose();
    textEditingController.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────
  // Message helpers (used across session, messaging, and voice parts)
  // ─────────────────────────────────────────────────────────────────

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
    Get.offNamed(AppRoutes.onboardingScenarioGift);
  }
}
