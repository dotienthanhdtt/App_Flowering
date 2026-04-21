import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/subscription-model.dart';
import 'revenuecat-service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_storage.dart';

/// Orchestrates subscription state by combining RevenueCat SDK + backend API.
///
/// Backend API is the source of truth; RevenueCat triggers sync on new purchases.
/// No offline cache — network error leaves the current in-memory state unchanged.
class SubscriptionService extends GetxService {
  final _revenueCatService = Get.find<RevenueCatService>();
  final _apiClient = Get.find<ApiClient>();
  final _authStorage = Get.find<AuthStorage>();

  final Rx<SubscriptionModel> currentSubscription = SubscriptionModel.free().obs;

  StreamSubscription? _customerInfoSubscription;

  bool get isPremium => currentSubscription.value.isPremium;
  SubscriptionPlan get currentPlan => currentSubscription.value.plan;

  Future<SubscriptionService> init() async {
    // Assumes RevenueCatService is a singleton for the app lifetime.
    // If RevenueCatService is ever re-created, re-call _listenToCustomerInfoChanges().
    _listenToCustomerInfoChanges();
    return this;
  }

  /// Call after user login — links RC identity and fetches backend subscription.
  Future<void> onUserLoggedIn() async {
    final userId = await _authStorage.getUserId();
    if (userId == null) return;

    if (_revenueCatService.isConfigured) {
      await _revenueCatService.logIn(userId);
    }

    await fetchSubscriptionFromBackend();
  }

  /// Call on user logout — clears RC identity and resets state.
  Future<void> onUserLoggedOut() async {
    if (_revenueCatService.isConfigured) {
      await _revenueCatService.logOut();
    }
    currentSubscription.value = SubscriptionModel.free();
  }

  /// Fetches subscription from backend (source of truth) and updates state.
  /// On error, leaves current state unchanged.
  Future<void> fetchSubscriptionFromBackend() async {
    try {
      final response = await _apiClient.get<SubscriptionModel>(
        ApiEndpoints.subscriptionMe,
        fromJson: (data) => SubscriptionModel.fromJson(data),
      );
      if (response.isSuccess && response.data != null) {
        currentSubscription.value = response.data!;
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('SubscriptionService.fetchSubscriptionFromBackend failed: $e\n$st');
      }
    }
  }

  /// Listens to RevenueCat CustomerInfo stream.
  /// On new premium entitlement, triggers a backend sync.
  void _listenToCustomerInfoChanges() {
    if (!_revenueCatService.isConfigured) return;
    _customerInfoSubscription =
        _revenueCatService.customerInfoStream.listen((info) {
      final hasPaidEntitlement =
          (info.entitlements.all['premium']?.isActive ?? false) ||
          (info.entitlements.all['premium_plus']?.isActive ?? false);
      if (hasPaidEntitlement && !isPremium) {
        // New purchase detected — backend always wins as source of truth
        fetchSubscriptionFromBackend();
      }
    });
  }

  @override
  void onClose() {
    _customerInfoSubscription?.cancel();
    super.onClose();
  }
}
