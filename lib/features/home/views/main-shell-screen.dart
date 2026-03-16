import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../chat/views/chat-home-screen.dart';
import '../../lessons/views/read-screen.dart';
import '../../vocabulary/views/vocabulary-screen.dart';
import '../../profile/views/profile-screen.dart';
import '../controllers/main-shell-controller.dart';
import '../widgets/bottom-nav-bar.dart';

/// Main shell with IndexedStack tab switching and custom bottom nav
class MainShellScreen extends BaseScreen<MainShellController> {
  const MainShellScreen({super.key});

  @override
  bool get useSafeArea => false;

  @override
  bool get showLoadingOverlay => false;

  @override
  Widget? buildBottomNav(BuildContext context) => const BottomNavBar();

  @override
  Widget buildContent(BuildContext context) {
    return Obx(() => IndexedStack(
      index: controller.selectedIndex.value,
      children: const [
        ChatHomeScreen(),
        ReadScreen(),
        VocabularyScreen(),
        ProfileScreen(),
      ],
    ));
  }
}
