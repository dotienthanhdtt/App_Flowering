import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../models/subscription-model.dart';
import '../services/subscription-service.dart';

/// Exposes reactive subscription state for UI consumption.
/// Delegates all business logic to SubscriptionService.
class SubscriptionController extends BaseController {
  final _subscriptionService = Get.find<SubscriptionService>();

  Rx<SubscriptionModel> get subscription =>
      _subscriptionService.currentSubscription;

  bool get isPremium => _subscriptionService.isPremium;

  SubscriptionPlan get currentPlan => _subscriptionService.currentPlan;

  Future<void> refreshSubscription() async {
    await apiCall(
      () => _subscriptionService.fetchSubscriptionFromBackend(),
    );
  }
}
