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
}
