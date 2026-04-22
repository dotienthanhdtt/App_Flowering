import 'dart:convert';
import 'package:dio/dio.dart';
import '../../config/env_config.dart';

/// Dev-only HTTP logger that prints curl, status, response time, and JSON body
class HttpLoggerInterceptor extends Interceptor {
  static const _divider = '══════════════════════════════════════';
  static const _maxBodyLength = 1000;

  // Fields redacted in auth endpoint responses
  static const _sensitiveKeys = [
    'access_token',
    'refresh_token',
    'token',
    'id_token',
  ];

  // Auth endpoint path prefixes whose response bodies are redacted
  static const _authPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/google',
    '/auth/apple',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (EnvConfig.isDev) {
      options.extra['_startTime'] = DateTime.now().millisecondsSinceEpoch;
      // ignore: avoid_print
      print(_divider);
      // ignore: avoid_print
      print('-> ${options.method} ${options.path}');
      // ignore: avoid_print
      print(_buildCurl(options));
      // ignore: avoid_print
      print(_divider);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (EnvConfig.isDev) {
      final elapsed = _elapsed(response.requestOptions);
      final path = response.requestOptions.path;
      final body = _isAuthEndpoint(path)
          ? _redactSensitiveFields(response.data)
          : response.data;
      // ignore: avoid_print
      print(_divider);
      // ignore: avoid_print
      print(
        '<- ${response.statusCode} '
        '$path '
        '[${elapsed}ms]',
      );
      // ignore: avoid_print
      print(_formatBody(body));
      // ignore: avoid_print
      print(_divider);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (EnvConfig.isDev) {
      final elapsed = _elapsed(err.requestOptions);
      // ignore: avoid_print
      print(_divider);
      // ignore: avoid_print
      print(
        'x ${err.response?.statusCode ?? 'ERR'} '
        '${err.requestOptions.path} '
        '[${elapsed}ms]',
      );
      if (err.response?.data != null) {
        // ignore: avoid_print
        print(_formatBody(err.response!.data));
      } else {
        // ignore: avoid_print
        print(err.message ?? 'Unknown error');
      }
      // ignore: avoid_print
      print(_divider);
    }
    handler.next(err);
  }

  bool _isAuthEndpoint(String path) {
    return _authPaths.any((p) => path.startsWith(p)) || path.startsWith('/auth/');
  }

  /// Recursively redact sensitive keys in a map/list structure
  dynamic _redactSensitiveFields(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (_sensitiveKeys.contains(key.toString())) {
          return MapEntry(key, '***REDACTED***');
        }
        return MapEntry(key, _redactSensitiveFields(value));
      });
    }
    if (data is List) {
      return data.map(_redactSensitiveFields).toList();
    }
    return data;
  }

  int _elapsed(RequestOptions options) {
    final start = options.extra['_startTime'] as int?;
    if (start == null) return 0;
    return DateTime.now().millisecondsSinceEpoch - start;
  }

  String _buildCurl(RequestOptions options) {
    final parts = <String>['curl -X ${options.method}'];

    final url = '${options.baseUrl}${options.path}';
    final query = options.queryParameters.isNotEmpty
        ? '?${options.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';
    parts.add("'$url$query'");

    options.headers.forEach((key, value) {
      // if (key.toLowerCase() == 'authorization') {
      //   parts.add("-H '$key: Bearer ***'");
      // } else {
        parts.add("-H '$key: $value'");
      // }
    });

    if (options.data != null && options.data is! FormData) {
      try {
        final body = jsonEncode(options.data);
        parts.add("-d '$body'");
      } catch (_) {
        parts.add("-d '${options.data}'");
      }
    }

    return parts.join(' \\\n  ');
  }

  String _formatBody(dynamic data) {
    try {
      final json = const JsonEncoder.withIndent('  ').convert(data);
      if (json.length > _maxBodyLength) {
        return '${json.substring(0, _maxBodyLength)}\n... [truncated]';
      }
      return json;
    } catch (_) {
      final str = data.toString();
      if (str.length > _maxBodyLength) {
        return '${str.substring(0, _maxBodyLength)}\n... [truncated]';
      }
      return str;
    }
  }
}
