part of 'scenario_chat_controller.dart';

// Chat turn flow for ScenarioChatController — kickoff + send + error mapping.
// Uses library-private helpers (_addAiMessage, _addTypingPlaceholder, …) and
// the `conversationId`/`turn`/`maxTurns`/`completed` state on the main class.

extension ScenarioChatControllerMessaging on ScenarioChatController {
  /// First turn: sends an empty message so the backend seeds the conversation
  /// with its scenario-opener greeting.
  Future<void> sendKickoff() async {
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
          if (data.conversationId.isNotEmpty) {
            conversationId = data.conversationId;
          }
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

  Future<void> retryKickoff() => sendKickoff();

  /// Standard turn: user text → /scenario/chat → AI reply. Also fires grammar
  /// check in parallel so the "Try instead" card can render when ready.
  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSending.value || completed.value) return;

    textEditingController.clear();
    final lastAiMessage = _getLastAiMessageText();
    final userMessageId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _addUserMessage(trimmed, messageId: userMessageId);
    isSending.value = true;
    _addTypingPlaceholder();

    _checkGrammar(userMessageId, trimmed, lastAiMessage);

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
          if (data.conversationId.isNotEmpty) {
            conversationId = data.conversationId;
          }
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
}
