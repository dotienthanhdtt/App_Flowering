import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../services/auth_storage.dart';
import '../constants/api_endpoints.dart';
import '../../config/env_config.dart';

/// QueuedInterceptor serializes onRequest callbacks.
/// Completer gate ensures a single concurrent refresh; waiters retry with
/// the freshly obtained token instead of triggering a second refresh.
class AuthInterceptor extends QueuedInterceptor {
  final AuthStorage _authStorage;
  final Dio _retryDio;
  Completer<bool>? _refreshGate;

  AuthInterceptor(this._authStorage, this._retryDio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains(ApiEndpoints.refreshToken)) {
      handler.next(options);
      return;
    }
    final token = _authStorage.cachedAccessToken ??
        await _authStorage.getAccessToken();
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
    if (err.response?.statusCode != 401 ||
        err.requestOptions.path.contains(ApiEndpoints.refreshToken)) {
      handler.next(err);
      return;
    }

    if (_refreshGate != null) {
      // Refresh already in-flight — await result, then retry with new token.
      final refreshed = await _refreshGate!.future;
      if (refreshed) {
        final newToken = await _authStorage.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await _retryDio.fetch(err.requestOptions);
          handler.resolve(response);
        } catch (_) {
          handler.next(err);
        }
      } else {
        handler.next(err);
      }
      return;
    }

    final gate = Completer<bool>();
    _refreshGate = gate;
    bool refreshed = false;
    try {
      refreshed = await _refreshToken();
    } catch (_) {
      refreshed = false;
    } finally {
      gate.complete(refreshed);
      _refreshGate = null;
    }

    if (refreshed) {
      final newToken = await _authStorage.getAccessToken();
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      try {
        final response = await _retryDio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {
        // retry failed — fall through
      }
    } else {
      await _authStorage.clearTokens();
      _triggerLogout();
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _authStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

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
    } catch (_) {
      // Refresh failed
    }
    return false;
  }

  void _triggerLogout() {
    Get.offAllNamed('/login');
  }
}
