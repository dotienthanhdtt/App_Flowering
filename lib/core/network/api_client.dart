import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../../config/env_config.dart';
import '../services/auth_storage.dart';
import 'api_exceptions.dart';
import 'api_response.dart';
import 'auth_interceptor.dart';
import 'retry_interceptor.dart';

/// Singleton API client with Dio
class ApiClient extends GetxService {
  late final Dio _dio;

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

    // Order matters: retry first, then auth
    _dio.interceptors.addAll([
      RetryInterceptor(maxRetries: 3),
      AuthInterceptor(authStorage),
      _loggingInterceptor(),
    ]);

    return this;
  }

  /// Logging interceptor for debug builds
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (EnvConfig.isDev) {
          // ignore: avoid_print
          print('→ ${options.method} ${options.path}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (EnvConfig.isDev) {
          // ignore: avoid_print
          print('← ${response.statusCode} ${response.requestOptions.path}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (EnvConfig.isDev) {
          // ignore: avoid_print
          print('✗ ${error.response?.statusCode} ${error.requestOptions.path}');
        }
        handler.next(error);
      },
    );
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
