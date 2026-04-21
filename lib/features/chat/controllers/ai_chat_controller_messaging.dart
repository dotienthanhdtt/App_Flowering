part of 'ai_chat_controller.dart';

// Messaging methods for AiChatController.
// Declared as extension within the same library part — has access to all
// library-private (`_`) identifiers defined in ai_chat_controller.dart.

extension AiChatControllerMessaging on AiChatController {
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
        data: {'conversation_id': _conversationId, 'message': trimmed},
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
}
