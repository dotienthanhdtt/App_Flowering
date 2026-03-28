import 'scenario_model.dart';

/// Onboarding completion profile returned by POST /onboarding/complete.
///
/// [scenarios] — AI-generated learning scenarios displayed on Screen 08.
/// [extractedProfile] — new API shape with languages, interests, level.
class OnboardingProfile {
  final List<Scenario> scenarios;
  final Map<String, dynamic>? extractedProfile;

  const OnboardingProfile({
    required this.scenarios,
    this.extractedProfile,
  });

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    // New API returns extracted_profile with different shape
    final extracted = json['extracted_profile'] as Map<String, dynamic>? ??
        json['extractedProfile'] as Map<String, dynamic>?;

    return OnboardingProfile(
      scenarios: (json['scenarios'] as List<dynamic>?)
              ?.map((e) => Scenario.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extractedProfile: extracted,
    );
  }
}
