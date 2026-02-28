import 'scenario_model.dart';

/// Onboarding completion profile returned by POST /onboarding/complete.
///
/// [scenarios] — 5 AI-generated learning scenarios displayed on Screen 08.
class OnboardingProfile {
  final String? userId;
  final List<Scenario> scenarios;
  final Map<String, dynamic>? preferences;

  const OnboardingProfile({
    this.userId,
    required this.scenarios,
    this.preferences,
  });

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    return OnboardingProfile(
      userId: json['userId'] as String?,
      scenarios: (json['scenarios'] as List<dynamic>?)
              ?.map((e) => Scenario.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }
}
