import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../services/language-context-service.dart';
import 'api_exceptions.dart';

/// Intercepts 403 "not enrolled" responses, resyncs the active language from
/// the server, then retries the original request exactly once.
/// Registered AFTER ActiveLanguageInterceptor so the retry re-passes through
/// header injection with the updated language code.
class LanguageRecoveryInterceptor extends Interceptor {
  static const String _retryFlag = '_langRetry';
  final Dio _dio;

  /// Guards against recursive 403 loops if the resync request itself returns 403.
  bool _recovering = false;

  LanguageRecoveryInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final serverMsg = (err.response?.data is Map)
        ? (err.response!.data as Map)['message']?.toString()
        : null;

    final detected = detectLanguageContextError(status, serverMsg);
    if (detected != LanguageContextError.notEnrolled) return handler.next(err);
    if (err.requestOptions.extra[_retryFlag] == true) return handler.next(err);
    if (_recovering) return handler.next(err);
    if (!Get.isRegistered<LanguageContextService>()) return handler.next(err);

    _recovering = true;
    try {
      final newCode = await Get.find<LanguageContextService>().resyncFromServer();
      if (newCode == null) return handler.next(err);

      final opts = err.requestOptions;
      opts.extra[_retryFlag] = true;
      final response = await _dio.fetch(opts);
      return handler.resolve(response);
    } catch (e) {
      if (kDebugMode) debugPrint('[LanguageRecoveryInterceptor] recovery failed: $e');
      return handler.next(err);
    } finally {
      _recovering = false;
    }
  }
}
