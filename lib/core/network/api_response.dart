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
