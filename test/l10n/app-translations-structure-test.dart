import 'package:flutter_test/flutter_test.dart';
import 'package:flowering/l10n/app-translations-loader.dart';
import 'package:flowering/l10n/english-translations-en-us.dart';
import 'package:flowering/l10n/vietnamese-translations-vi-vn.dart';

void main() {
  group('AppTranslations Structure', () {
    late AppTranslations translations;

    setUp(() {
      translations = AppTranslations();
    });

    test('contains en_US locale', () {
      expect(translations.keys, containsPair('en_US', anything));
    });

    test('contains vi_VN locale', () {
      expect(translations.keys, containsPair('vi_VN', anything));
    });

    test('en_US translations match enUS map', () {
      expect(translations.keys['en_US'], enUS);
    });

    test('vi_VN translations match viVN map', () {
      expect(translations.keys['vi_VN'], viVN);
    });

    test('both locales have same keys', () {
      final enKeys = enUS.keys.toSet();
      final viKeys = viVN.keys.toSet();

      expect(enKeys, viKeys, reason: 'EN and VI should have identical translation keys');
    });

    test('no empty translation values', () {
      for (final value in enUS.values) {
        expect(value.trim().isNotEmpty, isTrue);
      }

      for (final value in viVN.values) {
        expect(value.trim().isNotEmpty, isTrue);
      }
    });
  });

  group('AppLocales Configuration', () {
    test('default locale is english', () {
      expect(AppLocales.defaultLocale, AppLocales.english);
    });

    test('english locale is en_US', () {
      expect(AppLocales.english, 'en_US');
    });

    test('vietnamese locale is vi_VN', () {
      expect(AppLocales.vietnamese, 'vi_VN');
    });

    test('supported locales contains both languages', () {
      expect(AppLocales.supportedLocales.length, 2);

      final codes = AppLocales.supportedLocales.map((l) => l['code']).toList();
      expect(codes, contains('en_US'));
      expect(codes, contains('vi_VN'));
    });

    test('supported locales have display names', () {
      for (final locale in AppLocales.supportedLocales) {
        expect(locale['code'], isNotNull);
        expect(locale['name'], isNotNull);
        expect(locale['name']!.isNotEmpty, isTrue);
      }
    });
  });

  group('Translation Key Categories', () {
    test('common keys exist in both locales', () {
      final commonKeys = [
        'app_name', 'loading', 'error', 'success', 'cancel',
        'confirm', 'save', 'delete', 'edit', 'retry', 'ok', 'yes', 'no'
      ];

      for (final key in commonKeys) {
        expect(enUS, containsPair(key, anything));
        expect(viVN, containsPair(key, anything));
      }
    });

    test('auth keys exist in both locales', () {
      final authKeys = [
        'login', 'register', 'logout', 'email', 'password',
        'confirm_password', 'forgot_password', 'login_success', 'register_success'
      ];

      for (final key in authKeys) {
        expect(enUS, containsPair(key, anything));
        expect(viVN, containsPair(key, anything));
      }
    });

    test('validation keys exist in both locales', () {
      final validationKeys = [
        'email_required', 'email_invalid', 'password_required',
        'password_min_length', 'passwords_not_match'
      ];

      for (final key in validationKeys) {
        expect(enUS, containsPair(key, anything));
        expect(viVN, containsPair(key, anything));
      }
    });

    test('navigation keys exist in both locales', () {
      final navKeys = [
        'home', 'chat', 'lessons', 'profile', 'settings'
      ];

      for (final key in navKeys) {
        expect(enUS, containsPair(key, anything));
        expect(viVN, containsPair(key, anything));
      }
    });

    test('error keys exist in both locales', () {
      final errorKeys = [
        'network_error', 'server_error', 'session_expired', 'unknown_error'
      ];

      for (final key in errorKeys) {
        expect(enUS, containsPair(key, anything));
        expect(viVN, containsPair(key, anything));
      }
    });
  });
}
