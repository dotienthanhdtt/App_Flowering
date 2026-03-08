import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chat/views/chat-home-screen.dart';
import '../../lessons/views/read-screen.dart';
import '../../vocabulary/views/vocabulary-screen.dart';
import '../../profile/views/profile-screen.dart';
import '../controllers/main-shell-controller.dart';
import '../widgets/bottom-nav-bar.dart';

/// Main shell with IndexedStack tab switching and custom bottom nav
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainShellController>();

    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.selectedIndex.value,
        children: const [
          ChatHomeScreen(),
          ReadScreen(),
          VocabularyScreen(),
          ProfileScreen(),
        ],
      )),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
