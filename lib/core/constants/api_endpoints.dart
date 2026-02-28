/// API endpoint constants
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User
  static const String userMe = '/users/me';
  static const String updateUserMe = '/users/me'; // PATCH
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';

  // Lessons
  static const String lessons = '/lessons';
  static String lessonDetail(String id) => '/lessons/$id';

  // Chat
  static const String chatMessages = '/chat/messages';
  static const String chatSend = '/chat/send';
  static const String chatVoice = '/chat/voice';

  // Progress
  static const String progress = '/progress';
  static const String stats = '/progress/stats';
}
