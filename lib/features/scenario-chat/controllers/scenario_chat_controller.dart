import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/translation-service.dart';
import '../../chat/models/chat_message_model.dart';
import '../../chat/widgets/word-translation-sheet-loader.dart';
import '../models/scenario_chat_turn_request.dart';
import '../services/scenario_chat_service.dart';

class ScenarioChatController extends BaseController {
  final String scenarioId;
  final String scenarioTitle;
  final bool _forceNewPending;

  ScenarioChatController(
    this.scenarioId,
    this.scenarioTitle,
    this._forceNewPending,
  );

  final messages = <ChatMessage>[].obs;
  final isSending = false.obs;
  final completed = false.obs;
  final kickoffFailed = false.obs;
  final turn = 0.obs;
  final maxTurns = 0.obs;

  String? conversationId;

  final scrollController = ScrollController();

  ScenarioChatService get _service => Get.find<ScenarioChatService>();

  @override
  void onInit() {
    super.onInit();
    _sendKickoff();
  }

  Future<void> _sendKickoff() async {
    kickoffFailed.value = false;
    _addTypingPlaceholder();
    await apiCall(
      () => _service.chat(ScenarioChatTurnRequest(
        scenarioId: scenarioId,
        message: '',
        forceNew: _forceNewPending ? true : null,
      )),
      showLoading: false,
      onSuccess: (resp) {
        _removeTypingPlaceholder();
        if (resp.isSuccess && resp.data != null) {
          final data = resp.data!;
          conversationId = data.conversationId;
          turn.value = data.turn;
          maxTurns.value = data.maxTurns;
          completed.value = data.completed;
          _addAiMessage(data.reply);
        }
      },
      onError: (e) {
        _removeTypingPlaceholder();
        _handleChatError(e, isKickoff: true);
      },
    );
  }

  Future<void> retryKickoff() => _sendKickoff();

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSending.value || completed.value) return;

    _addUserMessage(trimmed);
    isSending.value = true;
    _addTypingPlaceholder();

    await apiCall(
      () => _service.chat(ScenarioChatTurnRequest(
        scenarioId: scenarioId,
        message: trimmed,
        conversationId: conversationId,
      )),
      showLoading: false,
      onSuccess: (resp) {
        _removeTypingPlaceholder();
        if (resp.isSuccess && resp.data != null) {
          final data = resp.data!;
          conversationId = data.conversationId;
          turn.value = data.turn;
          maxTurns.value = data.maxTurns;
          completed.value = data.completed;
          _addAiMessage(data.reply);
        }
        isSending.value = false;
      },
      onError: (e) {
        _removeTypingPlaceholder();
        isSending.value = false;
        _handleChatError(e);
      },
    );
  }

  // ─── Private helpers ───────────────────────────────────────────────

  void _handleChatError(ApiException e, {bool isKickoff = false}) {
    if (e is ForbiddenException) {
      Get.snackbar(
        'error'.tr,
        'scenario_chat_premium_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
      return;
    }
    if (isKickoff) {
      kickoffFailed.value = true;
    } else {
      Get.snackbar(
        'error'.tr,
        'scenario_chat_error_send'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

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
    messages.add(ChatMessage(
      id: const Uuid().v4(),
      type: ChatMessageType.aiText,
      text: text,
      timestamp: DateTime.now(),
    ));
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    messages.add(ChatMessage(
      id: const Uuid().v4(),
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

  // ─── Translation ──────────────────────────────────────────────────

  TranslationService get _translation => Get.find<TranslationService>();

  /// Toggle sentence translation. First tap fetches; subsequent taps toggle.
  Future<void> toggleTranslation(String messageId) async {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final msg = messages[index];

    if (msg.translatedText != null) {
      msg.showTranslation = !msg.showTranslation;
      messages.refresh();
      if (msg.showTranslation) _scrollToBottom();
      return;
    }

    final text = msg.text;
    if (text == null || text.isEmpty) return;

    try {
      final result = await _translation.translateContent(
        text,
        conversationId: conversationId,
      );
      msg.translatedText = result.translation;
      msg.showTranslation = true;
      messages.refresh();
      _scrollToBottom();
    } on ApiException catch (e) {
      Get.snackbar('', e.userMessage, snackPosition: SnackPosition.BOTTOM);
    }
  }

  void onWordTap(String word) {
    final clean = word
        .replaceAll(RegExp(r"[^\p{L}\p{N}'\-]", unicode: true), '')
        .trim();
    if (clean.isEmpty) return;
    final ctx = Get.context;
    if (ctx == null) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordTranslationSheetLoader(
        word: clean,
        conversationId: conversationId,
      ),
    );
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
