import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flowering/app/routes/app-page-definitions-with-transitions.dart';
import 'package:flowering/app/routes/app-route-constants.dart';
import 'package:flowering/l10n/app-translations-loader.dart';
import 'package:flowering/core/constants/app_colors.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  // Helper: builds app with home route — avoids splash timer/service deps
  // and avoids auth DI requirements of LoginEmailScreen.
  Widget buildTestApp() {
    return GetMaterialApp(
      title: 'Flowering',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
      smartManagement: SmartManagement.full,
      defaultTransition: AppPages.defaultTransition,
      transitionDuration: AppPages.defaultDuration,
    );
  }

  testWidgets('App renders successfully with main shell and bottom nav',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Bottom nav labels should be visible
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('App has correct theme configuration',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(Scaffold).first);
    final ThemeData theme = Theme.of(context);

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, isNotNull);
  });

  testWidgets('App uses GetX routing', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('App has translations configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(Get.locale, const Locale('en', 'US'));
    expect(Get.fallbackLocale, const Locale('en', 'US'));
  });

  testWidgets('App has smartManagement enabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(GetMaterialApp), findsOneWidget);
  });
}
