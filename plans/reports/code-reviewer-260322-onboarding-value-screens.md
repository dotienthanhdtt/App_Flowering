# Code Review: Onboarding Value Screens (Screens 03/04/05)

**Date:** 2026-03-22
**Scope:** Replace WelcomeProblemScreen (PageView) with 3 separate onboarding value screens
**Files:** 10 (4 new, 4 modified, 1 deleted, 1 route constants already updated)
**LOC changed:** ~250 added, ~200 removed
**Analysis:** flutter analyze passes with 0 issues

---

## Overall Assessment

Clean, well-structured refactor. The shared layout pattern (`OnboardingValueLayout`) is a good DRY extraction. Translation keys are consistent, assets exist, route wiring is correct, and no orphaned references to the deleted `WelcomeProblemScreen` remain. A few issues below warrant attention.

---

## Critical Issues

None.

---

## High Priority

### 1. Screen classes should extend BaseStatelessScreen, not StatelessWidget

**CLAUDE.md mandates:** "Screens without a controller: extend `BaseStatelessScreen`"

All other onboarding screens (`NativeLanguageScreen`, `LearningLanguageScreen`, `ScenarioGiftScreen`) extend `BaseScreen<OnboardingController>`. The new value screens extend plain `StatelessWidget`, breaking the project convention.

However, `OnboardingValueLayout` already creates its own `Scaffold` internally, so extending `BaseStatelessScreen` (which also wraps in `Scaffold`) would cause a **double-Scaffold** problem.

**Recommended fix:** Either:
- (A) Make `OnboardingValueLayout` the `buildContent()` body without its own Scaffold, and have each screen extend `BaseStatelessScreen` with `useSafeArea => false`. Move the Scaffold config into the base class overrides. OR
- (B) Keep the current approach (plain `StatelessWidget`) but add a comment on each screen class explaining the exemption, per CLAUDE.md: *"StatefulWidget screens (rare): exempt from base class, document why in a comment"*. Same principle applies.

Option B is lower-risk and pragmatic. Example:
```dart
/// Onboarding value screen 1 — extends StatelessWidget (not BaseStatelessScreen)
/// because OnboardingValueLayout provides its own Scaffold with custom
/// AnnotatedRegion and status bar styling.
class OnboardingValueScreen1 extends StatelessWidget {
```

### 2. AppButton outline variant changes affect other consumers

The outline variant changes are global:
- `backgroundColor`: `AppColors.surface` -> `Colors.transparent`
- `foregroundColor`: `AppColors.textSecondary` -> `AppColors.primaryColor`
- `borderRadius`: `radiusPill` -> `radiusM`
- `side.color`: added `AppColors.primaryColor` border

This also affects `lib/shared/widgets/error_widget.dart` (line 46) which uses `AppButtonVariant.outline`. Verify the error widget's retry button still looks correct with the new orange/primary styling instead of the previous neutral/secondary look.

---

## Medium Priority

### 3. Navigation stack depth — no back button on screens 1 & 2

The skip button navigates directly to `onboardingNativeLanguage`, but screens 1->2->3 use `Get.toNamed()` which pushes onto the navigation stack. When the user reaches `NativeLanguageScreen` (which has a back button calling `Get.back()`), pressing back from native language will go to value screen 3, not splash. This may or may not be desired.

If the intent is a linear flow with no back-navigation to value screens, consider using `Get.offNamed()` instead of `Get.toNamed()` between value screens, or `Get.offAllNamed()` when transitioning to native language from screen 3.

### 4. `OnboardingBinding()` is re-created for each of the 3 value screens

Each route instantiates a new `OnboardingBinding()`. Since the binding uses `Get.lazyPut` with `isRegistered` guards, this is functionally safe. But it creates and discards 3 binding instances during the flow. Not a bug, just a minor inefficiency consistent with how other onboarding routes are wired.

### 5. Unused import: `flutter/material.dart` in screen files

The 3 screen files import `package:flutter/material.dart` for `StatelessWidget` / `BuildContext` / `Widget`. This is correct and needed. No issue here — just confirmed.

---

## Low Priority

### 6. Magic number: hardcoded skip row height

`onboarding_value_layout.dart` line 92: `height: 44` is a magic number. Consider using an AppSizes constant (e.g., `AppSizes.inputHeight` which is likely 44-48).

### 7. File naming convention

CLAUDE.md says kebab-case for file names. The new files use snake_case (`onboarding_value_screen_1.dart`). However, looking at the existing codebase, onboarding files already use snake_case (`splash_screen.dart`, `step_dots_indicator.dart`). The kebab-case convention is followed by route/config files but not widget/view files. This is a pre-existing inconsistency — not introduced by this change.

---

## Edge Cases Found by Scout

1. **Orphaned references:** Grep for `welcome_problem`, `WelcomeProblemScreen`, `welcomeProblem` returns 0 matches. Clean removal.
2. **Asset existence:** All 3 PNG files (`onboarding_value_1.png`, `onboarding_value_2.png`, `onboarding_value_3.png`) confirmed present in `assets/images/onboarding/`.
3. **Translation parity:** Both EN and VI files have all 8 new keys (`onboarding_skip`, `onboarding_value_headline_1-3`, `onboarding_value_body_1-3`, `onboarding_next`, `onboarding_ready`). Key counts match.
4. **Route constants:** `onboardingWelcome`, `onboardingWelcome2`, `onboardingWelcome3` all defined in `app-route-constants.dart` and wired in page definitions.
5. **Splash entry point:** `splash_controller.dart` line 29 still navigates to `AppRoutes.onboardingWelcome` which now correctly points to `OnboardingValueScreen1`.

---

## Positive Observations

- **Good DRY pattern:** The shared `OnboardingValueLayout` eliminates duplication across 3 screens while keeping each screen's configuration explicit and readable.
- **Proper use of AppText with .tr:** All user-facing strings use translation keys.
- **Proper use of AppButton:** CTA buttons use the shared widget with appropriate variants (outline for screens 1-2, primary for screen 3).
- **Clean deletion:** The old `WelcomeProblemScreen` (200 lines with internal PageView) was fully removed with no traces.
- **Step dots indicator:** Clean, minimal update to match new color tokens.
- **File sizes:** All files well under 200 lines. Layout is 115 lines, screens are 23 lines each.

---

## Recommended Actions

1. **[High]** Add exemption comments to the 3 screen classes explaining why they don't extend `BaseStatelessScreen`
2. **[High]** Verify `error_widget.dart` retry button visual after outline variant color/radius changes
3. **[Medium]** Evaluate navigation stack strategy — decide if value screens should be replacements (`offNamed`) or pushes (`toNamed`)
4. **[Low]** Replace magic number `44` with `AppSizes.inputHeight` in layout skip row

---

## Metrics

- **Type Coverage:** N/A (Dart, statically typed)
- **flutter analyze:** 0 issues
- **Test Coverage:** Not measured (no new tests added — screens are declarative UI only)
- **Linting Issues:** 0
