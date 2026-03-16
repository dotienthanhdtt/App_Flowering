# Phase 01 — Foundation: Routes, Models, Translations

## Overview
- **Priority:** P1 (blocks all other phases)
- **Status:** Completed
- **Effort:** 2h

Setup routes, data models, and translation keys needed by screens 07-14.

## Key Insights

- `ApiEndpoints` already has all needed constants — no changes required
- Existing `OnboardingLanguage` model uses emoji flags; API returns `flagUrl` — model needs restructuring
- `OnboardingController` uses `lazyPut` without `fenix: true` — may be garbage-collected between screens
- No `AuthController`, `AuthBinding`, or auth-related models exist yet

## Requirements

### Functional
- New route constants for screens 08-14
- Data models for onboarding API responses and auth responses
- Translation keys for all new screen UI text (en-US + vi-VN)
- OnboardingController persistence across navigation

### Non-functional
- Models under 200 lines each
- All strings via `.tr` translation system

## Related Code Files

### Modify
- `lib/app/routes/app-route-constants.dart` — add 6 new routes
- `lib/app/routes/app-page-definitions-with-transitions.dart` — add page definitions
- `lib/features/onboarding/bindings/onboarding_binding.dart` — add `fenix: true`
- `lib/features/onboarding/models/onboarding_language_model.dart` — restructure for API
- `l10n/english-translations-en-us.dart` — add ~40 new keys
- `l10n/vietnamese-translations-vi-vn.dart` — add ~40 new keys

### Create
- `lib/features/onboarding/models/onboarding_session_model.dart` — sessionToken + turnNumber
- `lib/features/onboarding/models/onboarding_profile_model.dart` — profile + scenarios[]
- `lib/features/onboarding/models/scenario_model.dart` — id, title, description, icon, accentColor
- `lib/features/auth/models/auth_response_model.dart` — accessToken, refreshToken, user

## Implementation Steps

### 1. Add Route Constants

In `app-route-constants.dart`, add:
```dart
static const String onboardingScenarioGift = '/onboarding/scenario-gift';
static const String onboardingLoginGate = '/onboarding/login-gate';
static const String signup = '/signup';
static const String forgotPassword = '/forgot-password';
static const String otpVerification = '/otp-verification';
static const String newPassword = '/new-password';
```

### 2. Add Page Definitions

In `app-page-definitions-with-transitions.dart`, add GetPage entries for each new route:
- Scenario Gift → `rightToLeft`, OnboardingBinding
- Login Gate → not a separate page (bottom sheet), skip
- Signup → `rightToLeft`, AuthBinding
- Login → update existing placeholder with real screen + AuthBinding
- Forgot Password → `rightToLeft`, AuthBinding
- OTP Verification → `rightToLeft`, AuthBinding
- New Password → `rightToLeft`, AuthBinding

### 3. Create Onboarding Models

**`onboarding_session_model.dart`:**
```dart
class OnboardingSession {
  final String sessionToken;
  final int turnNumber;
  final bool isLastTurn;
  final String? floraMessage;
  final List<String>? quickReplies;

  factory OnboardingSession.fromJson(Map<String, dynamic> json) { ... }
}
```

**`onboarding_profile_model.dart`:**
```dart
class OnboardingProfile {
  final String userId;
  final List<Scenario> scenarios;
  final Map<String, dynamic>? preferences;

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) { ... }
}
```

**`scenario_model.dart`:**
```dart
class Scenario {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String accentColor; // 'primary', 'blue', 'green', 'lavender', 'rose'

  factory Scenario.fromJson(Map<String, dynamic> json) { ... }
}
```

### 4. Create Auth Response Model

**`auth_response_model.dart`:**
```dart
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) { ... }
}
```

### 5. Restructure OnboardingLanguage Model

Current model uses emoji flags and static lists. Restructure to support API data:
```dart
class OnboardingLanguage {
  final String id;       // UUID from API
  final String code;     // 'en', 'vi'
  final String name;     // 'English'
  final String? flagUrl; // URL from API
  final String flag;     // emoji fallback
  final bool isEnabled;

  factory OnboardingLanguage.fromJson(Map<String, dynamic> json) { ... }

  // Keep static fallback lists for offline mode
  static List<OnboardingLanguage> get fallbackNativeLanguages => [...];
  static List<OnboardingLanguage> get fallbackLearningLanguages => [...];
}
```

### 6. Fix OnboardingBinding Persistence
<!-- Updated: Validation Session 1 - fenix:true → permanent:true -->

```dart
// Change from:
Get.lazyPut<OnboardingController>(() => OnboardingController());
// To:
Get.put<OnboardingController>(OnboardingController(), permanent: true);
```

### 7. Add Social Auth Packages
<!-- Updated: Validation Session 1 - add packages now -->

Add to `pubspec.yaml`:
```yaml
dependencies:
  google_sign_in: ^6.2.2
  sign_in_with_apple: ^6.1.4
```

Run `flutter pub get` after adding.

### 7. Add Translation Keys

Add ~40 keys for: AI chat UI, scenario gift, login gate, signup form, login form, forgot password, OTP, new password screens. Both en-US and vi-VN files.

Key categories:
- `chat_*` — AI chat screen text
- `scenario_*` — scenario gift screen
- `auth_*` — login gate, signup, login
- `forgot_*` — forgot password flow
- `otp_*` — OTP verification
- `validation_*` — form validation messages

## Todo List

- [x] Add 6 new route constants (including onboardingLoginGate)
- [x] Add page definitions for new routes
- [x] Create onboarding session model
- [x] Create onboarding profile model
- [x] Create scenario model
- [x] Create auth response model
- [x] Restructure OnboardingLanguage model for API
- [x] Change OnboardingBinding to `permanent: true`
- [x] Add google_sign_in + sign_in_with_apple to pubspec.yaml
- [x] Add English translation keys (~40)
- [x] Add Vietnamese translation keys (~40)
- [x] Run `flutter analyze` to verify no errors

## Success Criteria

- All new routes navigable (even if screens are placeholders)
- Models serialize/deserialize correctly
- `flutter analyze` passes with no errors
- OnboardingController persists across screen navigation

## Risk Assessment

- **OnboardingLanguage restructure** may break existing language screens → test screens 05-06 after changes
- **Translation key count** may grow during later phases → keep key naming consistent

## Next Steps

→ Phase 02: Language API Integration
