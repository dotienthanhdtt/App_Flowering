import 'dart:math';

import 'package:dio/dio.dart';

/// Retry interceptor with jittered exponential backoff for network/server
/// errors. Jitter avoids thundering-herd spikes against a recovering server.
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;
  final Dio _dio;
  final Random _rand = Random();

  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 1,
    this.initialDelay = const Duration(seconds: 1),
  }) : _dio = dio;

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final retryCount = err.requestOptions.extra['_retry_count'] ?? 0;

    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    // Exponential backoff with ±50% jitter (range: 0.5×–1.5× base delay).
    final base = initialDelay.inMilliseconds * (1 << retryCount);
    final jitter = 0.5 + _rand.nextDouble();
    final delay = Duration(milliseconds: (base * jitter).round());

    await Future.delayed(delay);

    // Update retry count
    err.requestOptions.extra['_retry_count'] = retryCount + 1;

    try {
      final response = await _dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        // Recurse with updated retry count
        onError(e, handler);
      } else {
        handler.next(err);
      }
    }
  }

  bool _shouldRetry(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    final isIdempotent = method == 'GET' || method == 'HEAD' || method == 'OPTIONS';
    final retrySafe = err.requestOptions.extra['retry_safe'] == true;

    // Network errors: always safe to retry on idempotent verbs, or when
    // caller opts in with `retry_safe: true` (e.g., deduped POSTs).
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return isIdempotent || retrySafe;
    }

    // 5xx server errors: only retry idempotent or explicitly safe requests,
    // otherwise a POST could be applied twice server-side.
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return isIdempotent || retrySafe;
    }

    return false;
  }
}
