import 'package:get/get.dart';

import '../controllers/scenario_chat_controller.dart';

class ScenarioChatBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    final scenarioId = args?['scenarioId'] as String?;
    if (scenarioId == null || scenarioId.isEmpty) {
      Get.back();
      return;
    }
    final scenarioTitle = args?['scenarioTitle'] as String? ?? '';
    final forceNew = args?['forceNew'] as bool? ?? false;
    Get.lazyPut(() => ScenarioChatController(scenarioId, scenarioTitle, forceNew));
  }
}
