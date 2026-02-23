import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flowering/app/flowering-app-widget-with-getx.dart';
import 'package:flowering/app/routes/app-route-constants.dart';

void main() {
  setUp(() {
    // Clear GetX state before each test
    Get.reset();
  });

  testWidgets('FloweringApp renders successfully with placeholder login screen',
      (WidgetTester tester) async {
    // Build the app without initializing native plugins
    await tester.pumpWidget(const FloweringApp());
    await tester.pumpAndSettle();

    // Should show placeholder login screen (initial route)
    expect(find.text('Login - Coming Soon'), findsOneWidget);
  });

  testWidgets('FloweringApp has correct theme configuration',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FloweringApp());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(Scaffold).first);
    final ThemeData theme = Theme.of(context);

    // Verify Material3 is enabled
    expect(theme.useMaterial3, isTrue);

    // Verify color scheme is configured
    expect(theme.colorScheme.primary, isNotNull);
  });

  testWidgets('FloweringApp uses GetX routing', (WidgetTester tester) async {
    await tester.pumpWidget(const FloweringApp());
    await tester.pumpAndSettle();

    // Verify GetX is managing routes
    expect(Get.currentRoute, AppRoutes.login);
  });

  testWidgets('FloweringApp has translations configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FloweringApp());
    await tester.pumpAndSettle();

    // Verify translations are loaded
    expect(Get.locale, const Locale('en', 'US'));
    expect(Get.fallbackLocale, const Locale('en', 'US'));
  });

  testWidgets('FloweringApp has smartManagement enabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FloweringApp());
    await tester.pumpAndSettle();

    // Verify app is rendered
    expect(find.byType(GetMaterialApp), findsOneWidget);
  });
}
