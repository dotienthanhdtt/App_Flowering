# Brainstorm: RevenueCat Payment Feature

**Date:** 2026-03-13
**Status:** Complete — summary only (no implementation plan requested)

## Problem Statement

Implement in-app subscriptions in Flutter app using RevenueCat SDK. Backend already has full RevenueCat integration (webhooks, subscription entity, plan management with FREE/MONTHLY/YEARLY/LIFETIME plans).

## Requirements

- **Plans**: Dynamic from RevenueCat offerings (match backend)
- **Paywall UX**: Dedicated screen in settings + bottom sheet modal when hitting feature gates
- **RevenueCat Dashboard**: Partially configured (products/offerings may need setup)
- **Feature Gates**: AI Chat sessions, Daily usage limits, Lesson content
- **State Management**: Hybrid — RevenueCat SDK local cache + backend API as source of truth
- **User ID**: Linked to backend user ID via `Purchases.logIn(backendUserId)`

## Architecture: Hybrid State Management

RevenueCat SDK handles purchase flow natively, caches entitlements locally for offline. Backend remains source of truth via webhooks + `GET /subscriptions/me`.

```
Flutter App
├── RevenueCatService (SDK init, configure, logIn/logOut, raw purchase calls)
├── SubscriptionService (orchestrates RC + backend, caches state, exposes isSubscribed/currentPlan)
├── SubscriptionController (GetX reactive UI state)
├── PaywallController (offerings display, purchase flow, loading states)
└── SubscriptionGate (utility for feature gating in other controllers)
```

## New Files (feature-first pattern)

```
lib/features/subscription/
├── bindings/subscription_binding.dart
├── controllers/subscription_controller.dart
├── controllers/paywall_controller.dart
├── services/revenuecat_service.dart
├── services/subscription_service.dart
├── models/subscription_model.dart
├── models/offering_model.dart
├── views/paywall_screen.dart
├── widgets/paywall_bottom_sheet.dart
├── widgets/plan_card_widget.dart
├── widgets/subscription_status_widget.dart
└── utils/subscription_gate.dart
```

## Files to Modify

- `pubspec.yaml` — add `purchases_flutter`
- `global-dependency-injection-bindings.dart` — register subscription services
- `api_endpoints.dart` — add subscription endpoints
- `env_config.dart` — add RevenueCat API keys
- Feature controllers (chat, lessons) — add gate checks
- `AndroidManifest.xml` — BILLING permission
- `MainActivity.kt` — FlutterFragmentActivity
- `ios/Podfile` — minimum iOS 13+

## Key Flows

### App Startup
1. `main.dart` → init RevenueCat SDK with platform API key
2. After user auth → `Purchases.logIn(backendUserId)` to link
3. Fetch `CustomerInfo` → cache entitlements locally
4. Sync with `GET /subscriptions/me` for backend validation

### Purchase
1. User hits gated feature → show paywall (screen or bottom sheet)
2. Fetch offerings from RevenueCat → display dynamic plans
3. User selects plan → `Purchases.purchase(params)`
4. On success → SDK updates `CustomerInfo` locally
5. Backend receives webhook → updates subscription entity
6. App syncs on next `getCustomerInfo()` call

### Feature Gating
```dart
if (!subscriptionService.hasActiveSubscription) {
  PaywallBottomSheet.show();
  return;
}
```

## RevenueCat SDK Reference

### Installation
```yaml
dependencies:
  purchases_flutter: <latest>
```

### Configuration
```dart
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io' show Platform;

await Purchases.setLogLevel(LogLevel.debug);
late PurchasesConfiguration configuration;
if (Platform.isAndroid) {
  configuration = PurchasesConfiguration(<google_api_key>);
} else if (Platform.isIOS) {
  configuration = PurchasesConfiguration(<apple_api_key>);
}
await Purchases.configure(configuration);
```

### Fetch Offerings
```dart
Offerings offerings = await Purchases.getOfferings();
if (offerings.current != null && offerings.current.availablePackages.isNotEmpty) {
  // Display packages
}
```

### Make Purchase
```dart
final purchaseParams = PurchaseParams.package(package);
PurchaseResult result = await Purchases.purchase(purchaseParams);
if (result.customerInfo.entitlements.all["entitlement_id"]?.isActive ?? false) {
  // Unlock premium
}
```

### Check Entitlements
```dart
CustomerInfo customerInfo = await Purchases.getCustomerInfo();
if (customerInfo.entitlements.all["entitlement_id"].isActive) {
  // Premium active
}
```

### Restore Purchases
```dart
CustomerInfo customerInfo = await Purchases.restorePurchases();
```

## Platform Setup

### Android
- `AndroidManifest.xml`: `<uses-permission android:name="com.android.vending.BILLING" />`
- `MainActivity.kt`: extend `FlutterFragmentActivity` instead of `FlutterActivity`

### iOS
- Enable "In-App Purchase" capability in Xcode
- `Podfile`: minimum `platform :ios, '13.0'`

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| RC SDK + backend state out of sync | Hybrid: local cache for UX, periodic backend sync for truth |
| Purchase fails silently | Proper error handling with PurchasesErrorHelper, retry UI |
| Sandbox testing complexity | Use RC sandbox mode, document test account setup |
| iOS review rejection | Restore purchases button mandatory, proper subscription terms |

## Success Criteria

- Users can view dynamic offerings from RevenueCat
- Purchase flow works on both iOS and Android
- Subscription state persists across app restarts (Hive cache)
- Feature gates block AI chat, lessons, and daily limits for free users
- Backend webhook keeps server-side subscription state in sync
- Restore purchases works correctly
