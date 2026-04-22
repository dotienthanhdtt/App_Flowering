import 'package:dio/dio.dart' hide Options;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:uuid/uuid.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/audio/tts-service.dart';
import '../../../core/services/audio/voice-input-service.dart';
import '../../../core/services/language-context-service.dart';
import '../../../core/services/translation-service.dart';
import '../../chat/models/chat_message_model.dart';
import '../../chat/widgets/word-translation-sheet-loader.dart';
import '../models/scenario_chat_turn_request.dart';
import '../services/scenario_chat_service.dart';

part 'scenario_chat_controller_messaging.dart';
part 'scenario_chat_controller_translation.dart';
part 'scenario_chat_controller_voice.dart';
part 'scenario_chat_controller_grammar.dart';

/// Controller for the /scenario/chat feature. Mirrors the AI onboarding
/// chat's capabilities (TTS, STT, translation, grammar correction) while
/// driving the scenario-scoped chat turn endpoint.
class ScenarioChatController extends BaseController {
  final String scenarioId;
  final String scenarioTitle;
  final bool _forceNewPending;

  ScenarioChatController(
    this.scenarioId,
    this.scenarioTitle,
    this._forceNewPending,
  );

  // Services
  final ApiClient _apiClient = Get.find();
  final TtsService _ttsService = Get.find();
  final VoiceInputService _voiceInputService = Get.find();
  final LanguageContextService _langCtx = Get.find();

  // Reactive state
  final messages = <ChatMessage>[].obs;
  final isSending = false.obs;
  final completed = false.obs;
  final kickoffFailed = false.obs;
  final turn = 0.obs;
  final maxTurns = 0.obs;

  String? conversationId;

  final scrollController = ScrollController();
  final textEditingController = TextEditingController();

  // Voice input state (delegated to VoiceInputService)
  RxBool get isRecording => _voiceInputService.isListening;
  RxDouble get recordingAmplitude => _voiceInputService.amplitude;
  Rx<Duration> get recordingDuration => _voiceInputService.listeningDuration;

  // View-layer accessors for services
  TtsService get ttsService => _ttsService;
  VoiceInputService get voiceInputService => _voiceInputService;

  ScenarioChatService get _service => Get.find<ScenarioChatService>();
  TranslationService get _translation => Get.find<TranslationService>();
  String get _targetLanguage => _langCtx.activeCode.value ?? '';

  @override
  void onInit() {
    super.onInit();
    sendKickoff();
  }

  @override
  void onClose() {
    scrollController.dispose();
    textEditingController.dispose();
    super.onClose();
  }

  // ─── Message helpers (used across part files) ─────────────────────

  static const _typingId = '__typing__';

  void _addTypingPlaceholder() {
    messages.add(ChatMessage(
      id: _typingId,
      type: ChatMessageType.aiTyping,
      timestamp: DateTime.now(),
    ));
    _scrollToBottom();
  }

  void _removeTypingPlaceholder() {
    messages.removeWhere((m) => m.id == _typingId);
  }

  void _addAiMessage(String text) {
    if (text.trim().isEmpty) return;
    messages.add(ChatMessage(
      id: const Uuid().v4(),
      type: ChatMessageType.aiText,
      text: text,
      timestamp: DateTime.now(),
    ));
    _scrollToBottom();

    // Auto-play AI messages via TTS if user has opted in
    if (_ttsService.autoPlayEnabled) {
      _ttsService.speak(text, language: _targetLanguage);
    }
  }

  void _addUserMessage(String text, {String? messageId}) {
    messages.add(ChatMessage(
      id: messageId ?? const Uuid().v4(),
      type: ChatMessageType.userText,
      text: text,
      timestamp: DateTime.now(),
    ));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── TTS playback ─────────────────────────────────────────────────

  /// Speak an AI message via TTS.
  void playAudio(String messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final text = messages[index].text;
    if (text == null || text.trim().isEmpty) return;
    _ttsService.speak(text, language: _targetLanguage);
  }

  /// Stop any in-flight TTS playback.
  void stopSpeaking() => _ttsService.stop();
}
