# Phase 1: Platform Setup & Dependencies

## Context Links
- [Brainstorm](../reports/brainstorm-260313-revenuecat-payment-feature.md) — Platform Setup section
- [RC SDK Research](../reports/researcher-260313-revenuecat-flutter-sdk.md)

## Overview
- **Priority:** Critical
- **Status:** Complete
- **Description:** Add `purchases_flutter` dependency, configure platform files, add RC API keys to env config.

## Key Insights
- Android needs BILLING permission + FlutterFragmentActivity
- iOS needs In-App Purchase capability + minimum iOS 13
- RC API keys are platform-specific (Google vs Apple)

## Requirements
- `purchases_flutter` added to pubspec.yaml
- Android: BILLING permission, FlutterFragmentActivity
- iOS: Podfile minimum iOS 13+ (check current)
- Env config: RC API keys for both platforms

## Related Code Files

### Files to Modify
- `pubspec.yaml` — add `purchases_flutter` dependency
- `lib/config/env_config.dart` — add RC API key getters
- `android/app/src/main/AndroidManifest.xml` — BILLING permission
- `android/app/src/main/kotlin/.../MainActivity.kt` — FlutterFragmentActivity
- `ios/Podfile` — verify minimum iOS version
- `.env.dev` / `.env.prod` — add RC API keys (DO NOT commit)

### Files to Create
- None

## Implementation Steps

1. **Add dependency:**
   ```yaml
   # pubspec.yaml
   dependencies:
     purchases_flutter: ^8.0.0
   ```
   Run `flutter pub get`

2. **Android — BILLING permission:**
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <uses-permission android:name="com.android.vending.BILLING" />
   ```

3. **Android — FlutterFragmentActivity:**
   ```kotlin
   // MainActivity.kt
   import io.flutter.embedding.android.FlutterFragmentActivity
   class MainActivity: FlutterFragmentActivity()
   ```

4. **iOS — Podfile minimum version:**
   Ensure `platform :ios, '13.0'` or higher

5. **Env config — add RC keys:**
   ```dart
   // lib/config/env_config.dart
   static String get revenueCatAppleApiKey => dotenv.get('REVENUECAT_APPLE_API_KEY', fallback: '');
   static String get revenueCatGoogleApiKey => dotenv.get('REVENUECAT_GOOGLE_API_KEY', fallback: '');
   ```

6. **Env files — add keys:**
   ```
   # .env.dev / .env.prod
   REVENUECAT_APPLE_API_KEY=appl_xxxxx
   REVENUECAT_GOOGLE_API_KEY=goog_xxxxx
   ```

7. **Verify:** Run `flutter pub get && flutter analyze`

## Todo List
- [x] Add `purchases_flutter` to pubspec.yaml (v8.11.0)
- [x] Run `flutter pub get` — succeeded
- [x] Add BILLING permission to AndroidManifest.xml
- [x] Update MainActivity.kt to FlutterFragmentActivity
- [x] Verify iOS Podfile minimum version — 13.0 confirmed
- [x] Add RC API key getters to env_config.dart
- [x] Add RC API keys to .env.dev and .env.prod
- [x] Run `flutter analyze` — no new errors

## Success Criteria
- `flutter pub get` succeeds
- `flutter analyze` passes
- RC API key getters accessible via EnvConfig

## Risk Assessment
- **Missing API keys:** App should gracefully handle empty keys (skip RC init)
- **iOS capability:** Must be enabled in Xcode project settings manually

## Next Steps
- Phase 2: Models & API Endpoints
