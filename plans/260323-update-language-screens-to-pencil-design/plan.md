# Update Language Selection Screens to Match Pencil Design

## Summary
Update screens 06 (native language) and 07 (target/learning language) to match the Pencil design file.

## Status: Complete

---

## Phases

| # | Phase | Status | Effort |
|---|-------|--------|--------|
| 1 | Update Screen 06 — Native Language | Complete | Medium |
| 2 | Update Screen 07 — Learning Language | Complete | Medium |

## Key Design Differences

### Screen 06 — Native Language (`native_language_screen.dart`)

| Aspect | Current Code | Pencil Design |
|--------|-------------|---------------|
| Back button | Styled container with chevron_left | **None** — no back button |
| Title | "native_language_title" + subtitle | "What language do you speak?" only, no subtitle |
| Search field | Missing | Search input with "Search language..." placeholder |
| Card flag size | 40px (`avatarM`) | 36px circle |
| Card padding | horizontal 16 | all-sides 12 |
| Card gap (between elements) | 12 | 16 |
| Card height | fixed 64 | auto (fit content) |
| Cards list gap | 12 (`space3`) | 8 |
| Chevron icon | Missing | chevron-right icon (#545F71) |
| Horizontal padding | 24 (`space6`) | 16 |
| Bottom padding | None explicit | 34px safe area |

### Screen 07 — Learning Language (`learning_language_screen.dart`)

| Aspect | Current Code | Pencil Design |
|--------|-------------|---------------|
| Layout | **GridView** (2 columns) | **ListView** (list cards) |
| Back button | None | Arrow-left icon in top bar |
| Title | "language_select_title" + subtitle | "What language do you want to learn?" only |
| Card style | Grid card (image centered, stacked) | List card (row: 48px image, text, chevron) |
| Card padding | 20 (`space5`) | 16 |
| Card gap (between elements) | N/A grid | 16 |
| Cards list gap | N/A grid | 10 |
| Show all button | Missing | "Show all languages" + chevron-down |
| Continue button | Missing | Orange #FD9029, h52, opacity 0.5, cornerRadius 12 |
| Navigation | Auto-navigate on tap (400ms delay) | Manual via Continue button |

## Dependencies
- `language_card.dart` — shared widget, needs update
- `onboarding_controller.dart` — needs changes for screen 07 (remove auto-nav, add continue action)
- Translation files — update keys

## Files to Modify
- `lib/features/onboarding/views/native_language_screen.dart`
- `lib/features/onboarding/views/learning_language_screen.dart`
- `lib/features/onboarding/widgets/language_card.dart`
- `lib/features/onboarding/controllers/onboarding_controller.dart`
- `lib/l10n/english-translations-en-us.dart`
- `lib/l10n/vietnamese-translations-vi-vn.dart`
