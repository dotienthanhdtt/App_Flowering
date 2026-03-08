import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_sizes.dart';
import 'app-route-constants.dart';
import '../../features/onboarding/bindings/onboarding_binding.dart';
import '../../features/onboarding/bindings/splash_binding.dart';
import '../../features/onboarding/views/splash_screen.dart';
import '../../features/onboarding/views/welcome_problem_screen.dart';
import '../../features/onboarding/views/native_language_screen.dart';
import '../../features/onboarding/views/learning_language_screen.dart';
import '../../features/chat/bindings/ai_chat_binding.dart';
import '../../features/chat/views/ai_chat_screen.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/login_email_screen.dart';
import '../../features/auth/views/signup_email_screen.dart';
import '../../features/auth/views/forgot_password_screen.dart';
import '../../features/auth/views/otp_verification_screen.dart';
import '../../features/auth/views/new_password_screen.dart';
import '../../features/onboarding/views/scenario_gift_screen.dart';
import '../../features/home/views/main-shell-screen.dart';
import '../../features/home/bindings/main-shell-binding.dart';

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
              '$title - ${'coming_soon_suffix'.tr}',
              style: const TextStyle(fontSize: AppSizes.font3XL, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacingL),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: Text('go_back'.tr),
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

    // Onboarding — welcome screens (single route, internal PageView handles steps)
    GetPage(
      name: AppRoutes.onboardingWelcome,
      page: () => const WelcomeProblemScreen(),
      binding: OnboardingBinding(),
      transition: Transition.fade,
      transitionDuration: defaultDuration,
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
      page: () => const LoginEmailScreen(),
      binding: AuthBinding(),
      transition: Transition.fade,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const _PlaceholderScreen('Register'),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Home — main shell with bottom nav
    GetPage(
      name: AppRoutes.home,
      page: () => const MainShellScreen(),
      binding: MainShellBinding(),
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
      page: () => const ScenarioGiftScreen(),
      binding: OnboardingBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Auth — signup (Screen 10)
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupEmailScreen(),
      binding: AuthBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Auth — forgot password (Screen 12)
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      binding: AuthBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Auth — OTP verification (Screen 13)
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => const OtpVerificationScreen(),
      binding: AuthBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Auth — new password (Screen 14)
    GetPage(
      name: AppRoutes.newPassword,
      page: () => const NewPasswordScreen(),
      binding: AuthBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),
  ];
}
