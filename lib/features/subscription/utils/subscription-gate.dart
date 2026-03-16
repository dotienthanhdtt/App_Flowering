import 'package:get/get.dart';

import '../services/subscription-service.dart';
import '../widgets/paywall-bottom-sheet.dart';

/// Client-side feature gating utility.
///
/// NOTE: This is a UX guard only — always enforce limits server-side.
/// Never trust client subscription state for sensitive operations.
class SubscriptionGate {
  /// Whether the current user has an active premium subscription.
  static bool get isPremium => Get.find<SubscriptionService>().isPremium;

  /// Check access and show paywall if not premium.
  /// Returns true if access is granted (already premium or just purchased).
  static Future<bool> checkAccess() async {
    if (isPremium) return true;
    await PaywallBottomSheet.show();
    // Re-check after paywall dismissed — user may have purchased
    return isPremium;
  }

  /// Guard an action behind a subscription check.
  /// Runs [action] only if the user is premium or purchases during the paywall.
  static Future<void> guardAction(Future<void> Function() action) async {
    if (await checkAccess()) {
      await action();
    }
  }
}
