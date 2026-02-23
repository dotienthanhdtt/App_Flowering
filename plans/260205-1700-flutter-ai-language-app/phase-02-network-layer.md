---
phase: 2
title: "Core Network Layer"
status: completed
effort: 2h
depends_on: [1]
---

# Phase 2: Core Network Layer

## Context Links

- [Main Plan](./plan.md)
- [Dio/Hive Research](./research/researcher-dio-hive-patterns.md)
- Depends on: [Phase 1](./phase-01-project-setup.md)

## Overview

**Priority:** P1 - Foundation
**Status:** completed
**Description:** Implement Dio HTTP client with auth interceptor, retry logic, and standardized error handling.

## Key Insights

From research report:
- Use `QueuedInterceptor` for auth to prevent race conditions during concurrent refresh
- Implement exponential backoff for retries (1s, 2s, 4s)
- Separate 401 (unauthorized) from 5xx (server error) handling
- Create a new Dio instance for refresh to avoid interceptor loops

## Requirements

### Functional
- Single Dio instance with base configuration
- Bearer token automatically attached to requests
- 401 triggers token refresh, then retries original request
- Network/timeout errors retry with exponential backoff (max 3 retries)
- API response wrapper with code/message/data structure

### Non-Functional
- Thread-safe token refresh (no concurrent refresh calls)
- Timeout: connect 15s, receive 30s
- All errors mapped to user-friendly messages

## Architecture

```
core/network/
├── api_client.dart         # Dio singleton with interceptors
├── api_response.dart       # Generic response wrapper
├── api_exceptions.dart     # Custom exception types
├── auth_interceptor.dart   # Bearer + refresh token logic
└── retry_interceptor.dart  # Exponential backoff retry
```

## Related Code Files

### Files to Create
- `lib/core/network/api_response.dart`
- `lib/core/network/api_exceptions.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/network/retry_interceptor.dart`
- `lib/core/network/api_client.dart`

### Dependencies
- Requires `auth_storage.dart` from Phase 3 (create interface first)

## Implementation Steps

### Step 1: Create api_response.dart

```dart
// lib/core/network/api_response.dart

/// Standard API response wrapper
/// Server returns: { "code": 1, "message": "Success", "data": {...} }
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  bool get isSuccess => code == 1;
  bool get isError => code != 1;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  /// Create success response
  factory ApiResponse.success({T? data, String message = 'Success'}) {
    return ApiResponse(code: 1, message: message, data: data);
  }

  /// Create error response
  factory ApiResponse.error({int code = 0, required String message}) {
    return ApiResponse(code: code, message: message);
  }
}

/// Response codes from server
class ApiResponseCode {
  static const int success = 1;
  static const int generalError = 0;
  static const int validationError = -1;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
}
```

### Step 2: Create api_exceptions.dart

```dart
// lib/core/network/api_exceptions.dart
import 'package:dio/dio.dart';

/// Base API exception
abstract class ApiException implements Exception {
  final String message;
  final String userMessage;
  final int? statusCode;
  final dynamic originalError;

  const ApiException({
    required this.message,
    required this.userMessage,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Network connection failed
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Network connection failed',
    super.userMessage = 'Please check your internet connection',
    super.originalError,
  });
}

/// Request timeout
class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.userMessage = 'Request timed out. Please try again',
    super.originalError,
  });
}

/// Unauthorized - token expired or invalid
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Unauthorized',
    super.userMessage = 'Session expired. Please login again',
    super.statusCode = 401,
    super.originalError,
  });
}

/// Forbidden - no permission
class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Forbidden',
    super.userMessage = 'You do not have permission to access this resource',
    super.statusCode = 403,
    super.originalError,
  });
}

/// Resource not found
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Not found',
    super.userMessage = 'The requested resource was not found',
    super.statusCode = 404,
    super.originalError,
  });
}

/// Server error
class ServerException extends ApiException {
  const ServerException({
    super.message = 'Server error',
    super.userMessage = 'Something went wrong. Please try again later',
    super.statusCode = 500,
    super.originalError,
  });
}

/// Validation error from server
class ValidationException extends ApiException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    super.message = 'Validation failed',
    super.userMessage = 'Please check your input',
    super.statusCode,
    super.originalError,
    this.errors,
  });
}

/// Generic API error with server message
class ApiErrorException extends ApiException {
  const ApiErrorException({
    required super.message,
    required super.userMessage,
    super.statusCode,
    super.originalError,
  });
}

/// Maps DioException to ApiException
ApiException mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return TimeoutException(originalError: error);

    case DioExceptionType.connectionError:
      return NetworkException(originalError: error);

    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final serverMessage = data is Map ? data['message'] as String? : null;

      switch (statusCode) {
        case 401:
          return UnauthorizedException(originalError: error);
        case 403:
          return ForbiddenException(originalError: error);
        case 404:
          return NotFoundException(originalError: error);
        case 422:
          return ValidationException(
            message: serverMessage ?? 'Validation failed',
            userMessage: serverMessage ?? 'Please check your input',
            statusCode: statusCode,
            originalError: error,
            errors: _parseValidationErrors(data),
          );
        default:
          if (statusCode != null && statusCode >= 500) {
            return ServerException(
              statusCode: statusCode,
              originalError: error,
            );
          }
          return ApiErrorException(
            message: serverMessage ?? 'Request failed',
            userMessage: serverMessage ?? 'Something went wrong',
            statusCode: statusCode,
            originalError: error,
          );
      }

    case DioExceptionType.cancel:
      return const ApiErrorException(
        message: 'Request cancelled',
        userMessage: 'Request was cancelled',
      );

    default:
      return ApiErrorException(
        message: error.message ?? 'Unknown error',
        userMessage: 'Something went wrong',
        originalError: error,
      );
  }
}

Map<String, List<String>>? _parseValidationErrors(dynamic data) {
  if (data is! Map) return null;
  final errors = data['errors'];
  if (errors is! Map) return null;

  return errors.map((key, value) => MapEntry(
        key.toString(),
        (value is List) ? value.map((e) => e.toString()).toList() : [value.toString()],
      ));
}
```

### Step 3: Create auth_interceptor.dart

```dart
// lib/core/network/auth_interceptor.dart
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
```

### Step 4: Create retry_interceptor.dart

```dart
// lib/core/network/retry_interceptor.dart
import 'package:dio/dio.dart';

/// Retry interceptor with exponential backoff for network/server errors
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  });

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
      // Create new Dio for retry
      final retryDio = Dio();
      final response = await retryDio.fetch(err.requestOptions);
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
```

### Step 5: Create api_client.dart

```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
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
          print('→ ${options.method} ${options.path}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (EnvConfig.isDev) {
          print('← ${response.statusCode} ${response.requestOptions.path}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (EnvConfig.isDev) {
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
```

## Todo List

- [x] Create api_response.dart with code/message/data structure
- [x] Create api_exceptions.dart with exception types and mapper
- [x] Create auth_interceptor.dart with QueuedInterceptor
- [x] Create retry_interceptor.dart with exponential backoff
- [x] Create api_client.dart with Dio singleton
- [x] Test compilation with flutter analyze

## Success Criteria

- ApiClient compiles without errors
- All HTTP methods (GET, POST, PUT, DELETE) available
- Auth interceptor attaches Bearer token
- 401 triggers refresh, then retries
- Network errors retry 3 times with backoff
- All exceptions map to user-friendly messages

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Infinite refresh loop | High | Use separate Dio for refresh, check path |
| Race condition on concurrent refresh | High | Use QueuedInterceptor |
| Memory leak from retry Dio instances | Medium | Create lightweight Dio, no interceptors |

## Security Considerations

- Tokens stored via AuthStorage (encrypted in Phase 3)
- Refresh token only sent to refresh endpoint
- Clear tokens on refresh failure
- No sensitive data in logs (even in dev)

## Next Steps

After completion, proceed to [Phase 3: Core Services](./phase-03-core-services.md).
