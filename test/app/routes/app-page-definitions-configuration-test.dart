import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flowering/app/routes/app-page-definitions-with-transitions.dart';
import 'package:flowering/app/routes/app-route-constants.dart';

void main() {
  group('AppPages Configuration', () {
    test('default transition is rightToLeft', () {
      expect(AppPages.defaultTransition, Transition.rightToLeft);
    });

    test('default duration is 300ms', () {
      expect(AppPages.defaultDuration, const Duration(milliseconds: 300));
    });

    test('default curve is easeInOut', () {
      expect(AppPages.defaultCurve, Curves.easeInOut);
    });

    test('initial route is login', () {
      expect(AppPages.initialRoute, AppRoutes.login);
    });

    test('all required routes are defined', () {
      final routeNames = AppPages.pages.map((page) => page.name).toList();

      expect(routeNames, contains(AppRoutes.splash));
      expect(routeNames, contains(AppRoutes.login));
      expect(routeNames, contains(AppRoutes.register));
      expect(routeNames, contains(AppRoutes.home));
      expect(routeNames, contains(AppRoutes.chat));
      expect(routeNames, contains(AppRoutes.lessons));
      expect(routeNames, contains(AppRoutes.lessonDetail));
      expect(routeNames, contains(AppRoutes.profile));
      expect(routeNames, contains(AppRoutes.settings));
    });

    test('splash screen has fade transition', () {
      final splashPage = AppPages.pages.firstWhere(
        (page) => page.name == AppRoutes.splash,
      );

      expect(splashPage.transition, Transition.fade);
      expect(splashPage.transitionDuration, const Duration(milliseconds: 500));
    });

    test('login screen has fade transition', () {
      final loginPage = AppPages.pages.firstWhere(
        (page) => page.name == AppRoutes.login,
      );

      expect(loginPage.transition, Transition.fade);
    });

    test('home screen has fade transition', () {
      final homePage = AppPages.pages.firstWhere(
        (page) => page.name == AppRoutes.home,
      );

      expect(homePage.transition, Transition.fade);
    });

    test('other screens use rightToLeft transition', () {
      final pagesWithRightToLeft = [
        AppRoutes.register,
        AppRoutes.chat,
        AppRoutes.lessons,
        AppRoutes.lessonDetail,
        AppRoutes.profile,
        AppRoutes.settings,
      ];

      for (final routeName in pagesWithRightToLeft) {
        final page = AppPages.pages.firstWhere(
          (page) => page.name == routeName,
        );
        expect(page.transition, Transition.rightToLeft);
      }
    });

    test('no duplicate route names', () {
      final routeNames = AppPages.pages.map((page) => page.name).toList();
      final uniqueNames = routeNames.toSet();

      expect(uniqueNames.length, routeNames.length);
    });

    test('all pages have page builders', () {
      for (final page in AppPages.pages) {
        expect(page.page, isNotNull);
      }
    });
  });
}
