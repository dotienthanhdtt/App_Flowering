---
name: RevenueCat Flutter SDK Research Report
description: Comprehensive analysis of purchases_flutter SDK versions, APIs, initialization, user management, offerings, purchases, entitlements, and platform-specific setup
type: reference
---

# RevenueCat Flutter SDK (purchases_flutter) Research Report

**Date:** March 13, 2026
**Focus:** Flutter/Dart implementation of RevenueCat subscription management
**Report Type:** Technical Research

---

## 1. Latest Version & Installation

### Current Stable Version
- **Latest:** `purchases_flutter: ^7.x.x` (as of Feb 2025)
- **Dart SDK:** `^3.0.0` minimum
- **Flutter SDK:** `^3.13.0` minimum

### Installation Steps

**1. Add to pubspec.yaml:**
```yaml
dependencies:
  purchases_flutter: ^7.x.x
```

**2. Run:**
```bash
flutter pub get
```

**3. Platform-specific setup required (see Section 10)**

### Pub.dev Information
- Package: `purchases_flutter`
- Publisher: RevenueCat
- Active development, regularly updated
- Well-documented with examples

---

## 2. SDK Initialization & Configuration

### Basic Initialization Pattern

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Purchases SDK
  await Purchases.setup(
    'your_revenuecat_api_key',
    appUserID: null, // null = anonymous, or provide user ID
  );

  runApp(const MyApp());
}
```

### Configuration Best Practices

**1. API Key Management:**
- Store API key in environment config, NOT hardcoded
- Use different keys for dev/prod environments
- Never commit keys to version control

**2. Initialization Timing:**
- Call `Purchases.setup()` in `main()` before `runApp()`
- Must be called on app launch
- Single initialization point (idempotent)

**3. Optional Initialization Parameters:**
```dart
await Purchases.setup(
  apiKey,
  appUserID: userId, // Optional: set after login
  observerMode: false, // Set true for observer-only mode
  // observerMode = SDK doesn't make purchases, just observes native purchases
);
```

**4. Advanced Configuration (if needed):**
```dart
// Set log level for debugging
await Purchases.setLogLevel(LogLevel.debug);

// Configure proxy URL (enterprise feature)
await Purchases.setProxyURL('https://your-proxy.com');

// Enable/disable automatic sync
// (automatic by default)
```

**5. Service Initialization in GetX:**
```dart
// core/services/subscription_service.dart
class SubscriptionService extends GetxService {
  late Purchases _purchases;

  Future<SubscriptionService> init() async {
    try {
      _purchases = Purchases.instance;

      await _purchases.setup(
        'YOUR_API_KEY',
        appUserID: null,
      );

      // Listen to customer info updates
      _setupListeners();

      return this;
    } catch (e) {
      print('Subscription service init error: $e');
      rethrow;
    }
  }

  void _setupListeners() {
    // Listen to purchases
    Purchases.instance.purchaseUpdatedStream.listen(
      (purchases) => _handlePurchaseUpdate(purchases),
      onError: (error) => _handlePurchaseError(error),
    );
  }

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }
}
```

---

## 3. User Identification (logIn/logOut)

### Login Flow

**Anonymous User (Initial):**
```dart
// Initialize without appUserID
await Purchases.setup('api_key', appUserID: null);
```

**After User Authentication:**
```dart
// Call logIn() when user logs in
try {
  final customerInfo = await Purchases.logIn('user_id_from_backend');
  print('Customer logged in: ${customerInfo.originalAppUserId}');
} on PurchasesErrorCode catch (e) {
  print('Error logging in: ${e.code} - ${e.message}');
}
```

### Logout Flow

```dart
// Call logOut() on user logout
try {
  await Purchases.logOut();
  print('User logged out, anonymous mode enabled');
} on PurchasesErrorCode catch (e) {
  print('Error logging out: ${e.code} - ${e.message}');
}
```

### Key Points

- `logIn()` identifies user across devices
- `logOut()` reverts to anonymous mode
- Both are idempotent (safe to call multiple times)
- Returns updated `CustomerInfo` on successful login
- Automatically syncs purchase history

### Implementation Pattern

```dart
class AuthController extends GetxController {
  final _subscriptionService = Get.find<SubscriptionService>();

  Future<void> loginUser(String userId) async {
    try {
      await _subscriptionService.logIn(userId);
      // Update local user state
    } on PurchasesErrorCode catch (e) {
      _handleSubscriptionError(e);
    }
  }

  Future<void> logoutUser() async {
    try {
      await _subscriptionService.logOut();
      // Clear subscription state
    } on PurchasesErrorCode catch (e) {
      _handleSubscriptionError(e);
    }
  }
}
```

---

## 4. Fetching Offerings & Packages

### Data Model Structure

```dart
// RevenueCat's object hierarchy:
Offerings (all offers)
  └─ Offering (promotion/tier)
      └─ Package[] (product SKUs)
          └─ Product (detail: price, duration)
```

### Fetching Offerings

```dart
Future<void> loadOfferings() async {
  try {
    final offerings = await Purchases.getOfferings();

    if (offerings.current != null) {
      // Current offering (usually default)
      final currentOffering = offerings.current!;

      print('Offering ID: ${currentOffering.identifier}');
      print('Packages: ${currentOffering.availablePackages.length}');

      for (final package in currentOffering.availablePackages) {
        print('Package: ${package.identifier}');
        print('Price: ${package.storeProduct.price}');
      }
    }

    // Access all offerings by ID
    final allOfferings = offerings.all;
    for (final offering in allOfferings.values) {
      print('Offering: ${offering.identifier}');
    }
  } on PurchasesErrorCode catch (e) {
    print('Error fetching offerings: ${e.code}');
  }
}
```

### Available Package Types

RevenueCat provides predefined package types:

```dart
enum PackageType {
  unknown,
  custom,
  lifetime,
  annual,
  sixMonth,
  threeMonth,
  twoMonth,
  monthly,
  weekly,
}

// Example usage:
final package = offering.availablePackages
  .firstWhere((p) => p.packageType == PackageType.monthly);
```

### Caching Strategy

RevenueCat caches offerings with automatic refresh:

```dart
// First call fetches from server
final offerings1 = await Purchases.getOfferings();

// Subsequent calls return cached value (within cache period)
final offerings2 = await Purchases.getOfferings();

// Force refresh from server
await Purchases.invalidateCustomerInfoCache();
final offerings3 = await Purchases.getOfferings();
```

### Implementation in Service

```dart
class SubscriptionService extends GetxService {
  final offerings = Rx<Offerings?>(null);
  final isLoadingOfferings = false.obs;

  Future<void> loadOfferings() async {
    isLoadingOfferings.value = true;
    try {
      final result = await Purchases.getOfferings();
      offerings.value = result;
    } on PurchasesErrorCode catch (e) {
      _handleError(e);
    } finally {
      isLoadingOfferings.value = false;
    }
  }

  Package? getMonthlyPackage() {
    final currentOffering = offerings.value?.current;
    return currentOffering?.availablePackages
      .firstWhere(
        (p) => p.packageType == PackageType.monthly,
        orElse: () => currentOffering!.availablePackages.first,
      );
  }
}
```

---

## 5. Making Purchases (PurchaseParams, PurchaseResult)

### Purchase Flow

```dart
Future<void> purchasePackage(Package package) async {
  try {
    // Initiate purchase
    final purchaseResult = await Purchases.purchasePackage(package);

    // Check if successful
    if (purchaseResult.customerInfo.entitlements.active.isNotEmpty) {
      print('Purchase successful!');
      print('Active entitlements: ${purchaseResult.customerInfo.entitlements.active.keys}');
    }

    return purchaseResult;
  } on PurchasesErrorCode catch (e) {
    if (e.code == PurchasesErrorCode.purchaseCancelledError) {
      print('User cancelled purchase');
    } else if (e.code == PurchasesErrorCode.purchaseInvalidError) {
      print('Invalid purchase');
    } else {
      print('Purchase failed: ${e.message}');
    }
    rethrow;
  }
}
```

### PurchaseResult Structure

```dart
class PurchaseResult {
  final CustomerInfo customerInfo;        // Updated customer info after purchase
  final bool userCancelled;               // true if user cancelled

  // Direct properties
  List<EntitlementInfo> get activeEntitlements =>
    customerInfo.entitlements.active.values.toList();
}
```

### Advanced: Purchase with User Properties

```dart
// Available for SDK v7+
Future<void> purchasePackageWithData(
  Package package,
  Map<String, String> purchaseAppUserIdOverride,
) async {
  try {
    final result = await Purchases.purchasePackage(
      package,
      googlePlayProrationMode: null, // Android specific
      appUserId: null, // Can override user ID
    );

    return result;
  } on PurchasesErrorCode catch (e) {
    _handleError(e);
  }
}
```

### Common Purchase Errors

```dart
enum PurchasesErrorCode {
  purchaseCancelledError,           // User cancelled
  storeProblemError,                // App Store/Play Store issue
  purchaseInvalidError,             // Invalid purchase
  purchaseNotAllowedError,          // Not allowed (parental controls, etc)
  productNotAvailableForPurchaseError,
  networkError,
  unknownError,
  // ... more codes
}

// Usage in error handling
on PurchasesErrorCode catch (e) {
  switch (e.code) {
    case PurchasesErrorCode.purchaseCancelledError:
      print('Cancelled');
      break;
    case PurchasesErrorCode.networkError:
      print('Network error');
      break;
    default:
      print('Other error: ${e.message}');
  }
}
```

---

## 6. Checking Entitlements (CustomerInfo)

### CustomerInfo Structure

```dart
class CustomerInfo {
  // User identification
  String? originalAppUserId;        // The user ID
  String? managementURL;             // Manage subscription URL

  // Entitlements (your custom identifiers)
  EntitlementInfos entitlements;    // All entitlements (active/expired)

  // Subscription details
  Map<String, SubscriptionInfo> subscriptions;

  // Non-subscription purchases
  Map<String, NonSubscriptionTransactionInfo> nonSubscriptions;

  // Metadata
  DateTime requestDate;
  bool isLegacyUser;

  // Computed properties
  Map<String, EntitlementInfo> get activeEntitlements =>
    entitlements.active;  // Only active (non-expired)
}
```

### Checking Entitlements

```dart
// Get current customer info
Future<void> checkEntitlements() async {
  try {
    final customerInfo = await Purchases.getCustomerInfo();

    // Check if user has premium entitlement
    if (customerInfo.entitlements.active.containsKey('premium')) {
      final premiumEntitlement = customerInfo.entitlements.active['premium']!;
      print('User is premium');
      print('Expires: ${premiumEntitlement.expirationDate}');
    } else {
      print('User is not premium');
    }

    // List all active entitlements
    for (final (key, entitlement) in customerInfo.entitlements.active.entries) {
      print('Active: $key - Expires: ${entitlement.expirationDate}');
    }

    // Check subscription info
    final subscription = customerInfo.subscriptions['monthly_subscription'];
    if (subscription != null) {
      print('Subscription product: ${subscription.productIdentifier}');
      print('Purchase date: ${subscription.purchaseDate}');
      print('Renewal date: ${subscription.expirationDate}');
      print('Is active: ${subscription.isActive}');
    }

  } on PurchasesErrorCode catch (e) {
    print('Error checking entitlements: ${e.message}');
  }
}
```

### EntitlementInfo Details

```dart
class EntitlementInfo {
  String identifier;                  // Your entitlement ID (e.g., 'premium')
  bool isActive;                      // Still valid?
  DateTime? expirationDate;           // When it expires
  DateTime? latestPurchaseDate;       // Most recent purchase
  bool isSandbox;                     // Test environment?
  String? verificationResult;         // Verification status
}
```

### Implementation Pattern

```dart
class SubscriptionService extends GetxService {
  final customerInfo = Rx<CustomerInfo?>(null);
  final isPremium = false.obs;
  final premiumExpiresAt = Rx<DateTime?>(null);

  Future<void> updateCustomerInfo() async {
    try {
      final info = await Purchases.getCustomerInfo();
      customerInfo.value = info;

      // Check entitlements
      final hasActive = info.entitlements.active.containsKey('premium');
      isPremium.value = hasActive;

      if (hasActive) {
        premiumExpiresAt.value =
          info.entitlements.active['premium']?.expirationDate;
      }
    } on PurchasesErrorCode catch (e) {
      _handleError(e);
    }
  }

  bool isPremiumActive() => customerInfo.value?.entitlements
    .active.containsKey('premium') ?? false;

  DateTime? getPremiumExpirationDate() => customerInfo.value?.entitlements
    .active['premium']?.expirationDate;
}
```

---

## 7. Restoring Purchases

### Restore Flow

```dart
Future<void> restorePurchases() async {
  try {
    final customerInfo = await Purchases.restorePurchases();

    print('Purchases restored');
    print('Active entitlements: ${customerInfo.entitlements.active.keys}');

    // Update UI with restored state
    return customerInfo;

  } on PurchasesErrorCode catch (e) {
    if (e.code == PurchasesErrorCode.networkError) {
      print('Network error - check connection');
    } else {
      print('Restore failed: ${e.message}');
    }
    rethrow;
  }
}
```

### When to Call Restore

**Typical UX patterns:**
1. New device/app installation
2. User clicks "Restore Purchases" button
3. After failed purchase attempt (recovery)
4. Offline user comes back online

### Implementation

```dart
class SubscriptionController extends GetxController {
  final _subscriptionService = Get.find<SubscriptionService>();

  final isRestoring = false.obs;

  Future<void> restorePurchases() async {
    isRestoring.value = true;
    try {
      final result = await _subscriptionService.restorePurchases();

      if (result.entitlements.active.isNotEmpty) {
        Get.snackbar('Success', 'Purchases restored');
      } else {
        Get.snackbar('No purchases', 'Nothing to restore');
      }

    } on PurchasesErrorCode catch (e) {
      Get.snackbar('Error', e.message ?? 'Restore failed');
    } finally {
      isRestoring.value = false;
    }
  }
}
```

---

## 8. Listening to CustomerInfo Updates (Stream/Listener)

### CustomerInfo Update Stream

RevenueCat provides a stream of customer info updates:

```dart
// Listen to customer info updates
Purchases.instance.customerInfoStream.listen(
  (customerInfo) {
    print('Customer info updated');
    print('Active entitlements: ${customerInfo.entitlements.active.keys}');

    // Update reactive state
    // e.g., controller.isPremium.value = ...
  },
  onError: (error) {
    print('Error in customer info stream: $error');
  },
);
```

### Purchase Updates Stream

For real-time purchase state changes (user purchases in another app, etc):

```dart
// Listen to purchase updates
Purchases.instance.purchaseUpdatedStream.listen(
  (purchases) {
    print('Purchases updated: ${purchases.length} new purchases');
    for (final purchase in purchases) {
      print('Product: ${purchase.productIdentifier}');
      print('ID: ${purchase.transactionIdentifier}');
    }
  },
  onError: (error) {
    print('Error in purchase stream: $error');
  },
);
```

### Service Implementation with Streams

```dart
class SubscriptionService extends GetxService {
  late StreamSubscription _customerInfoSubscription;
  late StreamSubscription _purchaseSubscription;

  final customerInfo = Rx<CustomerInfo?>(null);
  final isPremium = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupStreams();
  }

  void _setupStreams() {
    // Listen to customer info changes
    _customerInfoSubscription = Purchases.instance.customerInfoStream
      .listen(
        (info) {
          customerInfo.value = info;
          _updatePremiumStatus(info);
        },
        onError: (error) => print('CustomerInfo stream error: $error'),
      );

    // Listen to purchase updates
    _purchaseSubscription = Purchases.instance.purchaseUpdatedStream
      .listen(
        (purchases) => _handlePurchaseUpdate(purchases),
        onError: (error) => print('Purchase stream error: $error'),
      );
  }

  void _updatePremiumStatus(CustomerInfo info) {
    isPremium.value = info.entitlements.active.containsKey('premium');
  }

  void _handlePurchaseUpdate(List<StoreTransaction> purchases) {
    for (final purchase in purchases) {
      print('Purchase: ${purchase.productIdentifier}');
      // Handle purchase logic
    }
  }

  @override
  void onClose() {
    _customerInfoSubscription.cancel();
    _purchaseSubscription.cancel();
    super.onClose();
  }
}
```

### Reactive Updates in Controllers

```dart
class PaywallController extends GetxController {
  final _subscriptionService = Get.find<SubscriptionService>();

  @override
  void onInit() {
    super.onInit();

    // React to entitlement changes
    ever(_subscriptionService.isPremium, (isPremium) {
      if (isPremium) {
        Get.offNamed('/home');  // Redirect after purchase
      }
    });
  }

  Widget buildContent() {
    return Obx(() =>
      _subscriptionService.isPremium.value
        ? PremiumContent()
        : PaywallWidget()
    );
  }
}
```

---

## 9. Error Handling Patterns

### Error Codes Hierarchy

```dart
abstract class PurchasesError {
  String get code;
  String get message;
  String? get underlyingErrorMessage;
}

// Specific error enum
enum PurchasesErrorCode {
  // Purchase errors
  purchaseCancelledError,
  storeProblemError,
  purchaseInvalidError,
  purchaseNotAllowedError,
  productNotAvailableForPurchaseError,

  // Network/connection errors
  networkError,

  // Service configuration errors
  unrecognizedCustomerError,
  invalidCredentialsError,
  configurationError,

  // Common SDK errors
  unknownError,
  invalidAppleSubscriptionKeyError,
  invalidGooglePlayAPIKeyError,
}
```

### Comprehensive Error Handling

```dart
Future<void> purchaseWithErrorHandling(Package package) async {
  try {
    final result = await Purchases.purchasePackage(package);
    print('Purchase successful');
    return result;

  } on PurchasesErrorCode catch (e) {
    switch (e.code) {
      // User actions
      case PurchasesErrorCode.purchaseCancelledError:
        print('User cancelled');
        rethrow; // Don't show error, user intended

      // Network issues
      case PurchasesErrorCode.networkError:
        print('Network error');
        showSnackbar('Check your internet connection');

      // Store problems
      case PurchasesErrorCode.storeProblemError:
        print('Store problem: ${e.message}');
        showSnackbar('App Store problem. Try again later.');

      // Invalid data
      case PurchasesErrorCode.purchaseInvalidError:
        print('Invalid purchase');
        showSnackbar('Invalid purchase. Try again.');

      // Not allowed (parental controls, etc)
      case PurchasesErrorCode.purchaseNotAllowedError:
        print('Purchase not allowed');
        showSnackbar('Purchases are not allowed on this device');

      // Config errors (usually at init time)
      case PurchasesErrorCode.configurationError:
        print('SDK configuration error: ${e.message}');
        showSnackbar('App configuration error. Contact support.');

      // Unknown
      default:
        print('Unknown error: ${e.code} - ${e.message}');
        showSnackbar('An error occurred. Please try again.');
    }

    rethrow;

  } on Exception catch (e) {
    print('Unexpected error: $e');
    showSnackbar('Unexpected error. Please try again.');
    rethrow;
  }
}
```

### Error Recovery Strategies

```dart
class SubscriptionService extends GetxService {
  // Retry logic for transient errors
  Future<CustomerInfo?> getCustomerInfoWithRetry({
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await Purchases.getCustomerInfo();
      } on PurchasesErrorCode catch (e) {
        attempt++;

        // Don't retry for non-transient errors
        if (e.code != PurchasesErrorCode.networkError &&
            e.code != PurchasesErrorCode.unknownError) {
          rethrow;
        }

        if (attempt >= maxRetries) rethrow;

        await Future.delayed(delay * attempt);
      }
    }

    return null;
  }

  // Fallback to cached data if network fails
  Future<CustomerInfo> getCustomerInfoSafe() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _cachedCustomerInfo = info; // Cache it
      return info;
    } on PurchasesErrorCode catch (e) {
      if (_cachedCustomerInfo != null) {
        print('Using cached customer info due to: ${e.message}');
        return _cachedCustomerInfo!;
      }
      rethrow;
    }
  }
}
```

---

## 10. Platform-Specific Setup

### Android Setup

**1. Gradle Configuration:**

```gradle
// android/app/build.gradle
android {
  compileSdkVersion 34  // Or latest

  defaultConfig {
    applicationId "com.example.flowering"
    minSdkVersion 21    // RevenueCat requires 21+
    targetSdkVersion 34
  }
}

dependencies {
  // RevenueCat dependencies (auto-managed by plugin)
  implementation 'com.revenuecat.purchases:purchases:7.x.x'
}
```

**2. AndroidManifest.xml Permissions:**

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest ...>
  <!-- CRITICAL: BILLING permission for In-App Purchases -->
  <uses-permission android:name="com.android.vending.BILLING" />

  <!-- Optional: For better user identification -->
  <uses-permission android:name="android.permission.INTERNET" />

  <application ...>
    <!-- Use FlutterFragmentActivity if using plugins that require FragmentActivity -->
    <activity
      android:name=".MainActivity"
      android:exported="true"
      android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
      android:hardwareAccelerated="true"
      android:windowSoftInputMode="adjustResize">
      ...
    </activity>
  </application>
</manifest>
```

**3. FlutterFragmentActivity (if needed):**

```kotlin
// android/app/src/main/kotlin/com/example/MainActivity.kt
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
  // No additional code needed
  // Just extending FlutterFragmentActivity instead of FlutterActivity
}
```

**4. Google Play Setup:**
- Add product SKUs in Google Play Console
- Configure in-app products (subscription or non-recurring)
- Publishing status: Published or Draft (both work for testing)

**5. Service Account Configuration:**
- Create service account in Google Cloud Console
- Grant `monetization.subscriptionsAndroid` role
- Download JSON key
- Configure in RevenueCat dashboard

### iOS Setup

**1. CocoaPods Configuration:**

```ruby
# ios/Podfile
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # RevenueCat specific (usually auto-configured)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'FIREBASE_ANALYTICS_ENABLED=1',
      ]
    end
  end
end
```

**2. Xcode Project Configuration:**

**Capabilities (Xcode GUI):**
- ✅ In-App Purchase (CRITICAL)
- ✅ App Groups (if using multiple apps/extensions)

**Info.plist:**
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app requires network access for subscriptions</string>

<key>NSBonjourServices</key>
<array>
  <string>_http._tcp</string>
</array>
```

**3. StoreKit Configuration:**
- Create `.storekit` file in Xcode for testing
- Configure test products matching Android SKUs
- Use in Simulator with `xcrun simctl openurl booted "itms://apps.apple.com/..."`

**4. App Store Connect Setup:**
- Create product IDs (subscriptions)
- Configure pricing and availability
- Set up test users for testing
- Create signing certificates and provisioning profiles

**5. Entitlements File:**

```xml
<!-- ios/Runner/Runner.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.developer.in-app-payments</key>
  <true/>
  <!-- Add others as needed -->
</dict>
</plist>
```

### Cross-Platform Considerations

```dart
// Check platform-specific features
import 'dart:io';

final isAndroid = Platform.isAndroid;
final isIOS = Platform.isIOS;

// Store-specific product IDs might differ
String getProductId(String baseId) {
  if (isAndroid) {
    return '${baseId}_android';
  } else if (isIOS) {
    return '${baseId}_ios';
  }
  return baseId;
}
```

---

## 11. Breaking Changes & Migration Notes

### Recent Major Versions

#### v7.x → v8.x (if released)
- Check migration guide in official docs
- May involve CustomerInfo structure changes
- Test thoroughly before upgrading

#### v6.x → v7.x (Recent)
- Null safety improvements
- Better error types (moved to enums)
- Stream-based architecture (recommended)
- Observer mode improvements

### Migration Pattern

```dart
// Old (v6)
// try-catch with generic Exception

// New (v7+)
try {
  // ...
} on PurchasesErrorCode catch (e) {
  // Specific error handling
}
```

### Compatibility Notes

- **Minimum iOS:** 11.0+ (older versions require iOS 9+)
- **Minimum Android:** API 21+ (5.0+)
- **Dart:** 3.0.0+
- **Flutter:** 3.13.0+

### Pre-v7 Upgrade Checklist

If upgrading from v6:
- [ ] Update error handling to use `PurchasesErrorCode`
- [ ] Migrate to stream-based updates if using observers
- [ ] Test on both platforms
- [ ] Update platform-specific code (Android/iOS)
- [ ] Re-test credentials and API keys

---

## Implementation Checklist

### Phase 1: Setup
- [ ] Add `purchases_flutter: ^7.x.x` to pubspec.yaml
- [ ] Android: Add BILLING permission, minSdkVersion 21+
- [ ] iOS: Enable In-App Purchase capability
- [ ] Create RevenueCat account, get API key
- [ ] Create SubscriptionService in core/services/
- [ ] Register in global bindings

### Phase 2: Initialization
- [ ] Call `Purchases.setup()` in main.dart
- [ ] Implement `SubscriptionService.init()`
- [ ] Test basic initialization (verify API key works)

### Phase 3: Core Features
- [ ] Implement offering/package fetching
- [ ] Add user login/logout with RevenueCat
- [ ] Implement purchase flow
- [ ] Add entitlement checking
- [ ] Test on both platforms

### Phase 4: Advanced
- [ ] Stream listeners (CustomerInfo, purchases)
- [ ] Restore purchases functionality
- [ ] Error handling & recovery
- [ ] Offline handling (cache customer info)

### Phase 5: Testing & Security
- [ ] Test with sandbox/test credentials
- [ ] Verify no API keys in code
- [ ] Test all error scenarios
- [ ] Production credentials ready

---

## Key Integration Points for Flowering App

### 1. AuthController
```
loginUser() → call Purchases.logIn(userId)
logoutUser() → call Purchases.logOut()
```

### 2. ProfileController
```
checkPremiumStatus() → SubscriptionService.isPremium
showPremiumExpiryDate() → SubscriptionService.premiumExpiresAt
```

### 3. PaywallScreen/Controller
```
loadOfferings() → display packages
purchasePackage() → initiate purchase
restorePurchases() → offer recovery option
```

### 4. HomeController/Screen
```
Display premium badge if isPremium.value
Show paywall if not premium and needed
```

### 5. Global Navigation
```
Setup stream listeners for entitlement changes
Redirect to paywall if entitlement lost
```

---

## Important Security Notes

**NEVER:**
- Hardcode API keys in code
- Log sensitive entitlement data
- Use test credentials in production
- Skip validation of entitlements

**ALWAYS:**
- Use environment config for API keys
- Validate entitlements on backend if critical
- Test with sandbox credentials
- Use secure token storage for user IDs

---

## Testing Strategy

### Unit Testing
```dart
// Mock Purchases
class MockPurchases extends Mock implements Purchases {
  @override
  Future<void> setup(String apiKey, {String? appUserID}) async {}

  @override
  Future<CustomerInfo> getCustomerInfo() async =>
    _mockCustomerInfo();
}

// Test SubscriptionService
void main() {
  test('isPremium updates on login', () async {
    Get.put<Purchases>(MockPurchases());
    // ...
  });
}
```

### Integration Testing
- Use TestFlight (iOS) or Beta channel (Android)
- Test with real sandbox credentials
- Verify purchase flows end-to-end
- Test restore functionality

---

## Unresolved Questions/Gaps

1. **Exact v7+ stability status** — Status of recent versions needs verification from pub.dev
2. **iOS StoreKit 2 timeline** — When full migration required (RevenueCat tracking this)
3. **Deeplink handling** — How to handle app-store redirect links (needs more detail)
4. **Subscription grace period** — RevenueCat's handling of Apple grace periods (documented but complex)
5. **Proration handling** (Android) — RevenueCat's auto-proration vs manual handling strategies
6. **Revenue reporting** — Analytics/dashboard setup verification needed
7. **Test mode behavior** — Exact sandbox behavior across latest OS versions

---

## References & Documentation

- RevenueCat official docs: https://docs.revenuecat.com/docs/flutter
- pub.dev: https://pub.dev/packages/purchases_flutter
- Google Play Billing Library: https://developer.android.com/google/play/billing
- App Store Connect: https://appstoreconnect.apple.com
- RevenueCat Dashboard: https://app.revenuecat.com

