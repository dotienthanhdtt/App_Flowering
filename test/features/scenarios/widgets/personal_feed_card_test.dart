import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flowering/features/scenarios/models/personal_scenario_item.dart';
import 'package:flowering/features/scenarios/models/personal_source.dart';
import 'package:flowering/features/scenarios/models/scenario_access_tier.dart';
import 'package:flowering/features/scenarios/models/scenario_type.dart';
import 'package:flowering/features/scenarios/models/scenario_user_status.dart';
import 'package:flowering/features/scenarios/widgets/personal_feed_card.dart';
import 'package:flowering/l10n/english-translations-en-us.dart';

PersonalScenarioItem _item({
  required PersonalSource source,
  required ScenarioUserStatus status,
}) =>
    PersonalScenarioItem(
      id: 'id',
      title: 'Morning routine',
      description: 'Talk about your morning',
      difficulty: 'beginner',
      languageId: 'en',
      addedAt: DateTime.utc(2026, 4, 20),
      source: source,
      accessTier: ScenarioAccessTier.free,
      status: status,
      type: ScenarioType.defaultType,
    );

Widget _host(Widget child) {
  return GetMaterialApp(
    translationsKeys: {'en_US': enUS},
    locale: const Locale('en', 'US'),
    fallbackLocale: const Locale('en', 'US'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('PersonalFeedCard', () {
    testWidgets('shows AI badge when source is personalized', (tester) async {
      await tester.pumpWidget(_host(PersonalFeedCard(
        item: _item(
          source: PersonalSource.personalized,
          status: ScenarioUserStatus.available,
        ),
      )));
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('KOL'), findsNothing);
    });

    testWidgets('shows KOL badge when source is kol', (tester) async {
      await tester.pumpWidget(_host(PersonalFeedCard(
        item: _item(
          source: PersonalSource.kol,
          status: ScenarioUserStatus.available,
        ),
      )));
      expect(find.text('KOL'), findsOneWidget);
      expect(find.text('AI'), findsNothing);
    });

    testWidgets('shows trailing check when status is learned', (tester) async {
      await tester.pumpWidget(_host(PersonalFeedCard(
        item: _item(
          source: PersonalSource.personalized,
          status: ScenarioUserStatus.learned,
        ),
      )));
      expect(find.byIcon(LucideIcons.checkCircle), findsOneWidget);
    });

    testWidgets('hides trailing check when status is available',
        (tester) async {
      await tester.pumpWidget(_host(PersonalFeedCard(
        item: _item(
          source: PersonalSource.personalized,
          status: ScenarioUserStatus.available,
        ),
      )));
      expect(find.byIcon(LucideIcons.checkCircle), findsNothing);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(PersonalFeedCard(
        item: _item(
          source: PersonalSource.personalized,
          status: ScenarioUserStatus.available,
        ),
        onTap: () => taps++,
      )));
      await tester.tap(find.byType(PersonalFeedCard));
      expect(taps, 1);
    });
  });
}
