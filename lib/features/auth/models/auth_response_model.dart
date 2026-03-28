import '../../../shared/models/user_model.dart';

/// Response model for POST /auth/login, /auth/register, /auth/google, /auth/apple.
///
/// After successful auth, call [AuthStorage.saveTokens] with [accessToken]
/// and [refreshToken], then navigate to /home.
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String? ??
          json['accessToken'] as String? ??
          '',
      refreshToken: json['refresh_token'] as String? ??
          json['refreshToken'] as String? ??
          '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
