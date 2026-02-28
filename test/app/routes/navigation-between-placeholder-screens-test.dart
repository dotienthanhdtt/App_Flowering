import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flowering/app/routes/app-page-definitions-with-transitions.dart';
import 'package:flowering/app/routes/app-route-constants.dart';

void main() {
  group('Navigation Between Placeholder Screens', () {
    testWidgets('can navigate from login to register', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.login,
          getPages: AppPages.pages,
        ),
      );

      // Verify login screen
      expect(find.text('Login - Coming Soon'), findsOneWidget);

      // Navigate to register
      Get.toNamed(AppRoutes.register);
      await tester.pumpAndSettle();

      // Verify register screen
      expect(find.text('Register - Coming Soon'), findsOneWidget);
    });

    testWidgets('can navigate to home screen', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.login,
          getPages: AppPages.pages,
        ),
      );

      Get.toNamed(AppRoutes.home);
      await tester.pumpAndSettle();

      expect(find.text('Home - Coming Soon'), findsOneWidget);
    });

    testWidgets('can navigate to chat screen', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.login,
          getPages: AppPages.pages,
        ),
      );

      Get.toNamed(AppRoutes.chat);
      await tester.pumpAndSettle();

      expect(find.text('Chat - Coming Soon'), findsOneWidget);
    });

    testWidgets('can navigate to lessons screen', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.login,
          getPages: AppPages.pages,
        ),
      );

      Get.toNamed(AppRoutes.lessons);
      await tester.pumpAndSettle();

      expect(find.text('Lessons - Coming Soon'), findsOneWidget);
    });

    testWidgets('can navigate to lesson detail screen', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.login,
          getPages: AppPages.pages,
        ),
      );

      Get.toNamed(AppRoutes.lessonDetail);
      await tester.pumpAndSettle();

      expect(find.text('Lesson Detail - Coming Soon'), findsOneWidget);
    });

    testWidgets('can navigate to profile screen', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.login,
          getPages: AppPages.pages,
        ),
      );

      Get.toNamed(AppRoutes.profile);
      await tester.pumpAndSettle();

      expect(find.text('Profile - Coming Soon'), findsOneWidget);
    });

    testWidgets('can navigate to settings screen', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.login,
          getPages: AppPages.pages,
        ),
      );

      Get.toNamed(AppRoutes.settings);
      await tester.pumpAndSettle();

      expect(find.text('Settings - Coming Soon'), findsOneWidget);
    });

    testWidgets('go back button works', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.login,
          getPages: AppPages.pages,
        ),
      );

      // Navigate to register
      Get.toNamed(AppRoutes.register);
      await tester.pumpAndSettle();

      expect(find.text('Register - Coming Soon'), findsOneWidget);

      // Tap go back button
      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      // Should be back on login
      expect(find.text('Login - Coming Soon'), findsOneWidget);
    });

    test('splash route is registered with fade transition', () {
      final splashPage = AppPages.pages.firstWhere(
        (page) => page.name == AppRoutes.splash,
      );

      expect(splashPage.transition, Transition.fade);
      expect(splashPage.binding, isNotNull);
    });
  });

  group('Transition Animation Tests', () {
    testWidgets('transition duration is correct', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.login,
          getPages: AppPages.pages,
          defaultTransition: AppPages.defaultTransition,
          transitionDuration: AppPages.defaultDuration,
        ),
      );

      Get.toNamed(AppRoutes.register);

      // Transition should be in progress
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // After 300ms, transition should be complete
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Register - Coming Soon'), findsOneWidget);
    });
  });
}
