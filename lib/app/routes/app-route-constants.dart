/// Route name constants following /feature/action pattern
abstract class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Main routes
  static const String home = '/home';

  // Chat routes
  static const String chat = '/chat';

  // Lessons routes
  static const String lessons = '/lessons';
  static const String lessonDetail = '/lessons/detail';

  // Profile routes
  static const String profile = '/profile';

  // Settings routes
  static const String settings = '/settings';

  // Onboarding routes
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingWelcome2 = '/onboarding/welcome-2';
  static const String onboardingWelcome3 = '/onboarding/welcome-3';
  static const String onboardingNativeLanguage = '/onboarding/native-language';
  static const String onboardingLearningLanguage = '/onboarding/learning-language';
  static const String onboardingScenarioGift = '/onboarding/scenario-gift';
  // Note: Login Gate is a bottom sheet shown over ScenarioGift — no GetPage needed.
  static const String onboardingLoginGate = '/onboarding/login-gate';

  // Signup / Auth routes
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String newPassword = '/new-password';
}
