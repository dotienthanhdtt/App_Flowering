/// API endpoint constants
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String loginFirebase = '/auth/firebase'; // POST (Google & Apple)
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
  // POST /onboarding/chat unified endpoint:
  //   Mode A (no conversationId) → create session + returns greeting
  //   Mode B (with conversationId) → chat turn
  static const String onboardingChat = '/onboarding/chat'; // POST
  static const String onboardingComplete = '/onboarding/complete'; // POST

  /// Fetches full message history for an anonymous onboarding conversation so
  /// the chat screen can rehydrate on cold-resume.
  /// Response data shape: `{ conversation_id, turn_number, max_turns,
  /// is_last_turn, messages: [{ id, role, content, created_at }] }`.
  static String onboardingConversationMessages(String id) =>
      '/onboarding/conversations/$id/messages';

  // Lessons
  static const String lessons = '/lessons';
  static String lessonDetail(String id) => '/lessons/$id';

  // Chat
  static const String chatMessages = '/chat/messages';
  static const String chatSend = '/chat/send';
  static const String chatVoice = '/chat/voice';

  // AI
  static const String translate = '/ai/translate'; // POST
  static const String chatCorrect = '/ai/chat/correct'; // POST
  static const String transcribeAudio = '/ai/transcribe'; // POST

  // Progress
  static const String progress = '/progress';
  static const String stats = '/progress/stats';

  // Subscriptions
  static const String subscriptionMe = '/subscriptions/me';
}
