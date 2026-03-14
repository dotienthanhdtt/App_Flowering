# Phase 5: Controllers

## Context Links
- [Brainstorm](../reports/brainstorm-260313-revenuecat-payment-feature.md) — Architecture section

## Overview
- **Priority:** High
- **Status:** Complete
- **Description:** Create SubscriptionController (reactive UI state) and PaywallController (offerings + purchase flow).

## Requirements
- SubscriptionController: exposes reactive subscription state for UI
- PaywallController: fetches offerings, handles purchase flow, manages loading/error states
- Both follow BaseController pattern
- Binding for dependency injection

## Related Code Files

### Files to Create
- `lib/features/subscription/controllers/subscription-controller.dart`
- `lib/features/subscription/controllers/paywall-controller.dart`
- `lib/features/subscription/bindings/subscription-binding.dart`

### Dependencies
- Phase 4: SubscriptionService
- Phase 3: RevenueCatService
- Phase 2: OfferingModel

## Implementation Steps

1. **SubscriptionController:**
   ```dart
   class SubscriptionController extends GetxController {
     final _subscriptionService = Get.find<SubscriptionService>();

     Rx<SubscriptionModel> get subscription =>
         _subscriptionService.currentSubscription;
     bool get isPremium => _subscriptionService.isPremium;
     SubscriptionPlan get currentPlan => _subscriptionService.currentPlan;

     Future<void> refreshSubscription() async {
       await _subscriptionService.fetchSubscriptionFromBackend();
     }
   }
   ```

2. **PaywallController:**
   ```dart
   class PaywallController extends GetxController {
     final _revenueCatService = Get.find<RevenueCatService>();
     final _subscriptionService = Get.find<SubscriptionService>();

     final offerings = <OfferingModel>[].obs;
     final isLoading = false.obs;
     final isPurchasing = false.obs;
     final errorMessage = ''.obs;
     final selectedPackageIndex = 0.obs;

     @override
     void onInit() {
       super.onInit();
       fetchOfferings();
     }

     Future<void> fetchOfferings() async {
       isLoading.value = true;
       errorMessage.value = '';
       try {
         final rcOfferings = await _revenueCatService.getOfferings();
         if (rcOfferings.current != null) {
           offerings.value = rcOfferings.current!.availablePackages
               .map((p) => OfferingModel.fromRCPackage(p))
               .toList();
         }
       } catch (e) {
         errorMessage.value = 'Failed to load plans. Please try again.';
       } finally {
         isLoading.value = false;
       }
     }

     Future<bool> purchase(OfferingModel offering) async {
       isPurchasing.value = true;
       errorMessage.value = '';
       try {
         await _revenueCatService.purchasePackage(offering.rcPackage);
         await _subscriptionService.fetchSubscriptionFromBackend();
         return true;
       } on PlatformException catch (e) {
         // Handle user cancellation vs real errors
         final errorCode = PurchasesErrorHelper.getErrorCode(e);
         if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
           errorMessage.value = 'Purchase failed. Please try again.';
         }
         return false;
       } finally {
         isPurchasing.value = false;
       }
     }

     Future<void> restorePurchases() async {
       isLoading.value = true;
       try {
         await _revenueCatService.restorePurchases();
         await _subscriptionService.fetchSubscriptionFromBackend();
       } catch (e) {
         errorMessage.value = 'Restore failed. Please try again.';
       } finally {
         isLoading.value = false;
       }
     }
   }
   ```

3. **SubscriptionBinding:**
   ```dart
   class SubscriptionBinding extends Bindings {
     @override
     void dependencies() {
       Get.lazyPut<SubscriptionController>(() => SubscriptionController());
       Get.lazyPut<PaywallController>(() => PaywallController());
     }
   }
   ```

4. **Verify:** `flutter analyze`

## Todo List
- [x] Create subscription-controller.dart
- [x] Create paywall-controller.dart
- [x] Create subscription-binding.dart
- [x] Run `flutter analyze` (0 errors, 0 warnings)

## Success Criteria
- Controllers correctly delegate to services
- Loading/error states properly managed
- Purchase flow handles cancellation gracefully
- Restore purchases works

## Next Steps
- Phase 6: Paywall UI
