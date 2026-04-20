import 'package:get/get.dart';
import 'app-route-constants.dart';
import 'app-route-transition-config.dart';
import '../../features/onboarding/bindings/onboarding_binding.dart';
import '../../features/onboarding/bindings/splash_binding.dart';
import '../../features/onboarding/views/splash_screen.dart';
import '../../features/onboarding/views/onboarding_value_screen_1.dart';
import '../../features/onboarding/views/onboarding_value_screen_2.dart';
import '../../features/onboarding/views/onboarding_value_screen_3.dart';
import '../../features/onboarding/views/native_language_screen.dart';
import '../../features/onboarding/views/learning_language_screen.dart';
import '../../features/onboarding/views/scenario_gift_screen.dart';

/// Onboarding flow pages: splash, value screens, language selection, scenario gift
final List<GetPage> onboardingPages = [
  // Splash screen with fade transition
  GetPage(
    name: AppRoutes.splash,
    page: () => const SplashScreen(),
    binding: SplashBinding(),
    transition: Transition.fade,
    transitionDuration: const Duration(milliseconds: 400),
  ),

  // Onboarding — value screen 1 (Screen 03)
  GetPage(
    name: AppRoutes.onboardingWelcome,
    page: () => const OnboardingValueScreen1(),
    binding: OnboardingBinding(),
    transition: Transition.fade,
    transitionDuration: kDefaultDuration,
  ),

  // Onboarding — value screen 2 (Screen 04)
  GetPage(
    name: AppRoutes.onboardingWelcome2,
    page: () => const OnboardingValueScreen2(),
    binding: OnboardingBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Onboarding — value screen 3 (Screen 05)
  GetPage(
    name: AppRoutes.onboardingWelcome3,
    page: () => const OnboardingValueScreen3(),
    binding: OnboardingBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Onboarding — native language selection
  GetPage(
    name: AppRoutes.onboardingNativeLanguage,
    page: () => const NativeLanguageScreen(),
    binding: OnboardingBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Onboarding — learning language selection
  GetPage(
    name: AppRoutes.onboardingLearningLanguage,
    page: () => const LearningLanguageScreen(),
    binding: OnboardingBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Onboarding — scenario gift (Screen 08)
  GetPage(
    name: AppRoutes.onboardingScenarioGift,
    page: () => const ScenarioGiftScreen(),
    binding: OnboardingBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),
];
