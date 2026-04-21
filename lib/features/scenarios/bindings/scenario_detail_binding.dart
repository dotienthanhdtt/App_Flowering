import 'package:get/get.dart';

import '../controllers/scenario_detail_controller.dart';

class ScenarioDetailBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    final id = args?['id'] as String?;
    if (id == null || id.isEmpty) {
      Get.back();
      return;
    }
    Get.lazyPut(() => ScenarioDetailController(id));
  }
}
