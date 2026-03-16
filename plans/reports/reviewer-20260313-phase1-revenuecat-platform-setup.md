# Code Review: Phase 1 RevenueCat Platform Setup

**Date:** 2026-03-13
**Reviewer:** code-reviewer
**Score: 8/10**

## Scope

- Files reviewed: 7
- Focus: RevenueCat SDK platform setup (pubspec, Android, iOS, env config)

## Overall Assessment

Solid foundational setup. The changes correctly integrate RevenueCat's `purchases_flutter` SDK across Android and iOS platforms, with environment-based API key management that follows the project's existing patterns. A few issues need attention before moving to Phase 2.

## Critical Issues

### 1. ENV files bundled as Flutter assets AND gitignored (SECURITY RISK)

**Severity: Critical**

The `.env.dev` and `.env.prod` files are listed in `pubspec.yaml` under `flutter: assets:` (lines 62-63). This means they are compiled into the app bundle and can be extracted from the APK/IPA by anyone. While they are gitignored (good), they ship to end users.

This is the project's pre-existing pattern (not introduced by this PR), but adding RevenueCat API keys to these files makes the risk more concrete. RevenueCat public API keys are designed to be client-side, so this is acceptable for RC keys specifically. However, if any secret keys are ever added to these env files, they would be exposed.

**Status:** Acceptable for RevenueCat public API keys. Document that only client-safe keys belong in these files.

## High Priority

### 2. Missing RevenueCat SDK initialization in main.dart

**Severity: High**

The SDK dependency and env keys are set up, but there is no `Purchases.configure()` call anywhere in the codebase. Only `env_config.dart` references the keys. Phase 2 presumably covers this, but the setup is incomplete without it -- `flutter pub get` will pull the SDK but it will sit unused.

**Recommendation:** Confirm Phase 2 plan includes a RevenueCat service initialization step in `initializeServices()` inside `global-dependency-injection-bindings.dart`, following the established service init pattern:

```dart
// In initializeServices(), after other services:
final revenueCatService = Get.put(RevenueCatService());
await revenueCatService.init();
```

### 3. Inconsistent `dotenv` access pattern in env_config.dart

**Severity: Medium**

Existing keys use `dotenv.env['KEY'] ?? ''` (bracket access with null coalescing), but the new RevenueCat keys use `dotenv.get('KEY', fallback: '')`. Both work, but the inconsistency reduces readability.

**Recommendation:** Standardize on one pattern. `dotenv.get()` with `fallback` is slightly safer (throws if key is missing and no fallback given), so migrating existing keys to match would be ideal. At minimum, keep new additions consistent with existing code:

```dart
// Option A: Match existing pattern
static String get revenueCatAppleApiKey =>
    dotenv.env['REVENUECAT_APPLE_API_KEY'] ?? '';

// Option B: Migrate all to dotenv.get (preferred)
static String get apiBaseUrl =>
    dotenv.get('API_BASE_URL', fallback: '');
```

## Medium Priority

### 4. purchases_flutter version pinning

**Severity: Medium**

`purchases_flutter: ^8.0.0` allows any 8.x.x version. This is standard Dart convention and acceptable, but RevenueCat SDK has been known to introduce breaking changes in minor versions. Consider pinning more tightly once a working version is confirmed (e.g., `^8.0.2` or whatever resolves).

### 5. iOS deployment target alignment

**Severity: Low (Already Correct)**

The Podfile sets `platform :ios, '13.0'` and the Xcode project already has `IPHONEOS_DEPLOYMENT_TARGET = 13.0` across all build configurations (Debug, Profile, Release). RevenueCat v8 requires iOS 13.0+, so this is correctly aligned. Good.

## Positive Observations

1. **FlutterFragmentActivity change is correct** -- RevenueCat's billing client on Android requires `FragmentActivity`, and `FlutterFragmentActivity` is the right Flutter equivalent. Clean change.

2. **BILLING permission added correctly** -- `com.android.vending.BILLING` is placed at the manifest level, which is correct.

3. **Env keys follow project pattern** -- Using `flutter_dotenv` with per-environment files matches the existing architecture. Keys are not hardcoded in Dart source.

4. **Gitignore correctly excludes .env files** -- `.env.*` pattern in `.gitignore` prevents accidental commit of real API keys.

5. **Placeholder keys use obvious dummy values** -- `appl_xxxxx` and `goog_xxxxx` make it clear these need replacement.

6. **env_config.dart stays under 200 lines** -- File is clean at 17 lines.

## Edge Cases Found by Scout

1. **No runtime validation of empty API keys** -- If `.env` files are missing or keys are empty, `Purchases.configure()` (when added) will receive empty strings. A guard or assertion should be added in the RevenueCat service init.

2. **Android package name is `com.example.flowering`** -- This is the default Flutter template name. RevenueCat dashboard configuration requires the actual package name. Ensure this matches what is configured in the RC dashboard, or update it before testing.

3. **No StoreKit configuration for iOS testing** -- For sandbox testing on iOS, a StoreKit configuration file (`.storekit`) is typically needed in the Xcode project. This may be a Phase 2 concern.

## Missing Setup Steps (for Phase 2 consideration)

1. RevenueCat SDK initialization (`Purchases.configure()`)
2. RevenueCat service class following GetX service pattern
3. StoreKit configuration file for iOS sandbox testing
4. ProGuard/R8 rules for Android release builds (if needed for obfuscation)
5. In-App Purchase capability in Xcode project (Signing & Capabilities)

## Recommended Actions

1. **[High]** Standardize dotenv access pattern in `env_config.dart`
2. **[High]** Add runtime guard for empty RevenueCat keys in the upcoming service init
3. **[Medium]** Verify Android package name matches RevenueCat dashboard config
4. **[Low]** Consider tighter version pinning after confirming working SDK version

## File-by-File Scores

| File | Score | Notes |
|------|-------|-------|
| pubspec.yaml | 9/10 | Clean addition, correct section |
| AndroidManifest.xml | 10/10 | Correct permission placement |
| MainActivity.kt | 10/10 | Correct FlutterFragmentActivity switch |
| ios/Podfile | 9/10 | Correct minimum version |
| env_config.dart | 7/10 | Inconsistent dotenv access pattern |
| .env.dev | 8/10 | Placeholder values, bundled in app |
| .env.prod | 8/10 | Placeholder values, bundled in app |

## Unresolved Questions

1. Is the `com.example.flowering` Android package name intentional or will it be updated before release?
2. Has the iOS In-App Purchase capability been enabled in Xcode Signing & Capabilities?
3. What RevenueCat entitlement/offering IDs will be used? (Needed for Phase 2 service implementation)
