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

enum LanguageContextError {
  headerMissing,
  unknownCode,
  notEnrolled,
  activeRequired;

  String get translationKey {
    switch (this) {
      case LanguageContextError.headerMissing:
        return 'err_language_header_missing';
      case LanguageContextError.unknownCode:
        return 'err_language_unknown';
      case LanguageContextError.notEnrolled:
        return 'err_language_not_enrolled';
      case LanguageContextError.activeRequired:
        return 'err_language_required';
    }
  }
}

/// Maps backend error status + message to a LanguageContextError variant.
/// Returns null if the error is unrelated to language context.
LanguageContextError? detectLanguageContextError(int? statusCode, String? message) {
  if (message == null) return null;
  final m = message.toLowerCase();
  if (statusCode == 403 && m.contains('not enrolled')) {
    return LanguageContextError.notEnrolled;
  }
  if (statusCode == 400) {
    if (m.contains('unknown or inactive language code')) return LanguageContextError.unknownCode;
    if (m.contains('anonymous')) return LanguageContextError.activeRequired;
    if (m.contains('active learning language required')) return LanguageContextError.headerMissing;
  }
  return null;
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
