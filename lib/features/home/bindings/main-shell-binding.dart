import 'package:get/get.dart';

import '../controllers/main-shell-controller.dart';
import '../../chat/controllers/chat-home-controller.dart';
import '../../lessons/controllers/read-controller.dart';
import '../../vocabulary/controllers/vocabulary-controller.dart';
import '../../profile/controllers/profile-controller.dart';

/// Registers MainShellController + all tab controllers
class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<MainShellController>(MainShellController(), permanent: true);
    Get.lazyPut<ChatHomeController>(() => ChatHomeController(), fenix: true);
    Get.lazyPut<ReadController>(() => ReadController(), fenix: true);
    Get.lazyPut<VocabularyController>(() => VocabularyController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
  }
}
