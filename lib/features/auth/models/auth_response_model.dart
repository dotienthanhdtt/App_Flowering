import '../../../shared/models/user_model.dart';
import 'user_language_model.dart';

/// Response model for POST /auth/login, /auth/register, /auth/firebase,
/// /auth/refresh.
///
/// After successful auth, call [AuthStorage.saveTokens] with [accessToken]
/// and [refreshToken], then navigate to /home.
///
/// [languages] contains the user's joined learning languages (createdAt DESC).
/// Empty list for brand-new users who haven't picked a language yet.
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final List<UserLanguageModel> languages;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.languages = const [],
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final rawLangs = json['languages'] as List<dynamic>? ?? const [];
    return AuthResponse(
      accessToken: json['access_token'] as String? ??
          json['accessToken'] as String? ??
          '',
      refreshToken: json['refresh_token'] as String? ??
          json['refreshToken'] as String? ??
          '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      languages: rawLangs
          .whereType<Map<String, dynamic>>()
          .map(UserLanguageModel.fromJson)
          .toList(),
    );
  }
}
