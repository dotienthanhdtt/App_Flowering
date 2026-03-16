# Phase 3: RevenueCat Service

## Context Links
- [RC SDK Research](../reports/researcher-260313-revenuecat-flutter-sdk.md)
- [Brainstorm](../reports/brainstorm-260313-revenuecat-payment-feature.md) — SDK Reference section

## Overview
- **Priority:** Critical
- **Status:** Complete
- **Description:** Thin SDK wrapper service for RevenueCat. Handles init, logIn/logOut, purchase, restore, offerings, and CustomerInfo stream.

## Key Insights
- Service should be a thin wrapper — no business logic, just SDK calls
- Must handle platform-specific API keys
- `logIn(backendUserId)` links RC anonymous user to our backend user
- `logOut()` resets to anonymous user on sign-out
- CustomerInfo stream provides reactive updates

## Requirements
- SDK initialization with platform-specific keys
- User identification (logIn/logOut)
- Fetch offerings
- Purchase a package
- Restore purchases
- Expose CustomerInfo stream
- Proper error handling with typed exceptions

## Related Code Files

### Files to Create
- `lib/features/subscription/services/revenuecat-service.dart`

### Dependencies
- Phase 1: `purchases_flutter` installed, env config ready
- `lib/config/env_config.dart` — for API keys

## Implementation Steps

1. **Create RevenueCatService:**
   ```dart
   class RevenueCatService extends GetxService {
     bool _isConfigured = false;

     Future<RevenueCatService> init() async {
       try {
         await Purchases.setLogLevel(LogLevel.debug); // dev only
         final apiKey = Platform.isIOS
             ? EnvConfig.revenueCatAppleApiKey
             : EnvConfig.revenueCatGoogleApiKey;
         if (apiKey.isEmpty) return this;
         final config = PurchasesConfiguration(apiKey);
         await Purchases.configure(config);
         _isConfigured = true;
       } catch (e) {
         debugPrint('RevenueCat init failed: $e');
       }
       return this;
     }

     bool get isConfigured => _isConfigured;

     Future<LogInResult> logIn(String userId) async {
       return await Purchases.logIn(userId);
     }

     Future<CustomerInfo> logOut() async {
       return await Purchases.logOut();
     }

     Future<Offerings> getOfferings() async {
       return await Purchases.getOfferings();
     }

     Future<CustomerInfo> purchasePackage(Package package) async {
       final result = await Purchases.purchasePackage(package);
       return result.customerInfo;
     }

     Future<CustomerInfo> restorePurchases() async {
       return await Purchases.restorePurchases();
     }

     Future<CustomerInfo> getCustomerInfo() async {
       return await Purchases.getCustomerInfo();
     }

     Stream<CustomerInfo> get customerInfoStream =>
         Purchases.customerInfoStream;
   }
   ```

2. **Error handling:** Let PlatformException propagate — callers (SubscriptionService) handle errors.

3. **Verify:** `flutter analyze`

## Todo List
- [x] Create revenuecat-service.dart
- [x] Implement init with platform-specific keys
- [x] Implement logIn/logOut
- [x] Implement getOfferings
- [x] Implement purchasePackage
- [x] Implement restorePurchases
- [x] Implement getCustomerInfo
- [x] Expose customerInfoStream
- [x] Run `flutter analyze`

## Success Criteria
- Service initializes without crash even with empty API keys
- All SDK methods wrapped with consistent API
- Stream exposed for reactive CustomerInfo updates

## Risk Assessment
- **Empty API keys in dev:** Handled by `_isConfigured` guard
- **SDK exceptions:** Propagated to callers for proper UX handling

## Next Steps
- Phase 4: Subscription Service
