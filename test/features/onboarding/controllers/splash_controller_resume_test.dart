import 'package:flutter_test/flutter_test.dart';
import 'package:flowering/app/routes/app-route-constants.dart';
import 'package:flowering/features/onboarding/controllers/splash_controller.dart';
import 'package:flowering/features/onboarding/models/onboarding_progress_model.dart';

void main() {
  group('computeOnboardingResumeTarget', () {
    test('empty progress routes to welcome', () {
      final target = computeOnboardingResumeTarget(OnboardingProgress.empty());
      expect(target, AppRoutes.onboardingWelcome);
    });

    test('native-lang only routes to learning-language screen', () {
      final target = computeOnboardingResumeTarget(
        const OnboardingProgress(nativeLang: LangCheckpoint(code: 'vi')),
      );
      expect(target, AppRoutes.onboardingLearningLanguage);
    });

    test('native + learning (no chat yet) routes to chat', () {
      final target = computeOnboardingResumeTarget(
        const OnboardingProgress(
          nativeLang: LangCheckpoint(code: 'vi'),
          learningLang: LangCheckpoint(code: 'en'),
        ),
      );
      expect(target, AppRoutes.chat);
    });

    test('active chat checkpoint routes to chat', () {
      final target = computeOnboardingResumeTarget(
        const OnboardingProgress(
          nativeLang: LangCheckpoint(code: 'vi'),
          learningLang: LangCheckpoint(code: 'en'),
          chat: ChatCheckpoint(conversationId: 'conv-uuid'),
        ),
      );
      expect(target, AppRoutes.chat);
    });

    test('profile_complete routes to scenario-gift (highest priority)', () {
      final target = computeOnboardingResumeTarget(
        const OnboardingProgress(
          nativeLang: LangCheckpoint(code: 'vi'),
          learningLang: LangCheckpoint(code: 'en'),
          chat: ChatCheckpoint(conversationId: 'conv-uuid'),
          profileComplete: true,
        ),
      );
      expect(target, AppRoutes.onboardingScenarioGift);
    });
  });
}
