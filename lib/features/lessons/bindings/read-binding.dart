import 'package:get/get.dart';

import '../controllers/read-controller.dart';

class ReadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReadController>(() => ReadController());
  }
}
