import 'package:get/get.dart';
import 'english-translations-en-us.dart';
import 'vietnamese-translations-vi-vn.dart';

/// GetX translations mapping for EN and VI locales
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'vi_VN': viVN,
      };
}

/// Supported locale constants and helpers
class AppLocales {
  static const String english = 'en_US';
  static const String vietnamese = 'vi_VN';

  static const String defaultLocale = english;

  /// List of all supported locales with display names
  static final List<Map<String, String>> supportedLocales = [
    {'code': english, 'name': 'English'},
    {'code': vietnamese, 'name': 'Tiếng Việt'},
  ];
}
