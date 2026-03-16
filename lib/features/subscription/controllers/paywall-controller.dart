import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/base/base_controller.dart';
import '../models/offering-model.dart';
import '../services/revenuecat-service.dart';
import '../services/subscription-service.dart';

/// Manages paywall UI state: fetches offerings and handles purchase flow.
class PaywallController extends BaseController {
  final _revenueCatService = Get.find<RevenueCatService>();
  final _subscriptionService = Get.find<SubscriptionService>();

  final offerings = <OfferingModel>[].obs;
  final isPurchasing = false.obs;
  final selectedPackageIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOfferings();
  }

  Future<void> fetchOfferings() async {
    await apiCall(
      () async {
        final rcOfferings = await _revenueCatService.getOfferings();
        if (rcOfferings.current != null) {
          offerings.value = rcOfferings.current!.availablePackages
              .map(OfferingModel.fromRCPackage)
              .toList();
        }
      },
      showLoading: true,
    );
  }

  Future<bool> purchase(OfferingModel offering) async {
    if (isPurchasing.value) return false; // prevent concurrent purchases
    isPurchasing.value = true;
    errorMessage.value = '';
    try {
      await _revenueCatService.purchasePackage(offering.rcPackage);
      await _subscriptionService.fetchSubscriptionFromBackend();
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        errorMessage.value = 'Purchase failed. Please try again.';
      }
      return false;
    } catch (_) {
      // Handles StateError from unconfigured RevenueCat and other unexpected errors
      errorMessage.value = 'Purchase failed. Please try again.';
      return false;
    } finally {
      isPurchasing.value = false;
    }
  }

  Future<void> restorePurchases() async {
    await apiCall(
      () async {
        await _revenueCatService.restorePurchases();
        await _subscriptionService.fetchSubscriptionFromBackend();
      },
      showLoading: true,
    );
  }
}
