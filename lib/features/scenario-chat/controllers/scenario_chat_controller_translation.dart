part of 'scenario_chat_controller.dart';

// Sentence + word translation helpers for ScenarioChatController.
// Sentence: toggles cached translation, fetching once on first tap.
// Word: opens the shared bottom sheet with per-word gloss.

extension ScenarioChatControllerTranslation on ScenarioChatController {
  /// Toggle sentence translation. First tap fetches from /ai/translate;
  /// subsequent taps flip visibility on the cached result.
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
}
