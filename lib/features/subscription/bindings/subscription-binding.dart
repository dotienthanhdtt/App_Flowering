import 'package:get/get.dart';

import '../controllers/paywall-controller.dart';
import '../controllers/subscription-controller.dart';

/// Dependency injection bindings for subscription feature controllers.
class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionController>(() => SubscriptionController());
    Get.lazyPut<PaywallController>(() => PaywallController());
  }
}
