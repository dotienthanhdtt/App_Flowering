# Phase 7: Feature Gating Integration

## Context Links
- [Brainstorm](../reports/brainstorm-260313-revenuecat-payment-feature.md) — Feature Gates section

## Overview
- **Priority:** High
- **Status:** Pending
- **Description:** Create SubscriptionGate utility and integrate into existing feature controllers (chat, lessons). Add service registration to DI.

## Requirements
- SubscriptionGate utility for consistent gate checks
- Gate AI Chat sessions
- Gate daily usage limits
- Gate lesson content
- Register all subscription services in global DI
- Initialize services in correct order in main.dart

## Related Code Files

### Files to Create
- `lib/features/subscription/utils/subscription-gate.dart`

### Files to Modify
- `lib/app/global-dependency-injection-bindings.dart` — register services
- `lib/main.dart` — initialize RevenueCatService + SubscriptionService
- `lib/features/*/controllers/*.dart` — add gate checks where needed (chat, lessons)

### Dependencies
- Phase 4: SubscriptionService
- Phase 6: PaywallBottomSheet

## Implementation Steps

1. **Create SubscriptionGate:**
   ```dart
   class SubscriptionGate {
     static bool get isPremium =>
         Get.find<SubscriptionService>().isPremium;

     /// Check access and show paywall if not premium.
     /// Returns true if access granted.
     static Future<bool> checkAccess() async {
       if (isPremium) return true;
       await PaywallBottomSheet.show();
       // Re-check after paywall dismissed (user may have purchased)
       return isPremium;
     }

     /// Use in controllers before gated actions
     static Future<void> guardAction(Future<void> Function() action) async {
       if (await checkAccess()) {
         await action();
       }
     }
   }
   ```

2. **Register services in global DI:**
   ```dart
   // global-dependency-injection-bindings.dart
   Get.lazyPut<RevenueCatService>(() => RevenueCatService(), fenix: true);
   Get.lazyPut<SubscriptionService>(() => SubscriptionService(), fenix: true);
   ```

3. **Initialize in main.dart** (after AuthStorage, before ApiClient or after):
   ```dart
   // In initializeServices()
   await Get.find<RevenueCatService>().init();
   await Get.find<SubscriptionService>().init();
   ```

4. **Hook into auth flow:**
   - After successful login: call `SubscriptionService.onUserLoggedIn()`
   - On logout: call `SubscriptionService.onUserLoggedOut()`
   - Find the auth controller/service that handles login/logout and add these calls

5. **Add gates to feature controllers:**
   ```dart
   // Example: ChatController
   Future<void> sendMessage() async {
     if (!await SubscriptionGate.checkAccess()) return;
     // ... existing send message logic
   }
   ```

6. **Verify:** `flutter analyze`

## Todo List
- [ ] Create subscription-gate.dart
- [ ] Register RevenueCatService in global DI
- [ ] Register SubscriptionService in global DI
- [ ] Initialize services in main.dart
- [ ] Hook onUserLoggedIn/onUserLoggedOut into auth flow
- [ ] Add gate checks to chat controller
- [ ] Add gate checks to lesson controller
- [ ] Run `flutter analyze`
- [ ] Test complete flow: login → fetch subscription → gate check → paywall → purchase

## Success Criteria
- Free users see paywall when hitting gated features
- Premium users pass gates seamlessly
- Services properly initialized on app startup
- Auth lifecycle properly hooked (logIn/logOut)
- No circular dependencies

## Risk Assessment
- **Circular dependency:** SubscriptionGate imports PaywallBottomSheet — ensure no reverse import
- **Init order:** RevenueCatService must init before SubscriptionService

## Security Considerations
- Feature gates are client-side UX only — backend enforces actual limits
- Never trust client-side subscription state for sensitive operations

## Next Steps
- Testing and QA
- RevenueCat sandbox testing
- App Store / Play Store review preparation
