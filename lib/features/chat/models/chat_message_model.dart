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
  String? text;
  String? translatedText;
  bool showTranslation;
  final List<String>? quickReplies;
  final DateTime timestamp;
  String? correctedText;
  bool showCorrection;

  ChatMessage({
    required this.id,
    required this.type,
    this.text,
    this.translatedText,
    this.showTranslation = false,
    this.quickReplies,
    required this.timestamp,
    this.correctedText,
    this.showCorrection = true,
  });

  /// Parses a server message from `GET /onboarding/conversations/:id/messages`.
  /// Server shape: `{ id, role: 'user'|'assistant', content, created_at }`.
  /// Unknown roles fall back to `aiText` so forward-compat additions don't crash.
  factory ChatMessage.fromServerJson(Map<String, dynamic> json) {
    final role = json['role'] as String?;
    final rawTimestamp = json['created_at'] as String?;
    return ChatMessage(
      id: json['id'] as String? ??
          'srv_${DateTime.now().microsecondsSinceEpoch}',
      type: role == 'user' ? ChatMessageType.userText : ChatMessageType.aiText,
      text: json['content'] as String? ?? '',
      timestamp: rawTimestamp != null
          ? (DateTime.tryParse(rawTimestamp) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
