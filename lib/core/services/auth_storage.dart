// lib/core/services/auth_storage.dart
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Secure token storage using Hive
class AuthStorage extends GetxService {
  static const String _boxName = 'auth';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  late Box<String> _box;

  /// Initialize auth storage
  Future<AuthStorage> init() async {
    _box = await Hive.openBox<String>(_boxName);
    return this;
  }

  /// Save both access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(_accessTokenKey, accessToken);
    await _box.put(_refreshTokenKey, refreshToken);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return _box.get(_accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return _box.get(_refreshTokenKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _box.put(_userIdKey, userId);
  }

  /// Get user ID
  String? getUserId() {
    return _box.get(_userIdKey);
  }

  /// Check if user is logged in
  bool get isLoggedIn {
    final token = _box.get(_accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Clear all auth data
  Future<void> clearTokens() async {
    await _box.clear();
  }

  /// Close the box
  Future<void> close() async {
    await _box.close();
  }
}
