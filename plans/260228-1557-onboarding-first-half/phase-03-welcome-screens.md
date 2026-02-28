# Phase 3 — Welcome Screens 1A/1B/1C

**Priority:** High
**Status:** completed
**Effort:** Medium
**Depends on:** Phase 2

---

## Context

- Design nodes: `hSf9J` (1A), `KkU9r` (1B), `TVpMu` (1C)
- 3 screens sharing identical layout, differing only in content + bottom action

## Overview

Build a single reusable `WelcomeProblemScreen` that accepts step data (headline, subtext, dot position, CTA). Create shared widgets for top bar and step dots. Navigation: tap-to-advance with slide transitions.

## Screen Content Data

```dart
const welcomeSteps = [
  WelcomeStepData(
    headline: "Your brain\nwasn't built\nto memorize.",
    subtext: "It was built to speak. Flowering works with your brain — not against it.",
    activeStep: 0,
    showCta: false,
  ),
  WelcomeStepData(
    headline: "You forget\nbecause nothing\nwas built for you.",
    subtext: "Generic apps give everyone the same lesson. Flowering remembers what you struggled with — and brings it back at the right moment.",
    activeStep: 1,
    showCta: false,
  ),
  WelcomeStepData(
    headline: "Finally, an app\nthat knows\nonly you.",
    subtext: "Your pace. Your interests. Your goals. Flowering builds a living path that evolves as you do — nobody else gets the same one.",
    activeStep: 2,
    showCta: true,
    ctaLabel: "Make it mine",
  ),
];
```

## Implementation Steps

### 1. Create `onboarding_top_bar.dart` widget

Shared across 1A/1B/1C:
- Row: [Logo icon (24x24 rounded) + "Flowering" text (18px bold)] ... [spacer] ... ["Log in" text (15px, #7AACCC)]
- Padding: top 56, horizontal 32
- "Log in" is a no-op `GestureDetector` for now

### 2. Create `step_dots_indicator.dart` widget

- 3 horizontal dots with gap=8
- Active dot: width 28, height 4, dark (#191919), cornerRadius 4
- Inactive dot: width 16, height 4, muted (#E5DFC9), cornerRadius 4
- Takes `activeStep` (0, 1, 2) param

### 3. Create `welcome_problem_screen.dart`

Layout (vertical, space-between):
```
┌──────────────────────┐
│ OnboardingTopBar      │  ← top bar
├──────────────────────┤
│                      │
│ StepDotsIndicator    │  ← dots at top of content
│                      │
│ Headline (34px, 800) │  ← bold headline
│ Subtext (16px, #5C5646) │
│                      │
│ "Tap anywhere..."    │  ← if !showCta (steps 0,1)
│ [Make it mine] btn   │  ← if showCta (step 2)
└──────────────────────┘
```

- Background: AppColors.background (#F8F4E3)
- Content padding: top 48, horizontal 32, bottom 60
- `justifyContent: spaceBetween` equivalent → use `MainAxisAlignment.spaceBetween` in Column
- For steps 0 and 1: Wrap entire screen in `GestureDetector(onTap: nextStep)`
- For step 2: "Make it mine" button navigates to 2A

### 4. Navigation logic

Each welcome route passes the step index:
```dart
// In page definitions:
GetPage(
  name: AppRoutes.onboardingWelcome,
  page: () => const WelcomeProblemScreen(step: 0),
  ...
),
GetPage(
  name: AppRoutes.onboardingWelcome2,
  page: () => const WelcomeProblemScreen(step: 1),
  ...
),
GetPage(
  name: AppRoutes.onboardingWelcome3,
  page: () => const WelcomeProblemScreen(step: 2),
  ...
),
```

Navigation on tap:
- Step 0 → `Get.toNamed(AppRoutes.onboardingWelcome2)`
- Step 1 → `Get.toNamed(AppRoutes.onboardingWelcome3)`
- Step 2 CTA → `Get.toNamed(AppRoutes.onboardingNativeLanguage)`

### 5. Reset status bar to dark

In `WelcomeProblemScreen.build()`:
```dart
SystemChrome.setSystemUIOverlayStyle(
  const SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.dark,
  ),
);
```

## Files Created

| File | Purpose |
|------|---------|
| `lib/features/onboarding/widgets/onboarding_top_bar.dart` | Logo + "Log in" bar |
| `lib/features/onboarding/widgets/step_dots_indicator.dart` | 3-dot progress indicator |
| `lib/features/onboarding/views/welcome_problem_screen.dart` | Data-driven welcome screen |

## Design Specs

| Element | Style |
|---------|-------|
| Background | #F8F4E3 (AppColors.background) |
| Headline | Outfit, 34px, weight 800, #191919, letterSpacing -0.8, lineHeight 1.2 |
| Subtext | Outfit, 16px, weight 400, #5C5646, lineHeight 1.6 |
| Tap hint | Outfit, 15px, #9C9585 |
| CTA button | Full width, 56h, pill radius, #FF7A27 bg, white text 17px bold |
| Logo text | Outfit, 18px, 700 weight, #191919 |
| Login text | Outfit, 15px, 600 weight, #7AACCC |

## Todo

- [x] Create `onboarding_top_bar.dart`
- [x] Create `step_dots_indicator.dart`
- [x] Create `welcome_problem_screen.dart` (data-driven)
- [x] Wire navigation: tap → next screen, CTA → native language
- [x] Reset status bar to dark icons
- [x] Visual match against design screenshots
- [x] `flutter analyze` passes

## Success Criteria

- All 3 welcome screens render from single widget with different data
- Tap anywhere advances 1A→1B, 1B→1C
- 1C shows CTA button instead of tap hint
- "Make it mine" → navigates to 2A
- Layout, typography, colors match design exactly
