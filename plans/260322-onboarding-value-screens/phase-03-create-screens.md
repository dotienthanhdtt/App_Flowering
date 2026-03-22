# Phase 3: Create 3 New Screen Files

## Status
**Complete**

## Overview
Create 3 separate StatelessWidget screens replacing the single WelcomeProblemScreen.

### Implementation Summary
- Created 3 new screen files extending BaseStatelessScreen:
  - lib/features/onboarding/views/onboarding_value_screen_1.dart
  - lib/features/onboarding/views/onboarding_value_screen_2.dart
  - lib/features/onboarding/views/onboarding_value_screen_3.dart
- All screens follow design spec: layout with SafeArea, Skip button, illustration (full-width), headline, body, StepDotsIndicator, CTA button
- Screen 1-2: Outline "Next" buttons with navigation to next screen
- Screen 3: Primary "I'm Ready" button with navigation to native language screen
- All screens include Skip button (ghost style) to navigate directly to native language
- Created shared OnboardingValueScreenLayout widget for DRY layout reuse
- Updated StepDotsIndicator colors: primaryColor (#FD9029) for active, infoColor (#9CB0CF) for inactive
- Code review feedback applied: BaseStatelessScreen exemption comments, Get.offNamed for proper navigation, AppSizes.topBarHeight constant usage

## Design Spec (from Pencil)

### Common Layout (all 3 screens)
```
Scaffold (backgroundColor)
├── Column
│   ├── SafeArea top spacer (30px)
│   ├── Skip Row (height: 44, padding-right: 16, justify: end)
│   │   └── "Skip" ghost button → navigates to native language
│   ├── Illustration (full-width, aspect ratio 1:1, from assets)
│   ├── SizedBox(height: 32)
│   ├── Expanded → Column (padding: 0,24)
│   │   ├── Headline (Inter, 32px/font8XL, bold 700, center, #1A1A2E)
│   │   ├── SizedBox(height: 12)
│   │   ├── Subheadline (Inter, 18px/font3XL, normal, center, neutralColor)
│   │   ├── Spacer or SizedBox(height: 48)
│   │   ├── StepDotsIndicator(activeStep: N) — centered
│   │   ├── SizedBox(height: 24)
│   │   ├── CTA Button (full-width)
│   │   └── SizedBox(height: 34) — bottom safe area
```

### Screen-Specific Differences

| Property | Screen 03 (Value 1) | Screen 04 (Value 2) | Screen 05 (Value 3) |
|----------|---------------------|---------------------|---------------------|
| Image | `onboarding_value_1.png` | `onboarding_value_2.png` | `onboarding_value_3.png` |
| Headline key | `onboarding_value_headline_1` | `onboarding_value_headline_2` | `onboarding_value_headline_3` |
| Body key | `onboarding_value_body_1` | `onboarding_value_body_2` | `onboarding_value_body_3` |
| Active step | 0 | 1 | 2 |
| Button variant | Outline ("Next") | Outline ("Next") | Primary ("I'm Ready") |
| Button action | → onboardingWelcome2 | → onboardingWelcome3 | → onboardingNativeLanguage |

### Button Styles (matching Pencil components)
- **Outline (Next):** `AppButton(variant: AppButtonVariant.outline)` — border: primaryColor 1.5px, cornerRadius: 12, height: 52
- **Primary (I'm Ready):** `AppButton(variant: AppButtonVariant.primary)` — bg: primaryColor, text: white, cornerRadius: 12, height: 52

### StepDotsIndicator Update
Current dots use `textPrimaryColor` for active / `borderLightColor` for inactive.
Design uses `primaryColor` (#FD9029) for active / `infoColor` (#9CB0CF) for inactive.
→ Update `step_dots_indicator.dart` colors to match design.

## Files to Create
- `lib/features/onboarding/views/onboarding_value_screen_1.dart`
- `lib/features/onboarding/views/onboarding_value_screen_2.dart`
- `lib/features/onboarding/views/onboarding_value_screen_3.dart`

## Files to Modify
- `lib/features/onboarding/widgets/step_dots_indicator.dart` — update dot colors

## Architecture
- All 3 screens extend `BaseStatelessScreen` (no controller needed)
- Use `AppText`, `AppButton`, `StepDotsIndicator` shared widgets
- Skip button: `GestureDetector` with `AppText('onboarding_skip'.tr)`
- No `OnboardingTopBar` — just the skip button

## Success Criteria
- All 3 screens render correctly matching design screenshots
- Navigation flow: 1→2→3→native language
- Skip button works on all screens
- Step dots show correct active state
- Buttons match design variants
