import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flowering/features/scenarios/models/scenario_access_tier.dart';
import 'package:flowering/features/scenarios/widgets/access_tier_badge.dart';
import 'package:flowering/l10n/english-translations-en-us.dart';

Widget _host(Widget child) {
  return GetMaterialApp(
    translationsKeys: {'en_US': enUS},
    locale: const Locale('en', 'US'),
    fallbackLocale: const Locale('en', 'US'),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('AccessTierBadge', () {
    testWidgets('renders PRO pill when tier is premium', (tester) async {
      await tester.pumpWidget(
        _host(const AccessTierBadge(tier: ScenarioAccessTier.premium)),
      );
      expect(find.text('PRO'), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink when tier is free', (tester) async {
      await tester.pumpWidget(
        _host(const AccessTierBadge(tier: ScenarioAccessTier.free)),
      );
      expect(find.text('PRO'), findsNothing);
      final shrink = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(shrink.width ?? -1, 0);
      expect(shrink.height ?? -1, 0);
    });
  });
}
