/// Response model for POST /onboarding/start and POST /onboarding/chat.
///
/// [sessionToken] — returned by /start; null in /chat responses.
/// [isLastTurn] — when true, caller should trigger POST /onboarding/complete.
/// [reply] — AI message text (field name varies: `floraMessage` or `reply`).
class OnboardingSession {
  final String? sessionToken;
  final String? messageId;
  final int turnNumber;
  final bool isLastTurn;
  final String? reply;
  final List<String> quickReplies;

  const OnboardingSession({
    this.sessionToken,
    this.messageId,
    required this.turnNumber,
    required this.isLastTurn,
    this.reply,
    this.quickReplies = const [],
  });

  factory OnboardingSession.fromJson(Map<String, dynamic> json) {
    return OnboardingSession(
      sessionToken: json['sessionToken'] as String?,
      messageId: json['messageId'] as String?,
      turnNumber: json['turnNumber'] as int? ?? 0,
      isLastTurn: json['isLastTurn'] as bool? ?? false,
      reply: json['reply'] as String? ?? json['floraMessage'] as String?,
      quickReplies: (json['quickReplies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
