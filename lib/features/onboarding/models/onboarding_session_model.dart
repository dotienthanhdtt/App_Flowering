/// Response model for POST /onboarding/start and POST /onboarding/chat.
///
/// [sessionToken] — returned by /start; null in /chat responses.
/// [isLastTurn] — when true, caller should trigger POST /onboarding/complete.
/// [reply] — AI message text.
class OnboardingSession {
  final String? sessionToken;
  final String? messageId;
  final int turnNumber;
  final int maxTurns;
  final bool isLastTurn;
  final String? reply;
  final List<String> quickReplies;
  final DateTime? expiresAt;

  const OnboardingSession({
    this.sessionToken,
    this.messageId,
    required this.turnNumber,
    this.maxTurns = 10,
    required this.isLastTurn,
    this.reply,
    this.quickReplies = const [],
    this.expiresAt,
  });

  factory OnboardingSession.fromJson(Map<String, dynamic> json) {
    final turnCount = json['turn_number'] as int? ??
        json['turn_count'] as int? ??
        json['turnNumber'] as int? ??
        0;
    final maxTurns = json['max_turns'] as int? ?? 10;

    return OnboardingSession(
      sessionToken: json['session_token'] as String? ??
          json['session_id'] as String? ??
          json['sessionToken'] as String?,
      messageId: json['message_id'] as String? ??
          json['messageId'] as String?,
      turnNumber: turnCount,
      maxTurns: maxTurns,
      isLastTurn: json['is_last_turn'] as bool? ??
          json['isLastTurn'] as bool? ??
          turnCount >= maxTurns,
      reply: json['response'] as String? ??
          json['reply'] as String? ??
          json['floraMessage'] as String?,
      quickReplies: (json['quick_replies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['quickReplies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
    );
  }
}
