import 'package:get/get.dart';

import '../controllers/flowering_feed_controller.dart';
import '../controllers/for_you_feed_controller.dart';

/// Binds the two scenario-feed controllers for the Home screen tabs.
/// Both are `lazyPut` so they instantiate on first tab view and are
/// disposed together when the Home route unmounts.
class ScenariosBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FloweringFeedController>(() => FloweringFeedController());
    Get.lazyPut<ForYouFeedController>(() => ForYouFeedController());
  }
}
