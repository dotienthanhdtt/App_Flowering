import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../services/language-context-service.dart';

/// Attaches X-Learning-Language header to all content-scoped requests.
/// Skips auth/meta paths; preserves explicit per-request overrides.
/// Must be registered AFTER AuthInterceptor and BEFORE HttpLoggerInterceptor.
class ActiveLanguageInterceptor extends Interceptor {
  static const List<String> _skipPrefixes = [
    '/auth',
    '/languages',
    '/users/me',
    '/subscription',
    '/admin',
  ];
  static const String _headerName = 'X-Learning-Language';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      // Per-request override wins — do not overwrite explicit header
      if (options.headers.containsKey(_headerName)) {
        return handler.next(options);
      }
      if (!_needsHeader(options.path)) return handler.next(options);
      if (!Get.isRegistered<LanguageContextService>()) {
        if (kDebugMode) {
          debugPrint('[ActiveLanguageInterceptor] LanguageContextService not registered — skipping header');
        }
        return handler.next(options);
      }
      final code = Get.find<LanguageContextService>().activeCode.value;
      if (code != null && code.isNotEmpty) {
        options.headers[_headerName] = code;
      }
    } catch (e) {
      // Never block a request on interceptor error
      if (kDebugMode) debugPrint('[ActiveLanguageInterceptor] error: $e');
    }
    handler.next(options);
  }

  bool _needsHeader(String path) => !_skipPrefixes.any(path.startsWith);
}
