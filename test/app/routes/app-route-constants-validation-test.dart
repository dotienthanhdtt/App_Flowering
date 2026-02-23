import 'package:flutter_test/flutter_test.dart';
import 'package:flowering/app/routes/app-route-constants.dart';

void main() {
  group('AppRoutes Constants', () {
    test('all route paths are defined correctly', () {
      expect(AppRoutes.splash, '/');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.register, '/register');
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.chat, '/chat');
      expect(AppRoutes.lessons, '/lessons');
      expect(AppRoutes.lessonDetail, '/lessons/detail');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.settings, '/settings');
    });

    test('routes follow /feature/action pattern', () {
      expect(AppRoutes.splash.startsWith('/'), isTrue);
      expect(AppRoutes.login.startsWith('/'), isTrue);
      expect(AppRoutes.lessonDetail, contains('/lessons/'));
    });

    test('no duplicate route paths', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.home,
        AppRoutes.chat,
        AppRoutes.lessons,
        AppRoutes.lessonDetail,
        AppRoutes.profile,
        AppRoutes.settings,
      ];

      final uniqueRoutes = routes.toSet();
      expect(uniqueRoutes.length, routes.length);
    });
  });
}
