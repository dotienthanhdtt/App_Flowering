part of 'scenario_chat_controller.dart';

// Chat turn flow for ScenarioChatController — kickoff + send + error mapping.

extension ScenarioChatControllerMessaging on ScenarioChatController {
  void _applyServerState(ScenarioChatResponse r) {
    final s = r.scenario;
    if (s.conversationId.isNotEmpty) conversationId = s.conversationId;
    turn.value = s.turn;
    maxTurns.value = s.maxTurns;
    completed.value = s.status == ScenarioStatus.done;

    messages.value = _mergeWithServer(messages, r.messages);
    _scrollToBottom();

    if (!_isFirstLoad) _maybeAutoplayLatestAi();
    _isFirstLoad = false;
  }

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
          _applyServerState(resp.data!);
        }
      },
      onError: (e) {
        _removeTypingPlaceholder();
        _handleChatError(e, isKickoff: true);
      },
    );
  }

  Future<void> retryKickoff() => sendKickoff();

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
          _applyServerState(resp.data!);
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
