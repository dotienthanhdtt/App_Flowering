/// API endpoint constants
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String loginGoogle = '/auth/google'; // POST
  static const String loginApple = '/auth/apple'; // POST
  static const String forgotPassword = '/auth/forgot-password'; // POST
  static const String verifyOtp = '/auth/verify-otp'; // POST
  static const String resetPassword = '/auth/reset-password'; // POST

  // User
  static const String userMe = '/users/me';
  static const String updateUserMe = '/users/me'; // PATCH

  // Languages
  static const String languages = '/languages'; // GET ?type=native|learning
  static const String userNativeLanguage = '/languages/user/native'; // PATCH
  static const String userLanguages = '/languages/user'; // GET, POST
  static String userLanguage(String id) => '/languages/user/$id'; // PATCH, DELETE

  // Onboarding
  static const String onboardingStart = '/onboarding/start'; // POST
  static const String onboardingChat = '/onboarding/chat'; // POST
  static const String onboardingComplete = '/onboarding/complete'; // POST

  // Lessons
  static const String lessons = '/lessons';
  static String lessonDetail(String id) => '/lessons/$id';

  // Chat
  static const String chatMessages = '/chat/messages';
  static const String chatSend = '/chat/send';
  static const String chatVoice = '/chat/voice';

  // AI
  static const String translate = '/ai/translate'; // POST

  // Progress
  static const String progress = '/progress';
  static const String stats = '/progress/stats';
}
