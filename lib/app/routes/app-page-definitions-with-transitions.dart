import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app-route-constants.dart';
import '../../features/onboarding/bindings/onboarding_binding.dart';
import '../../features/onboarding/bindings/splash_binding.dart';
import '../../features/onboarding/views/splash_screen.dart';
import '../../features/onboarding/views/welcome_problem_screen.dart';
import '../../features/onboarding/views/native_language_screen.dart';
import '../../features/onboarding/views/learning_language_screen.dart';
import '../../features/chat/bindings/ai_chat_binding.dart';
import '../../features/chat/views/ai_chat_screen.dart';

// Placeholder screen for initial setup
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title - Coming Soon',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// GetPage definitions with transitions and bindings
abstract class AppPages {
  /// Default transition configuration
  static const Transition defaultTransition = Transition.rightToLeft;
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOut;

  /// Initial route — splash handles auth check + routing
  static String get initialRoute => AppRoutes.splash;

  /// All app pages with routes, screens, and transitions
  static final List<GetPage> pages = [
    // Splash screen with fade transition
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    // Onboarding — welcome screens
    GetPage(
      name: AppRoutes.onboardingWelcome,
      page: () => const WelcomeProblemScreen(step: 0),
      binding: OnboardingBinding(),
      transition: Transition.fade,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: AppRoutes.onboardingWelcome2,
      page: () => const WelcomeProblemScreen(step: 1),
      binding: OnboardingBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),
    GetPage(
      name: AppRoutes.onboardingWelcome3,
      page: () => const WelcomeProblemScreen(step: 2),
      binding: OnboardingBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Onboarding — language selection
    GetPage(
      name: AppRoutes.onboardingNativeLanguage,
      page: () => const NativeLanguageScreen(),
      binding: OnboardingBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),
    GetPage(
      name: AppRoutes.onboardingLearningLanguage,
      page: () => const LearningLanguageScreen(),
      binding: OnboardingBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Auth screens
    GetPage(
      name: AppRoutes.login,
      page: () => const _PlaceholderScreen('Login'),
      // binding: AuthBinding(), // Will be uncommented when auth feature is ready
      transition: Transition.fade,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const _PlaceholderScreen('Register'),
      // binding: AuthBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Home screen with fade transition
    GetPage(
      name: AppRoutes.home,
      page: () => const _PlaceholderScreen('Home'),
      // binding: HomeBinding(),
      transition: Transition.fade,
      transitionDuration: defaultDuration,
    ),

    // Chat screen — AI onboarding flow (Screen 3)
    GetPage(
      name: AppRoutes.chat,
      page: () => const AiChatScreen(),
      binding: AiChatBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Lessons screens
    GetPage(
      name: AppRoutes.lessons,
      page: () => const _PlaceholderScreen('Lessons'),
      // binding: LessonBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),
    GetPage(
      name: AppRoutes.lessonDetail,
      page: () => const _PlaceholderScreen('Lesson Detail'),
      // binding: LessonBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Profile screen
    GetPage(
      name: AppRoutes.profile,
      page: () => const _PlaceholderScreen('Profile'),
      // binding: ProfileBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Settings screen
    GetPage(
      name: AppRoutes.settings,
      page: () => const _PlaceholderScreen('Settings'),
      // binding: SettingsBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Onboarding — scenario gift (Screen 08)
    GetPage(
      name: AppRoutes.onboardingScenarioGift,
      page: () => const _PlaceholderScreen('Scenario Gift'),
      binding: OnboardingBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Auth — signup (Screen 10)
    GetPage(
      name: AppRoutes.signup,
      page: () => const _PlaceholderScreen('Sign Up'),
      // binding: AuthBinding(), // Uncommented in Phase 05
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Auth — forgot password (Screen 12)
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const _PlaceholderScreen('Forgot Password'),
      // binding: AuthBinding(), // Uncommented in Phase 06
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Auth — OTP verification (Screen 13)
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => const _PlaceholderScreen('OTP Verification'),
      // binding: AuthBinding(), // Uncommented in Phase 06
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Auth — new password (Screen 14)
    GetPage(
      name: AppRoutes.newPassword,
      page: () => const _PlaceholderScreen('New Password'),
      // binding: AuthBinding(), // Uncommented in Phase 06
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),
  ];
}
