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
    if (type == 'native' || type == 'learning') {
      isEnabled = json['is_active'] as bool? ??
          json['isNativeAvailable'] as bool? ??
          json['isLearningAvailable'] as bool? ??
          json['isEnabled'] as bool? ??
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

  // ── Offline fallback lists ────────────────────────────────────────────────

  // fallbackNativeLanguages / fallbackLearningLanguages are the same as the
  // static lists below — use nativeLanguages / learningLanguages directly.

  /// Hardcoded native language list — used when API is unavailable.
  static const List<OnboardingLanguage> nativeLanguages = [
    OnboardingLanguage(
      code: 'vi',
      flag: '🇻🇳',
      name: 'Tiếng Việt',
      subtitle: 'Vietnamese',
      isEnabled: true,
    ),
    OnboardingLanguage(
      code: 'en',
      flag: '🇬🇧',
      name: 'English',
      subtitle: 'English',
      isEnabled: true,
    ),
    OnboardingLanguage(
      code: 'ja',
      flag: '🇯🇵',
      name: '日本語',
      subtitle: 'Japanese',
    ),
    OnboardingLanguage(
      code: 'ko',
      flag: '🇰🇷',
      name: '한국어',
      subtitle: 'Korean',
    ),
    OnboardingLanguage(
      code: 'zh',
      flag: '🇨🇳',
      name: '中文',
      subtitle: 'Chinese',
    ),
    OnboardingLanguage(
      code: 'es',
      flag: '🇪🇸',
      name: 'Español',
      subtitle: 'Spanish',
    ),
    OnboardingLanguage(
      code: 'fr',
      flag: '🇫🇷',
      name: 'Français',
      subtitle: 'French',
    ),
  ];

  /// Hardcoded learning language list — used when API is unavailable.
  static const List<OnboardingLanguage> learningLanguages = [
    OnboardingLanguage(
      code: 'en',
      flag: '🇬🇧',
      name: 'English',
      subtitle: 'The language to global citizen',
      isEnabled: true,
    ),
    OnboardingLanguage(
      code: 'ja',
      flag: '🇯🇵',
      name: 'Japanese',
      subtitle: 'Coming soon',
    ),
    OnboardingLanguage(
      code: 'ko',
      flag: '🇰🇷',
      name: 'Korean',
      subtitle: 'Coming soon',
    ),
    OnboardingLanguage(
      code: 'zh',
      flag: '🇨🇳',
      name: 'Chinese',
      subtitle: 'Coming soon',
    ),
    OnboardingLanguage(
      code: 'es',
      flag: '🇪🇸',
      name: 'Spanish',
      subtitle: 'Coming soon',
    ),
    OnboardingLanguage(
      code: 'fr',
      flag: '🇫🇷',
      name: 'French',
      subtitle: 'Coming soon',
    ),
  ];
}
