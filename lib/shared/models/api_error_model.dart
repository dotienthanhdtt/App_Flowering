class ApiErrorModel {
  final int code;
  final String message;
  final Map<String, List<String>>? errors;

  const ApiErrorModel({
    required this.code,
    required this.message,
    this.errors,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? 'Unknown error',
      errors: _parseErrors(json['errors']),
    );
  }

  static Map<String, List<String>>? _parseErrors(dynamic errors) {
    if (errors is! Map) return null;
    return errors.map((key, value) => MapEntry(
          key.toString(),
          (value is List) ? value.map((e) => e.toString()).toList() : [value.toString()],
        ));
  }

  String get firstError {
    if (errors == null || errors!.isEmpty) return message;
    final firstKey = errors!.keys.first;
    return errors![firstKey]?.first ?? message;
  }
}
