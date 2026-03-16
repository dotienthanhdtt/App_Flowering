# Onboarding First Half — Implementation Plan

**Created:** 2026-02-28
**Status:** completed
**Brainstorm:** `plans/reports/brainstorm-260228-1551-onboarding-first-half.md`
**Branch:** `feat/onboarding-first-half`

---

## Overview

Implement 6 onboarding screens: Splash → Welcome 1A/1B/1C → Native Language → Learning Language. Includes real API token check on splash, data-driven welcome screens, and mock language data.

## Phases

| # | Phase | Status | File |
|---|-------|--------|------|
| 1 | Infrastructure & Config | completed | `phase-01-infrastructure.md` |
| 2 | Splash Screen | completed | `phase-02-splash-screen.md` |
| 3 | Welcome Screens 1A/1B/1C | completed | `phase-03-welcome-screens.md` |
| 4 | Language Selection 2A/2B | completed | `phase-04-language-selection.md` |

## Dependencies

```
Phase 1 (infra) ──▶ Phase 2 (splash) ──▶ Phase 3 (welcome) ──▶ Phase 4 (languages)
```

All phases sequential — each depends on prior routes/bindings.

## Key Files Modified

- `.env.dev` — base URL update
- `lib/core/constants/api_endpoints.dart` — add `/users/me`
- `lib/app/routes/app-route-constants.dart` — onboarding routes
- `lib/app/routes/app-page-definitions-with-transitions.dart` — page registrations + initial route
- `lib/shared/models/user_model.dart` — align fields with API response

## Key Files Created

- `lib/features/onboarding/bindings/onboarding_binding.dart`
- `lib/features/onboarding/controllers/splash_controller.dart`
- `lib/features/onboarding/controllers/onboarding_controller.dart`
- `lib/features/onboarding/views/splash_screen.dart`
- `lib/features/onboarding/views/welcome_problem_screen.dart`
- `lib/features/onboarding/views/native_language_screen.dart`
- `lib/features/onboarding/views/learning_language_screen.dart`
- `lib/features/onboarding/widgets/onboarding_top_bar.dart`
- `lib/features/onboarding/widgets/step_dots_indicator.dart`
- `lib/features/onboarding/widgets/language_card.dart`
- `lib/features/onboarding/models/onboarding_language_model.dart`

## Success Criteria

- [ ] Splash shows 3s minimum, checks token via GET /users/me
- [ ] Valid token → /home, invalid → /onboarding/welcome
- [ ] 1A/1B/1C screens match design (layout, colors, typography)
- [ ] Tap navigates 1A→1B→1C with slide transition
- [ ] 1C "Make it mine" button → 2A
- [ ] 2A shows language list with Vietnamese pre-selected
- [ ] 2B shows 2-col grid, English pre-selected
- [ ] 2B selection → navigates to Screen 3 route (placeholder OK)
- [ ] `flutter analyze` passes with no errors
