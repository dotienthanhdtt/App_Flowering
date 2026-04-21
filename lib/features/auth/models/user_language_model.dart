/// User language enrollment — joined learning languages returned by
/// /auth/firebase, /auth/refresh, etc.
///
/// Backend default ordering: createdAt DESC (newest first).
/// proficiencyLevel enum: beginner | elementary | intermediate |
/// upper_intermediate | advanced.
///
/// JSON parsing accepts both snake_case and camelCase since response shape
/// may be transformed by interceptors.
class UserLanguageModel {
  final String id;
  final String languageId;
  final String proficiencyLevel;
  final bool isActive;
  final DateTime? createdAt;
  final LanguageModel language;

  const UserLanguageModel({
    required this.id,
    required this.languageId,
    required this.proficiencyLevel,
    required this.isActive,
    required this.createdAt,
    required this.language,
  });

  factory UserLanguageModel.fromJson(Map<String, dynamic> json) {
    final createdRaw =
        json['created_at'] as String? ?? json['createdAt'] as String?;
    return UserLanguageModel(
      id: json['id'] as String? ?? '',
      languageId:
          json['language_id'] as String? ?? json['languageId'] as String? ?? '',
      proficiencyLevel: json['proficiency_level'] as String? ??
          json['proficiencyLevel'] as String? ??
          'beginner',
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? false,
      createdAt: createdRaw != null ? DateTime.tryParse(createdRaw) : null,
      language: LanguageModel.fromJson(
        (json['language'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'language_id': languageId,
        'proficiency_level': proficiencyLevel,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
        'language': language.toJson(),
      };
}

class LanguageModel {
  final String id;
  final String code;
  final String name;
  final String nativeName;
  final String? flagUrl;
  final bool isNativeAvailable;
  final bool isLearningAvailable;

  const LanguageModel({
    required this.id,
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagUrl,
    required this.isNativeAvailable,
    required this.isLearningAvailable,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nativeName:
          json['native_name'] as String? ?? json['nativeName'] as String? ?? '',
      flagUrl: json['flag_url'] as String? ?? json['flagUrl'] as String?,
      isNativeAvailable: json['is_native_available'] as bool? ??
          json['isNativeAvailable'] as bool? ??
          false,
      isLearningAvailable: json['is_learning_available'] as bool? ??
          json['isLearningAvailable'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'native_name': nativeName,
        'flag_url': flagUrl,
        'is_native_available': isNativeAvailable,
        'is_learning_available': isLearningAvailable,
      };
}
