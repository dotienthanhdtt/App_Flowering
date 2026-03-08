/// Message types for the AI onboarding chat flow
enum ChatMessageType {
  aiText, // AI text bubble with optional translation
  userText, // User text bubble
  quickReplies, // Horizontal quick-reply chips from API
  aiTyping, // Animated three-dot indicator
}

/// Single message in the onboarding conversation
class ChatMessage {
  final String id;
  final ChatMessageType type;
  final String? text;
  String? translatedText;
  bool showTranslation;
  final List<String>? quickReplies;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.type,
    this.text,
    this.translatedText,
    this.showTranslation = false,
    this.quickReplies,
    required this.timestamp,
  });
}
