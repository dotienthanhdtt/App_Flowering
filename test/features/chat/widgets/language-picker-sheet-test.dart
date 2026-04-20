import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flowering/features/chat/widgets/language-picker-sheet.dart';
import 'package:flowering/features/onboarding/models/onboarding_language_model.dart';
import 'package:flowering/l10n/english-translations-en-us.dart';

class _Translations extends Translations {
  @override
  Map<String, Map<String, String>> get keys =>
      {'en_US': enUS};
}

Widget _host(Widget child) => GetMaterialApp(
      translations: _Translations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      home: Scaffold(body: child),
    );

const _vi = OnboardingLanguage(
  id: 'id-vi',
  code: 'vi',
  flag: '🇻🇳',
  name: 'Vietnamese',
  subtitle: 'Tiếng Việt',
  isEnabled: true,
);
const _en = OnboardingLanguage(
  id: 'id-en',
  code: 'en',
  flag: '🇬🇧',
  name: 'English',
  subtitle: 'UK English',
  isEnabled: true,
);

void main() {
  group('LanguagePickerSheet', () {
    testWidgets('renders one row per language and marks active with check',
        (tester) async {
      await tester.pumpWidget(_host(
        LanguagePickerSheet(
          languages: const [_vi, _en],
          activeCode: 'vi',
          onSelect: (_) {},
        ),
      ));

      expect(find.text('Vietnamese'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('tapping a row fires onSelect with that language',
        (tester) async {
      OnboardingLanguage? picked;
      await tester.pumpWidget(_host(
        LanguagePickerSheet(
          languages: const [_vi, _en],
          activeCode: 'vi',
          onSelect: (lang) => picked = lang,
        ),
      ));

      await tester.tap(find.text('Vietnamese'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.code, 'vi');
    });

    testWidgets('shows empty-state text when languages is empty',
        (tester) async {
      await tester.pumpWidget(_host(
        LanguagePickerSheet(
          languages: const [],
          activeCode: null,
          onSelect: (_) {},
        ),
      ));

      expect(find.text('No languages yet. Add one from settings.'),
          findsOneWidget);
    });
  });
}
