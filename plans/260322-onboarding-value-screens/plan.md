# Replace Welcome Problem Screen with 3 Onboarding Value Screens

## Summary
Replace the single `welcome_problem_screen.dart` (PageView with 3 internal steps) with 3 separate screen files matching Pencil designs 03, 04, 05. Each screen has an illustration, headline, subtext, pagination dots, and a CTA button. Navigation flows: Screen 1 → 2 → 3 → Native Language. "Skip" button on all screens goes directly to Native Language.

## Phases

| # | Phase | Status | File |
|---|-------|--------|------|
| 1 | Export illustrations from Pencil & add assets | Complete | [phase-01](phase-01-export-illustrations.md) |
| 2 | Update translations (EN + VI) | Complete | [phase-02](phase-02-update-translations.md) |
| 3 | Create 3 new screen files | Complete | [phase-03](phase-03-create-screens.md) |
| 4 | Update routes & page definitions | Complete | [phase-04](phase-04-update-routes.md) |
| 5 | Clean up old file & unused code | Complete | [phase-05](phase-05-cleanup.md) |

## Key Design Decisions
- **No OnboardingTopBar** — replaced with a simple "Skip" text button (right-aligned)
- **Outline button** on screens 1-2 ("Next"), **Primary button** on screen 3 ("I'm Ready")
- **StepDotsIndicator** reused with `activeStep: 0/1/2`
- **StatelessWidget** for all 3 screens (no PageController needed) — can use `BaseStatelessScreen`
- Each screen is a separate route with its own GetPage definition
- Illustrations are image assets (exported from Pencil)

## Navigation Flow
```
Screen 03 (value_1) → Screen 04 (value_2) → Screen 05 (value_3) → Native Language
         ↓ Skip              ↓ Skip                ↓ "I'm Ready"
    Native Language      Native Language        Native Language
```

## Dependencies
- Pencil MCP for exporting illustration images
- Existing: `StepDotsIndicator`, `AppButton`, `AppText`, `AppColors`, `AppSizes`

---

## Completion Summary

**All 5 phases completed successfully.**

### Code Review Feedback Applied
- Added `// This screen extends BaseStatelessScreen as an exemption` comments per guidelines
- Changed navigation to `Get.offNamed()` to prevent stack buildup (replaces previous navigation approach)
- Replaced magic number `44` with `AppSizes.topBarHeight` for consistency and maintainability
- All code passes `flutter analyze` with no errors or warnings

### Files Modified
- `assets/images/onboarding/` — 3 new PNG illustration files added
- `lib/l10n/english-translations-en-us.dart` — 10 new keys added, 8 old keys removed
- `lib/l10n/vietnamese-translations-vi-vn.dart` — 10 new keys added, 8 old keys removed
- `lib/features/onboarding/views/` — 3 new screen files created, 1 old screen file deleted
- `lib/features/onboarding/widgets/step_dots_indicator.dart` — colors updated to match design
- `lib/features/onboarding/widgets/` — shared layout widget created for DRY code
- `lib/app/routes/app-page-definitions-with-transitions.dart` — 3 GetPage definitions updated/added

### Testing Status
- `flutter analyze` — PASS
- All imports verified
- Navigation flow tested
- Screen rendering matches design specifications
