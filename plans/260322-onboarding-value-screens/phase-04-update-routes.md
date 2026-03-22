# Phase 4: Update Routes & Page Definitions

## Status
**Complete**

## Overview
Wire up the 3 new screens to existing route constants and add GetPage definitions.

### Implementation Summary
- Updated lib/app/routes/app-page-definitions-with-transitions.dart:
  - Removed old import of welcome_problem_screen.dart
  - Added imports for 3 new screen files
  - Replaced WelcomeProblemScreen GetPage with OnboardingValueScreen1 for onboardingWelcome route
  - Added GetPage entries for onboardingWelcome2 and onboardingWelcome3 routes
- All 3 routes use OnboardingBinding for dependency injection
- Navigation sequence: Value Screen 1 → Value Screen 2 → Value Screen 3 → Native Language
- Skip button on all screens navigates directly to native language
- Transition types: fade for first screen, rightToLeft for screens 2-3 (per design)
- All routes properly configured and tested

## Route Constants (already exist)
- `AppRoutes.onboardingWelcome` = `/onboarding/welcome` → Screen 03 (Value 1)
- `AppRoutes.onboardingWelcome2` = `/onboarding/welcome-2` → Screen 04 (Value 2)
- `AppRoutes.onboardingWelcome3` = `/onboarding/welcome-3` → Screen 05 (Value 3)

Routes already defined in `app-route-constants.dart` — no changes needed there.

## Page Definitions Changes

### File: `app-page-definitions-with-transitions.dart`

1. **Remove** import of `welcome_problem_screen.dart`
2. **Add** imports for 3 new screen files
3. **Replace** WelcomeProblemScreen GetPage with OnboardingValueScreen1
4. **Add** 2 new GetPage entries for screens 2 and 3

```dart
// Screen 03 — onboarding value 1
GetPage(
  name: AppRoutes.onboardingWelcome,
  page: () => const OnboardingValueScreen1(),
  binding: OnboardingBinding(),
  transition: Transition.fade,
  transitionDuration: defaultDuration,
),

// Screen 04 — onboarding value 2
GetPage(
  name: AppRoutes.onboardingWelcome2,
  page: () => const OnboardingValueScreen2(),
  binding: OnboardingBinding(),
  transition: defaultTransition,
  transitionDuration: defaultDuration,
  curve: defaultCurve,
),

// Screen 05 — onboarding value 3
GetPage(
  name: AppRoutes.onboardingWelcome3,
  page: () => const OnboardingValueScreen3(),
  binding: OnboardingBinding(),
  transition: defaultTransition,
  transitionDuration: defaultDuration,
  curve: defaultCurve,
),
```

## Files to Modify
- `lib/app/routes/app-page-definitions-with-transitions.dart`

## Success Criteria
- All 3 routes navigate correctly
- Splash screen still routes to `onboardingWelcome` for new users
- Transition: fade for first screen, rightToLeft for screens 2-3
