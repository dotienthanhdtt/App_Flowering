/// Response model for POST /onboarding/start and POST /onboarding/chat.
///
/// [sessionToken] — persisted in OnboardingController + StorageService.
/// [isLastTurn] — when true, caller should trigger POST /onboarding/complete.
class OnboardingSession {
  final String sessionToken;
  final int turnNumber;
  final bool isLastTurn;
  final String? floraMessage;
  final List<String> quickReplies;

  const OnboardingSession({
    required this.sessionToken,
    required this.turnNumber,
    required this.isLastTurn,
    this.floraMessage,
    this.quickReplies = const [],
  });

  factory OnboardingSession.fromJson(Map<String, dynamic> json) {
    return OnboardingSession(
      sessionToken: json['sessionToken'] as String,
      turnNumber: json['turnNumber'] as int? ?? 0,
      isLastTurn: json['isLastTurn'] as bool? ?? false,
      floraMessage: json['floraMessage'] as String?,
      quickReplies: (json['quickReplies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
