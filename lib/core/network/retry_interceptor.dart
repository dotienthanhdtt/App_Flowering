import 'package:dio/dio.dart';

/// Retry interceptor with exponential backoff for network/server errors
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;
  final Dio _dio;

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

    // Calculate delay with exponential backoff
    final delay = initialDelay * (1 << retryCount);

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
    // Retry on network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on 5xx server errors
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return true;
    }

    return false;
  }
}
