import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../../config/env_config.dart';
import '../services/auth_storage.dart';
import 'active-language-interceptor.dart';
import 'api_exceptions.dart';
import 'api_response.dart';
import 'auth_interceptor.dart';
import 'http_logger_interceptor.dart';
import 'language-recovery-interceptor.dart';
import 'retry_interceptor.dart';

/// Singleton API client with Dio
class ApiClient extends GetxService {
  late final Dio _dio;
  late final Dio _retryDio;

  Dio get dio => _dio;

  /// Initialize with auth storage dependency
  Future<ApiClient> init(AuthStorage authStorage) async {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Shared retry Dio — no interceptors so retried requests bypass the full chain.
    _retryDio = Dio(BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Order: retry → auth → language header → language 403 recovery → logger
    _dio.interceptors.addAll([
      RetryInterceptor(dio: _dio, maxRetries: 3),
      AuthInterceptor(authStorage, _retryDio),
      ActiveLanguageInterceptor(),
      LanguageRecoveryInterceptor(_retryDio),
      HttpLoggerInterceptor(),
    ]);

    return this;
  }

  // ─────────────────────────────────────────────────────────────────
  // HTTP Methods
  // ─────────────────────────────────────────────────────────────────

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// POST request returning an SSE stream of raw `data:` payloads.
  ///
  /// Each yielded [String] is the content after `data: ` (already trimmed).
  /// The caller is responsible for JSON-decoding individual events.
  Stream<String> postStream(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async* {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );
      final stream = response.data?.stream as Stream<List<int>>?;
      if (stream == null) return;

      String buffer = '';
      await for (final chunk in stream) {
        buffer += String.fromCharCodes(chunk);
        // Split on double-newline (SSE event boundary) or single newlines
        final lines = buffer.split('\n');
        // Keep last incomplete line in buffer
        buffer = lines.removeLast();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('data:')) {
            final payload = trimmed.substring(5).trim();
            if (payload.isNotEmpty) yield payload;
          }
        }
      }
      // Process any remaining data in buffer
      if (buffer.trim().startsWith('data:')) {
        final payload = buffer.trim().substring(5).trim();
        if (payload.isNotEmpty) yield payload;
      }
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Upload file with multipart
  Future<ApiResponse<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        fieldName: await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Handle response and parse to ApiResponse
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      return ApiResponse.fromJson(data, fromJson);
    }

    // Unexpected response format
    return ApiResponse.error(
      code: 0,
      message: 'Unexpected response format',
    );
  }
}
