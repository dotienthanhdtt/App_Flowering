import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flowering/features/scenarios/models/scenario_access_tier.dart';
import 'package:flowering/features/scenarios/models/scenario_feed_item.dart';
import 'package:flowering/features/scenarios/models/scenario_type.dart';
import 'package:flowering/features/scenarios/models/scenario_user_status.dart';
import 'package:flowering/features/scenarios/widgets/feed_scenario_card.dart';
import 'package:flowering/l10n/english-translations-en-us.dart';

ScenarioFeedItem _item({
  required ScenarioAccessTier tier,
  required ScenarioUserStatus status,
  String? imageUrl,
}) =>
    ScenarioFeedItem(
      id: 'id',
      title: 'Order coffee',
      description: 'Practice ordering coffee at a cafe',
      imageUrl: imageUrl,
      difficulty: 'beginner',
      languageId: 'en',
      accessTier: tier,
      status: status,
      type: ScenarioType.defaultType,
      orderIndex: 0,
    );

Widget _host(Widget child) {
  return GetMaterialApp(
    translationsKeys: {'en_US': enUS},
    locale: const Locale('en', 'US'),
    fallbackLocale: const Locale('en', 'US'),
    home: Scaffold(
      body: SizedBox(width: 180, height: 230, child: child),
    ),
  );
}

void main() {
  group('FeedScenarioCard', () {
    testWidgets('renders placeholder when imageUrl missing', (tester) async {
      await tester.pumpWidget(_host(FeedScenarioCard(
        item: _item(
          tier: ScenarioAccessTier.free,
          status: ScenarioUserStatus.available,
        ),
      )));
      expect(find.byIcon(LucideIcons.image), findsOneWidget);
    });

    testWidgets('renders title from item', (tester) async {
      await tester.pumpWidget(_host(FeedScenarioCard(
        item: _item(
          tier: ScenarioAccessTier.free,
          status: ScenarioUserStatus.available,
        ),
      )));
      expect(find.text('Order coffee'), findsOneWidget);
    });

    testWidgets('renders check badge when status is learned', (tester) async {
      await tester.pumpWidget(_host(FeedScenarioCard(
        item: _item(
          tier: ScenarioAccessTier.free,
          status: ScenarioUserStatus.learned,
        ),
      )));
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsNothing);
    });

    testWidgets('renders lock badge when status is locked', (tester) async {
      await tester.pumpWidget(_host(FeedScenarioCard(
        item: _item(
          tier: ScenarioAccessTier.free,
          status: ScenarioUserStatus.locked,
        ),
      )));
      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsNothing);
    });

    testWidgets('renders no status badge when status is available',
        (tester) async {
      await tester.pumpWidget(_host(FeedScenarioCard(
        item: _item(
          tier: ScenarioAccessTier.free,
          status: ScenarioUserStatus.available,
        ),
      )));
      expect(find.byIcon(LucideIcons.check), findsNothing);
      expect(find.byIcon(LucideIcons.lock), findsNothing);
    });

    testWidgets('renders PRO badge when accessTier is premium', (tester) async {
      await tester.pumpWidget(_host(FeedScenarioCard(
        item: _item(
          tier: ScenarioAccessTier.premium,
          status: ScenarioUserStatus.available,
        ),
      )));
      expect(find.text('PRO'), findsOneWidget);
    });

    testWidgets('hides PRO badge when accessTier is free', (tester) async {
      await tester.pumpWidget(_host(FeedScenarioCard(
        item: _item(
          tier: ScenarioAccessTier.free,
          status: ScenarioUserStatus.available,
        ),
      )));
      expect(find.text('PRO'), findsNothing);
    });

    // Full 3×2 matrix — asserts combined status + tier.
    for (final status in ScenarioUserStatus.values) {
      for (final tier in ScenarioAccessTier.values) {
        testWidgets('renders ${status.name} × ${tier.name} without error',
            (tester) async {
          await tester.pumpWidget(_host(FeedScenarioCard(
            item: _item(tier: tier, status: status),
          )));
          expect(tester.takeException(), isNull);
          expect(find.byType(FeedScenarioCard), findsOneWidget);
        });
      }
    }
  });
}
