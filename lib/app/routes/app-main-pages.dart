import 'package:get/get.dart';
import 'app-route-constants.dart';
import 'app-route-transition-config.dart';
import 'app-placeholder-screen.dart';
import '../../features/chat/bindings/ai_chat_binding.dart';
import '../../features/chat/views/ai_chat_screen.dart';
import '../../features/home/views/main-shell-screen.dart';
import '../../features/home/bindings/main-shell-binding.dart';
import '../../features/subscription/bindings/subscription-binding.dart';
import '../../features/subscription/views/paywall-screen.dart';

/// Main app pages: home shell, chat, lessons, profile, settings, paywall
final List<GetPage> mainPages = [
  // Home — main shell with bottom nav
  GetPage(
    name: AppRoutes.home,
    page: () => const MainShellScreen(),
    binding: MainShellBinding(),
    transition: Transition.fade,
    transitionDuration: kDefaultDuration,
  ),

  // Chat screen — AI onboarding flow (Screen 3)
  GetPage(
    name: AppRoutes.chat,
    page: () => const AiChatScreen(),
    binding: AiChatBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Lessons screens
  GetPage(
    name: AppRoutes.lessons,
    page: () => const AppPlaceholderScreen('Lessons'),
    // binding: LessonBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),
  GetPage(
    name: AppRoutes.lessonDetail,
    page: () => const AppPlaceholderScreen('Lesson Detail'),
    // binding: LessonBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Profile screen
  GetPage(
    name: AppRoutes.profile,
    page: () => const AppPlaceholderScreen('Profile'),
    // binding: ProfileBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Settings screen
  GetPage(
    name: AppRoutes.settings,
    page: () => const AppPlaceholderScreen('Settings'),
    // binding: SettingsBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Paywall screen
  GetPage(
    name: AppRoutes.paywall,
    page: () => const PaywallScreen(),
    binding: SubscriptionBinding(),
    transition: Transition.downToUp,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),
];
