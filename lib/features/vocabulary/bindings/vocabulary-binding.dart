import 'package:get/get.dart';

import '../controllers/vocabulary-controller.dart';
import '../services/vocabulary-service.dart';

class VocabularyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VocabularyService>(() => VocabularyService(), fenix: true);
    Get.lazyPut<VocabularyController>(() => VocabularyController());
  }
}
