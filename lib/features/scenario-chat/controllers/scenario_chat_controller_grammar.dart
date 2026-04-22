part of 'scenario_chat_controller.dart';

// Grammar correction helpers for ScenarioChatController.
// Runs /ai/chat/correct in parallel with each user turn so the red
// "Try instead" card can render without blocking the main chat flow.

extension ScenarioChatControllerGrammar on ScenarioChatController {
  /// Toggle visibility of the stored grammar correction for a user message.
  void toggleCorrection(String messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    messages[index].showCorrection = !messages[index].showCorrection;
    messages.refresh();
    if (messages[index].showCorrection) _scrollToBottom();
  }

  /// Walks backward from the tail to find the most recent AI message text;
  /// used as the conversational context for /ai/chat/correct.
  String? _getLastAiMessageText() {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].type == ChatMessageType.aiText) {
        return messages[i].text;
      }
    }
    return null;
  }

  /// Fire-and-forget grammar check in parallel with the main chat API call.
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
          'target_language': _langCtx.activeCode.value,
          if (conversationId != null) 'conversation_id': conversationId,
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
      // Silent fail — grammar check is non-critical.
    }
  }
}
