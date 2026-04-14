/// Language model for onboarding screens 05-06.
///
/// Supports both API-fetched data (with [id] and [flagUrl]) and
/// offline fallback static lists (emoji flags only).
class OnboardingLanguage {
  /// UUID from API; null for hardcoded fallback entries.
  final String? id;
  final String code;
  final String flag; // emoji flag — always available
  final String? flagUrl; // network URL from API; takes precedence over [flag]
  final String name;
  final String subtitle;
  final bool isEnabled;

  const OnboardingLanguage({
    this.id,
    required this.code,
    required this.flag,
    this.flagUrl,
    required this.name,
    required this.subtitle,
    this.isEnabled = false,
  });

  /// Parse from API response or cache.
  ///
  /// [type] — `'native'` or `'learning'` — selects the correct availability
  /// flag from the real API (`isNativeAvailable` / `isLearningAvailable`).
  /// Omit when reading back from local cache (which stores `isEnabled` directly).
  factory OnboardingLanguage.fromJson(
    Map<String, dynamic> json, {
    String? type,
  }) {
    final bool isEnabled;
    if (type == 'native') {
      isEnabled = json['is_native_available'] as bool? ??
          json['isNativeAvailable'] as bool? ??
          false;
    } else if (type == 'learning') {
      isEnabled = json['is_learning_available'] as bool? ??
          json['isLearningAvailable'] as bool? ??
          false;
    } else {
      // Cache format uses 'is_active' or legacy 'isEnabled'.
      isEnabled = json['is_active'] as bool? ??
          json['isEnabled'] as bool? ??
          true;
    }

    return OnboardingLanguage(
      id: json['id'] as String?,
      code: json['code'] as String,
      flag: json['flag'] as String? ?? '',
      flagUrl: json['flag_url'] as String? ?? json['flagUrl'] as String?,
      name: json['name'] as String,
      subtitle: json['native_name'] as String? ??
          json['nativeName'] as String? ??
          json['subtitle'] as String? ??
          '',
      isEnabled: isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'code': code,
        'flag': flag,
        if (flagUrl != null) 'flag_url': flagUrl,
        'name': name,
        'subtitle': subtitle,
        'is_active': isEnabled,
      };
}
