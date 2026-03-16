# Phase 4: Subscription Service

## Context Links
- [Brainstorm](../reports/brainstorm-260313-revenuecat-payment-feature.md) — Architecture section
- [Backend API Research](../reports/researcher-260313-backend-subscription-api.md)

## Overview
- **Priority:** Critical
- **Status:** Complete (2026-03-14)
- **Description:** Orchestration service combining RevenueCat SDK + backend API. Manages subscription state, caching, and feature access checks.

## Key Insights
- Hybrid state: RC SDK for instant UX, backend API as source of truth
- Cache subscription state in Hive for offline access
- Single entitlement ID: `premium`
- Expose simple boolean checks for feature gating

## Requirements
- Fetch and cache subscription from backend API
- Sync with RevenueCat CustomerInfo
- Expose reactive `currentSubscription` state
- Provide `isPremium`, `currentPlan` getters
- Handle logIn/logOut lifecycle
- Listen to CustomerInfo stream for real-time updates

## Related Code Files

### Files to Create
- `lib/features/subscription/services/subscription-service.dart`

### Dependencies
- Phase 2: SubscriptionModel
- Phase 3: RevenueCatService
- `lib/core/network/api_client.dart` — for backend API calls
- `lib/core/services/auth_storage.dart` — for user ID

## Implementation Steps

1. **Create SubscriptionService:**
   ```dart
   class SubscriptionService extends GetxService {
     final _revenueCatService = Get.find<RevenueCatService>();
     final _apiClient = Get.find<ApiClient>();
     final _authStorage = Get.find<AuthStorage>();

     final Rx<SubscriptionModel> currentSubscription =
         SubscriptionModel.free().obs;

     bool get isPremium => currentSubscription.value.isPremium;
     SubscriptionPlan get currentPlan => currentSubscription.value.plan;

     Future<SubscriptionService> init() async {
       _listenToCustomerInfoChanges();
       return this;
     }

     /// Call after user login
     Future<void> onUserLoggedIn() async {
       final userId = _authStorage.getUserId();
       if (userId == null) return;

       // Link RC user to backend user
       if (_revenueCatService.isConfigured) {
         await _revenueCatService.logIn(userId);
       }

       // Fetch from backend (source of truth)
       await fetchSubscriptionFromBackend();
     }

     /// Call on user logout
     Future<void> onUserLoggedOut() async {
       if (_revenueCatService.isConfigured) {
         await _revenueCatService.logOut();
       }
       currentSubscription.value = SubscriptionModel.free();
       _clearCache();
     }

     Future<void> fetchSubscriptionFromBackend() async {
       try {
         final response = await _apiClient.get<SubscriptionModel>(
           ApiEndpoints.subscriptionMe,
           fromJson: (data) => SubscriptionModel.fromJson(data),
         );
         if (response.isSuccess && response.data != null) {
           currentSubscription.value = response.data!;
           _cacheSubscription(response.data!);
         }
       } catch (e) {
         // Fallback to cache
         _loadCachedSubscription();
       }
     }

     void _listenToCustomerInfoChanges() {
       if (!_revenueCatService.isConfigured) return;
       _revenueCatService.customerInfoStream.listen((info) {
         // If RC says premium, update optimistically
         final hasPremium = info.entitlements.all['premium']?.isActive ?? false;
         if (hasPremium && !isPremium) {
           // RC detected new purchase — sync with backend
           fetchSubscriptionFromBackend();
         }
       });
     }

     void _cacheSubscription(SubscriptionModel sub) {
       // Hive cache implementation
     }

     void _loadCachedSubscription() {
       // Load from Hive cache
     }

     void _clearCache() {
       // Clear Hive cache
     }
   }
   ```

2. **Hive caching:** Use existing StorageService pattern or direct Hive box.

3. **Verify:** `flutter analyze`

## Todo List
- [x] Create subscription-service.dart
- [x] Implement onUserLoggedIn (RC logIn + backend fetch)
- [x] Implement onUserLoggedOut (RC logOut + clear state)
- [x] Implement fetchSubscriptionFromBackend
- [x] Implement CustomerInfo stream listener
- [x] Implement Hive caching (cache/load/clear)
- [x] Run `flutter analyze` (0 errors)

## Success Criteria
- Subscription state correctly reflects backend data
- RC CustomerInfo changes trigger backend sync
- Offline: cached subscription used as fallback
- Clean logIn/logOut lifecycle

## Risk Assessment
- **Race condition:** RC stream update vs backend fetch — backend always wins as source of truth
- **Offline purchase:** RC handles locally, app syncs on next backend call

## Next Steps
- Phase 5: Controllers
