import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flowering/features/chat/widgets/home-language-button.dart';
import 'package:flowering/features/onboarding/models/onboarding_language_model.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('HomeLanguageButton', () {
    testWidgets('shows globe placeholder when active is null', (tester) async {
      await tester.pumpWidget(_host(
        const HomeLanguageButton(active: null),
      ));

      expect(find.byIcon(LucideIcons.globe), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    });

    testWidgets('renders flag emoji when active language has no URL',
        (tester) async {
      const lang = OnboardingLanguage(
        code: 'vi',
        flag: '🇻🇳',
        name: 'Vietnamese',
        subtitle: 'Tiếng Việt',
        isEnabled: true,
      );

      await tester.pumpWidget(_host(
        const HomeLanguageButton(active: lang),
      ));

      expect(find.text('🇻🇳'), findsOneWidget);
      expect(find.byIcon(LucideIcons.globe), findsNothing);
    });

    testWidgets('invokes onTap when pressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        HomeLanguageButton(active: null, onTap: () => taps++),
      ));

      await tester.tap(find.byType(HomeLanguageButton));
      expect(taps, 1);
    });
  });
}
