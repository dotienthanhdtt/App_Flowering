# RevenueCat iOS Setup Checklist

## 1. pubspec.yaml
- [x] `purchases_flutter` is listed under dependencies — `purchases_flutter: ^8.0.0`
- [x] Version is up to date (latest stable)

## 2. Bundle ID
- [x] `ios/Runner.xcodeproj/project.pbxproj` contains `com.flowering.app` (not `com.example.flowering`)
- [x] `android/app/build.gradle` applicationId matches — ✅ Fixed to `com.flowering.app`

## 3. iOS Capabilities
- [x] `ios/Runner/Runner.entitlements` exists with In-App Purchase capability — ✅ Created
- [x] `CODE_SIGN_ENTITLEMENTS` added to all build configs (Debug, Release, Profile) in `project.pbxproj`

## 4. RevenueCat Initialization
- [x] `Purchases.configure()` is called at app startup — `lib/features/subscription/services/revenuecat-service.dart:27-28`
- [x] API key used is the **iOS** public API key from RevenueCat dashboard (loaded via env config)
- [x] `appUserID` is set correctly (or null for anonymous)

## 5. Product IDs match App Store Connect
- [x] `com.flowering.app.premium.monthly` — defined in `ios/Products.storekit:63`
- [x] `com.flowering.app.premium.yearly` — defined in `ios/Products.storekit:147`
- [x] `com.flowering.app.premiumplus.monthly` — defined in `ios/Products.storekit:91`
- [x] `com.flowering.app.premiumplus.yearly` — defined in `ios/Products.storekit:119`

## 6. Entitlement identifiers match RevenueCat dashboard
- [x] `premium` — used in `subscription-service.dart:86`
- [x] `premium_plus` — used in `subscription-service.dart:87`

## 7. Offerings fetch
- [x] App fetches offerings using `Purchases.getOfferings()` — `revenuecat-service.dart:59-61`
- [x] Handles null/empty offerings gracefully — `paywall-controller.dart:28`
- [x] Uses offering identifier `default`

## 8. Purchase flow
- [x] `Purchases.purchasePackage(package)` is implemented — `revenuecat-service.dart:64-66`
- [x] Success case: updates UI based on entitlement — `paywall-controller.dart`
- [x] Error case: handles `PurchasesErrorCode.purchaseCancelledError` — `paywall-controller.dart:49-50`

## 9. Restore purchases
- [x] `Purchases.restorePurchases()` is implemented and accessible to user — `revenuecat-service.dart:69-71`, UI in `paywall-bottom-sheet.dart`

## 10. Entitlement check
- [x] App checks `customerInfo.entitlements.active` to unlock features — `subscription-service.dart:85-87`
- [x] Checks both `premium` and `premium_plus` entitlements separately

## 11. iOS Deployment Target
- [x] Minimum iOS version is 13.0 or higher — `Podfile:1` and `project.pbxproj`

## 12. StoreKit Testing (optional but recommended)
- [x] `ios/Products.storekit` exists for local testing (4 products configured)
- [ ] RevenueCat sandbox environment testing — Not yet confirmed

---

## Summary: 24/25 items complete ✅

### Remaining (1 item)
1. **RevenueCat sandbox testing** — Not yet confirmed
