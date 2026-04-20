import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app-route-constants.dart';
import 'app-route-transition-config.dart';
import 'app-onboarding-pages.dart';
import 'app-auth-pages.dart';
import 'app-main-pages.dart';

/// GetPage definitions with transitions and bindings
abstract class AppPages {
  /// Default transition configuration
  static const Transition defaultTransition = kDefaultTransition;
  static const Duration defaultDuration = kDefaultDuration;
  static const Curve defaultCurve = kDefaultCurve;

  /// Initial route — splash handles auth check + routing
  static String get initialRoute => AppRoutes.splash;

  /// All app pages with routes, screens, and transitions
  static final List<GetPage> pages = [
    ...onboardingPages,
    ...authPages,
    ...mainPages,
  ];
}
