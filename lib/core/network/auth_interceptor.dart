import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../services/auth_storage.dart';
import '../constants/api_endpoints.dart';
import '../../config/env_config.dart';

/// QueuedInterceptor ensures concurrent 401s wait for single refresh
class AuthInterceptor extends QueuedInterceptor {
  final AuthStorage _authStorage;
  bool _isRefreshing = false;

  AuthInterceptor(this._authStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for refresh endpoint to avoid loop
    if (options.path.contains(ApiEndpoints.refreshToken)) {
      handler.next(options);
      return;
    }

    final token = await _authStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 for non-refresh requests
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains(ApiEndpoints.refreshToken)) {

      if (_isRefreshing) {
        // Another request is already refreshing, wait and retry
        handler.next(err);
        return;
      }

      _isRefreshing = true;

      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry original request with new token
          final newToken = await _authStorage.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

          // Create new Dio for retry to avoid interceptor loop
          final retryDio = Dio(BaseOptions(
            baseUrl: EnvConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
          ));

          final response = await retryDio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        // Refresh failed, clear tokens and let error propagate
        await _authStorage.clearTokens();
      } finally {
        _isRefreshing = false;
      }

      // Refresh failed, trigger logout
      _triggerLogout();
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _authStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Use separate Dio instance for refresh to avoid interceptor loop
      final refreshDio = Dio(BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.data['code'] == 1) {
        await _authStorage.saveTokens(
          accessToken: response.data['data']['access_token'],
          refreshToken: response.data['data']['refresh_token'],
        );
        return true;
      }
    } catch (e) {
      // Refresh failed
    }
    return false;
  }

  void _triggerLogout() {
    // Navigate to login and clear auth state
    // Will be implemented when AuthController exists
    Get.offAllNamed('/login');
  }
}
