# Brainstorm: Onboarding 1st Half Implementation

**Date:** 2026-02-28
**Status:** Draft — pending user edits

---

## Scope

6 screens: Splash (0) → Welcome 1A/1B/1C → Native Language (2A) → Learning Language (2B)

### Requirement Summary

- **Splash (Screen 0):** 3s min display, real API token check (GET /users/me). Valid → /home, invalid/expired → onboarding 1A
- **Screens 1A/1B/1C:** Welcome problem statements. Tap-only navigation with slide-right transitions. "Log in" button = no-op for now.
- **Screen 2A:** Native language selection (list). Vietnamese + English active, rest "Soon".
- **Screen 2B:** Learning language selection (grid cards). English active, rest "Coming soon".
- **After 2B:** Navigate to Screen 3 (AI Chat) — next scope

### Ref Files

- API design: `docs/api_docs/auth-api.md`
- Design: `design.pen` (Pencil MCP)
- Base URL (dev): `https://dev.broduck.me`
- Swagger: `https://dev.broduck.me/api/docs`

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Welcome screens | Single `welcome_problem_screen.dart` with params | DRY — 1A/1B/1C differ only in headline, subtext, dot position, CTA visibility |
| Navigation | Separate routes, slide-right transition | User preference. Each screen = GetX page with `Transition.rightToLeft` |
| Splash logic | `Future.wait([timer, apiCheck])` | Ensures min 3s display while token check runs in parallel |
| State management | `OnboardingController` with `.obs` | Tracks `selectedNativeLanguage`, `selectedLearningLanguage` |
| Language data | Static mock list in model file | 7 native langs, 6 learning langs. Most marked "Soon"/"Coming soon" |
| Login button | No-op | Will be wired to Screen 5 (Login Gate) in 2nd half |
| Base URL | Update `.env.dev` to `https://dev.broduck.me` | Real API call in splash needs correct base URL |

---

## Feature Structure

```
lib/features/onboarding/
├── bindings/
│   └── onboarding_binding.dart        # DI for all onboarding controllers
├── controllers/
│   ├── splash_controller.dart         # Token check + 3s timer logic
│   └── onboarding_controller.dart     # Shared state: selected languages, step tracking
├── views/
│   ├── splash_screen.dart             # Screen 0
│   ├── welcome_problem_screen.dart    # Reusable for 1A/1B/1C (data-driven)
│   ├── native_language_screen.dart    # Screen 2A
│   └── learning_language_screen.dart  # Screen 2B
├── widgets/
│   ├── onboarding_top_bar.dart        # Logo + "Log in" link (shared 1A-1C)
│   ├── step_dots_indicator.dart       # 3-dot progress indicator
│   └── language_card.dart             # Reusable card for 2A list + 2B grid
└── models/
    └── onboarding_language_model.dart # Mock language data
```

---

## Screen Details

### Screen 0 — Splash

- Full orange bg (#FF7A27), centered: flower logo image, "Flowering" (white, 36px bold), "Bloom in your own way" (white 80% opacity, 15px)
- Logic: `Future.wait([Future.delayed(3s), checkToken()])`
  - Token exists → GET /users/me → 200 OK → `/home`
  - Token missing/401/error/timeout(5s) → `/onboarding/welcome`

### Screen 1A/1B/1C — Welcome Problems (data-driven)

Shared layout:
- **Top bar:** Logo (icon + "Flowering") left, "Log in" right (blue #7AACCC, no-op)
- **Step dots:** 3 dots (active=28w dark, inactive=16w light). Position varies per step.
- **Content:** Headline (34px, 800 weight) + subtext (16px, #5C5646)
- **Bottom:** "Tap anywhere to continue" (1A/1B) OR "Make it mine" CTA button (1C only)

| Step | Headline | Subtext |
|------|----------|---------|
| 1A | Your brain wasn't built to memorize. | It was built to speak. Flowering works with your brain — not against it. |
| 1B | You forget because nothing was built for you. | Generic apps give everyone the same lesson. Flowering remembers what you struggled with — and brings it back at the right moment. |
| 1C | Finally, an app that knows only you. | Your pace. Your interests. Your goals. Flowering builds a living path that evolves as you do — nobody else gets the same one. |

Navigation: 1A → tap → 1B → tap → 1C → "Make it mine" button → 2A

### Screen 2A — Native Language

- **Header:** Back button (chevron left), "What's your native language?", subtitle
- **List:** Scrollable vertical list of language cards
  - Vietnamese 🇻🇳 — selectable (default selected, orange border + check)
  - English 🇬🇧 — selectable
  - Japanese 🇯🇵, Korean 🇰🇷, Chinese 🇨🇳, Spanish 🇪🇸, French 🇫🇷 — disabled, "Soon" badge, opacity 0.5
- **Selection:** Orange border (#FF7A27), orange bg (#FFEADB), orange check circle
- **Auto-advance or continue button?** — TODO: decide (design shows no explicit button, seems like tap-to-select then auto-advance)

### Screen 2B — Learning Language

- **Header:** "What do you want to learn?", subtitle
- **Grid:** 2-column card grid
  - English 🇬🇧 — selectable (pre-selected, orange border + shadow)
  - Japanese 🇯🇵, Korean 🇰🇷, Chinese 🇨🇳, Spanish 🇪🇸, French 🇫🇷 — disabled, "Coming soon", opacity 0.5
- **Card layout:** Flag emoji (48px) + name (18px bold) + subtitle (11px)
- **After selection:** Navigate to Screen 3 (AI Chat)

---

## Route Definitions

```
/splash                        → Screen 0 (initial route, fade transition)
/onboarding/welcome            → Screen 1A
/onboarding/welcome-2          → Screen 1B
/onboarding/welcome-3          → Screen 1C
/onboarding/native-language    → Screen 2A
/onboarding/learning-language  → Screen 2B
```

All onboarding routes use `Transition.rightToLeft` (300ms).

---

## Infrastructure Changes

| File | Change |
|------|--------|
| `.env.dev` | Update `BASE_URL=https://dev.broduck.me` |
| `api_endpoints.dart` | Add `static const String userMe = '/users/me';` |
| `app-route-constants.dart` | Add onboarding route constants |
| `app-page-definitions-with-transitions.dart` | Register 6 new pages |
| `main.dart` | Change initial route from `/login` to `/splash` |

---

## Splash Flow Diagram

```
App Launch
    │
    ▼
┌─────────────────┐
│   Splash Screen  │ (3s minimum)
│   Orange BG      │
│   Logo + Brand   │
└────────┬────────┘
         │
    Future.wait([
      3s delay,
      token check
    ])
         │
         ├── Token valid (200 OK)
         │   └──▶ /home
         │
         └── No token / 401 / error / timeout(5s)
             └──▶ /onboarding/welcome (1A)
```

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| API unreachable during splash | User stuck | 5s timeout, fallback to onboarding on any error |
| Language selection not persisted | Lost on restart | Store in Hive preferences via StorageService |
| Flag emoji rendering | Platform differences | Test on both iOS/Android, fallback to text codes if needed |
| No "Continue" button on 2A | UX confusion | Auto-advance after 500ms delay on selection, or add explicit button |

---

## Unresolved Questions

- [ ] Screen 2A: Auto-advance on language tap, or add a "Continue" button?
- [ ] Should selected languages persist across app restarts (Hive) or just in-memory?
- [ ] Screen 2B → Screen 3: Should Screen 3 be a placeholder or skip to it entirely?

---

## Next Steps

1. User edits this file with adjustments
2. Create detailed implementation plan in `plans/` directory
3. Implement in phases: infra → splash → welcome → language screens → testing
