import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../services/language-context-service.dart';
import 'api_exceptions.dart';

/// Intercepts 403 "not enrolled" responses, resyncs the active language from
/// the server, then retries the original request once via retryDio (no interceptors).
/// QueuedInterceptor + Completer gate: concurrent 403s trigger exactly one resync.
class LanguageRecoveryInterceptor extends QueuedInterceptor {
  static const String _retryFlag = '_langRetry';
  final Dio _retryDio;
  Completer<bool>? _resyncGate;

  LanguageRecoveryInterceptor(this._retryDio);

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
    if (detected != LanguageContextError.notEnrolled) {
      handler.next(err);
      return;
    }
    if (err.requestOptions.extra[_retryFlag] == true) {
      handler.next(err);
      return;
    }
    if (!Get.isRegistered<LanguageContextService>()) {
      handler.next(err);
      return;
    }

    if (_resyncGate != null) {
      // Resync already in-flight — await result, then retry with updated header.
      final resynced = await _resyncGate!.future;
      if (resynced) {
        await _retryWithUpdatedHeader(err, handler);
      } else {
        handler.next(err);
      }
      return;
    }

    final gate = Completer<bool>();
    _resyncGate = gate;
    bool resynced = false;
    try {
      final newCode =
          await Get.find<LanguageContextService>().resyncFromServer();
      resynced = newCode != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LanguageRecoveryInterceptor] recovery failed: $e');
      }
      resynced = false;
    } finally {
      gate.complete(resynced);
      _resyncGate = null;
    }

    if (resynced) {
      await _retryWithUpdatedHeader(err, handler);
    } else {
      handler.next(err);
    }
  }

  Future<void> _retryWithUpdatedHeader(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final opts = err.requestOptions;
    opts.extra[_retryFlag] = true;
    final code = Get.find<LanguageContextService>().activeCode.value;
    if (code != null && code.isNotEmpty) {
      opts.headers['X-Learning-Language'] = code;
    }
    try {
      final response = await _retryDio.fetch(opts);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }
}
