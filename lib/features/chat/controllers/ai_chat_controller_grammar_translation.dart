part of 'ai_chat_controller.dart';

// Grammar correction and translation methods for AiChatController.
// Declared as extension within the same library part — has access to all
// library-private (`_`) identifiers defined in ai_chat_controller.dart.

extension AiChatControllerGrammarTranslation on AiChatController {
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
          'target_language': _langCtx.activeCode.value,
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
}
