# Phase 1 — Infrastructure & Config

**Priority:** Critical
**Status:** completed
**Effort:** Small

---

## Context

- Brainstorm: `plans/reports/brainstorm-260228-1551-onboarding-first-half.md`
- API docs: `docs/api_docs/auth-api.md`
- Design: `design.pen` (Pencil MCP)

## Overview

Update env config, API endpoints, route constants, page definitions, and UserModel to support onboarding flow. Foundation for all subsequent phases.

## Requirements

- Update `.env.dev` base URL to `https://dev.broduck.me`
- Add `/users/me` endpoint constant
- Add onboarding route constants
- Register onboarding pages with slide transitions
- Change initial route from `/login` to `/splash`
- Align `UserModel` fields with actual API response
- Create onboarding feature directory structure + binding

## Implementation Steps

### 1. Update `.env.dev`

```
API_BASE_URL=https://dev.broduck.me
```

### 2. Update `api_endpoints.dart`

Add to User section:
```dart
static const String userMe = '/users/me';
static const String updateUserMe = '/users/me'; // PATCH
```

Note: Current file has `/user/profile` — API actually uses `/users/me`. Update existing constants too.

### 3. Update `user_model.dart`

Current fields don't match API response. API returns:
```json
{
  "id": "uuid",
  "email": "...",
  "displayName": "...",
  "avatarUrl": "...",
  "nativeLanguageId": "uuid",
  "nativeLanguageCode": "en",
  "nativeLanguageName": "English",
  "createdAt": "..."
}
```

Update `UserModel`:
- `name` → `displayName` (json key: `displayName`)
- Add `nativeLanguageId`, `nativeLanguageCode`, `nativeLanguageName`
- Remove `nativeLanguage`, `targetLanguage` (not in API)
- Update `fromJson`/`toJson`/`copyWith`

### 4. Add route constants in `app-route-constants.dart`

```dart
// Onboarding routes
static const String onboardingWelcome = '/onboarding/welcome';
static const String onboardingWelcome2 = '/onboarding/welcome-2';
static const String onboardingWelcome3 = '/onboarding/welcome-3';
static const String onboardingNativeLanguage = '/onboarding/native-language';
static const String onboardingLearningLanguage = '/onboarding/learning-language';
```

### 5. Create onboarding directory structure

```bash
mkdir -p lib/features/onboarding/{bindings,controllers,views,widgets,models}
```

### 6. Create `onboarding_binding.dart`

```dart
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(() => OnboardingController());
  }
}
```

### 7. Create `splash_binding.dart` (or include in page definition)

SplashController can be put directly in GetPage's binding since it's a one-time screen.

### 8. Register pages in `app-page-definitions-with-transitions.dart`

- Change `initialRoute` from `AppRoutes.login` to `AppRoutes.splash`
- Replace splash placeholder with real `SplashScreen()`
- Add 5 onboarding GetPage entries with `Transition.rightToLeft`
- All onboarding pages share `OnboardingBinding`

### 9. Run `flutter analyze`

Verify no compile errors after all changes.

## Files Modified

| File | Change |
|------|--------|
| `.env.dev` | Update `API_BASE_URL` |
| `lib/core/constants/api_endpoints.dart` | Add `/users/me`, fix `/user/profile` paths |
| `lib/shared/models/user_model.dart` | Align fields with API |
| `lib/app/routes/app-route-constants.dart` | Add 5 onboarding routes |
| `lib/app/routes/app-page-definitions-with-transitions.dart` | Register pages, change initial route |

## Files Created

| File | Purpose |
|------|---------|
| `lib/features/onboarding/bindings/onboarding_binding.dart` | DI for OnboardingController |

## Todo

- [x] Update `.env.dev` base URL
- [x] Update `api_endpoints.dart`
- [x] Update `user_model.dart` to match API
- [x] Add onboarding route constants
- [x] Create onboarding directory + binding
- [x] Register pages + change initial route
- [x] `flutter analyze` passes

## Success Criteria

- All onboarding routes defined and registered
- `UserModel` matches `/users/me` response shape
- Initial route = `/splash`
- `flutter analyze` clean
