class OnboardingLanguage {
  final String code;
  final String flag;
  final String name;
  final String subtitle;
  final bool isEnabled;

  const OnboardingLanguage({
    required this.code,
    required this.flag,
    required this.name,
    required this.subtitle,
    this.isEnabled = false,
  });

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
