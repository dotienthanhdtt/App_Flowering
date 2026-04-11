import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../models/subscription-model.dart';
import 'revenuecat-service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_storage.dart';
import '../../../core/services/storage_service.dart';

/// Orchestrates subscription state by combining RevenueCat SDK + backend API.
///
/// Backend API is the source of truth; RevenueCat triggers sync on new purchases.
/// Subscription state is cached in Hive via StorageService for offline access.
class SubscriptionService extends GetxService {
  final _revenueCatService = Get.find<RevenueCatService>();
  final _apiClient = Get.find<ApiClient>();
  final _authStorage = Get.find<AuthStorage>();
  final _storageService = Get.find<StorageService>();

  static const String _cacheKey = 'subscription_cache';

  final Rx<SubscriptionModel> currentSubscription = SubscriptionModel.free().obs;

  StreamSubscription? _customerInfoSubscription;

  bool get isPremium => currentSubscription.value.isPremium;
  SubscriptionPlan get currentPlan => currentSubscription.value.plan;

  Future<SubscriptionService> init() async {
    _loadCachedSubscription();
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

  /// Call on user logout — clears RC identity, resets state, clears cache.
  Future<void> onUserLoggedOut() async {
    if (_revenueCatService.isConfigured) {
      await _revenueCatService.logOut();
    }
    currentSubscription.value = SubscriptionModel.free();
    await _clearCache();
  }

  /// Fetches subscription from backend (source of truth) and updates state.
  /// Falls back to cached subscription on error.
  Future<void> fetchSubscriptionFromBackend() async {
    try {
      final response = await _apiClient.get<SubscriptionModel>(
        ApiEndpoints.subscriptionMe,
        fromJson: (data) => SubscriptionModel.fromJson(data),
      );
      if (response.isSuccess && response.data != null) {
        currentSubscription.value = response.data!;
        await _cacheSubscription(response.data!);
      }
    } catch (_) {
      // Network or parse error — fall back to cached data
      _loadCachedSubscription();
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

  Future<void> _cacheSubscription(SubscriptionModel sub) async {
    final jsonString = jsonEncode(sub.toJson());
    await _storageService.setPreference<String>(_cacheKey, jsonString);
  }

  void _loadCachedSubscription() {
    final jsonString = _storageService.getPreference<String>(_cacheKey);
    if (jsonString == null) return;
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      currentSubscription.value = SubscriptionModel.fromJson(json);
    } catch (_) {
      // Corrupted cache — retain free tier default
    }
  }

  Future<void> _clearCache() async {
    await _storageService.removePreference(_cacheKey);
  }

  @override
  void onClose() {
    _customerInfoSubscription?.cancel();
    super.onClose();
  }
}
