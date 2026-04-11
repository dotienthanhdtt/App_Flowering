// lib/core/services/auth_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

/// Secure token storage using platform keychain (iOS Keychain / Android Keystore)
class AuthStorage extends GetxService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _cachedToken;

  /// Initialize auth storage
  Future<AuthStorage> init() async {
    await refreshLoginState();
    return this;
  }

  /// Save both access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    _cachedToken = accessToken;
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  /// Check if user is logged in (sync — uses cached token)
  bool get isLoggedIn => _cachedToken != null && _cachedToken!.isNotEmpty;

  /// Refresh the cached login state from secure storage
  Future<void> refreshLoginState() async {
    _cachedToken = await _storage.read(key: _accessTokenKey);
  }

  /// Clear all auth data
  Future<void> clearTokens() async {
    await _storage.deleteAll();
    _cachedToken = null;
  }

  /// No-op — flutter_secure_storage has no explicit close
  Future<void> close() async {}
}
