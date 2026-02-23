import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app-route-constants.dart';

// Placeholder screen for initial setup
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title - Coming Soon',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// GetPage definitions with transitions and bindings
abstract class AppPages {
  /// Default transition configuration
  static const Transition defaultTransition = Transition.rightToLeft;
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOut;

  /// Initial route (will be determined by auth state later)
  static String get initialRoute => AppRoutes.login;

  /// All app pages with routes, screens, and transitions
  static final List<GetPage> pages = [
    // Splash screen with fade transition
    GetPage(
      name: AppRoutes.splash,
      page: () => const _PlaceholderScreen('Splash'),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    // Auth screens
    GetPage(
      name: AppRoutes.login,
      page: () => const _PlaceholderScreen('Login'),
      // binding: AuthBinding(), // Will be uncommented when auth feature is ready
      transition: Transition.fade,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const _PlaceholderScreen('Register'),
      // binding: AuthBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Home screen with fade transition
    GetPage(
      name: AppRoutes.home,
      page: () => const _PlaceholderScreen('Home'),
      // binding: HomeBinding(),
      transition: Transition.fade,
      transitionDuration: defaultDuration,
    ),

    // Chat screen
    GetPage(
      name: AppRoutes.chat,
      page: () => const _PlaceholderScreen('Chat'),
      // binding: ChatBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Lessons screens
    GetPage(
      name: AppRoutes.lessons,
      page: () => const _PlaceholderScreen('Lessons'),
      // binding: LessonBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),
    GetPage(
      name: AppRoutes.lessonDetail,
      page: () => const _PlaceholderScreen('Lesson Detail'),
      // binding: LessonBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Profile screen
    GetPage(
      name: AppRoutes.profile,
      page: () => const _PlaceholderScreen('Profile'),
      // binding: ProfileBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Settings screen
    GetPage(
      name: AppRoutes.settings,
      page: () => const _PlaceholderScreen('Settings'),
      // binding: SettingsBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),
  ];
}
