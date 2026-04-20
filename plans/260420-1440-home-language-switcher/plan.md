# Home Language Switcher — Plan Overview

**Created:** 2026-04-20
**Scope:** Update `/home` first tab (ChatHomeScreen) header to match `09_chat_screen` in `flowering_design.pen`. Replace count-pill + search icon with a language-flag button that opens a language picker and drives the `X-Learning-Language` request header.

## Design Reference

- File: `/Users/tienthanh/Dev/new_flowering/flowering_design.pen`
- Frame: `4xVNl` (09_chat_screen)
- Components reused from design system: `A444B` (BottomNavBar/ChatActive, already implemented), `QKWzO` (ScenarioCard, already implemented)

## Clarified Scope (from user)

- **Streak pill → OMITTED** (no backend streak field yet; revisit later)
- **Card component → SKIP** (existing `LanguageListCard` and `ScenarioCard` are sufficient; do not duplicate)

## Goals

1. Show active language flag + chevron in the header of `ChatHomeScreen`.
2. Tapping the button opens a language picker bottom sheet listing the user's enrolled learning languages.
3. Selecting a language persists via `LanguageContextService.setActive(code, id)`, which the existing `ActiveLanguageInterceptor` automatically applies as the `X-Learning-Language` header.
4. Trigger a lessons refetch after switch so the UI reflects the new language.

## Non-Goals

- No streak UI.
- No new card widget.
- No backend changes.
- No changes to bottom nav bar, other tabs, or lessons list/grid behavior.

## Phases

| # | File | Status | Summary |
|---|------|--------|---------|
| 1 | `phase-01-header-widgets.md` | Pending | Create `HomeLanguageButton` + `LanguagePickerSheet` widgets. |
| 2 | `phase-02-integration.md` | Pending | Replace `ChatHomeScreen` header. Add controller methods for enrolled languages + switch flow. |
| 3 | `phase-03-tests-and-l10n.md` | Pending | Add translation keys (en + vi). Widget tests. `flutter analyze` + `flutter test`. |

## Key Dependencies

- `LanguageContextService` (exists) — source of truth for active language.
- `ActiveLanguageInterceptor` (exists) — already attaches `X-Learning-Language` automatically.
- `/languages/user` endpoint (exists, used by `resyncFromServer`) — returns enrolled languages.
- `LanguageListCard` + `LanguageFlag` in `features/onboarding/widgets/language_card.dart` — reusable in picker sheet.
- `OnboardingLanguage` model — reusable (holds `id`, `code`, `flag`, `flagUrl`, `name`, `subtitle`).

## Risks / Open Questions

- Enrolled-language fetch may race with home first paint. Mitigation: show cached active code's flag immediately; fetch list lazily on first picker open.
- If user has only one enrolled language, keep button visible but make picker a no-op (show only current) — avoids surprising empty state.
- If server list is stale or empty after switching, fall back to `activeCode` from `LanguageContextService`.

## Acceptance

- Flag visible in header reflects `LanguageContextService.activeCode`.
- Picker opens on tap, lists enrolled languages, highlights active.
- Selecting a language updates `X-Learning-Language` on subsequent requests (verify via Dio logger output).
- Lessons list refetches and shows content for the newly selected language.
- `flutter analyze` clean; tests pass.
