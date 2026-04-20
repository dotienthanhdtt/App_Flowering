# Phase 07 — Shared Widgets & Dead Code

## Context Links
- `research/researcher-03-code-structure.md` D1-D3, M1-M5, X1-X2

## Overview
- **Priority:** P3 (maintainability, not performance)
- **Status:** pending
- **Effort:** ~2h

Extract duplicated patterns into shared widgets; replace raw Text/ElevatedButton with AppText/AppButton where project rule demands; delete dead code.

## Key Insights
- Only extract when the pattern actually appears 2+ times (DRY, not speculative).
- Raw `Text` / `ElevatedButton` violations are local — fix per file rather than inventing new widgets.
- `audio_service.dart` (282 lines) appears unused — verify and delete in Phase 03. This phase cleans remainder.

## Requirements

**Functional**
- No behavior change.

**Non-functional**
- Duplicated code de-duplicated (only where 2+ call sites exist).
- All user-facing text uses `AppText`.
- All branded buttons use `AppButton` (except native platform buttons like `SignInWithAppleButton`).

## Architecture

```
lib/shared/widgets/
├─ infinite_scroll_list.dart      NEW — wraps ListView.builder/GridView.builder + load-more
├─ empty_or_error_view.dart       NEW — icon + message + retry
└─ cached-scenario-image.dart     NEW (if Phase 01 didn't already create it)
```

## Related Code Files

**Create**
- `lib/shared/widgets/empty_or_error_view.dart`
- `lib/shared/widgets/infinite_scroll_list.dart` (optional — only if 2+ call sites still need it after Phase 02 restructure)

**Modify — replace raw widgets with shared ones**
- `lib/features/scenarios/views/flowering_tab.dart` — use EmptyOrErrorView
- `lib/features/scenarios/views/for_you_tab.dart` — use EmptyOrErrorView
- `lib/features/subscription/views/paywall-screen.dart` — AppText + AppButton + EmptyOrErrorView
- `lib/features/subscription/widgets/paywall-bottom-sheet.dart` — AppButton
- `lib/features/subscription/widgets/paywall-bottom-actions-widget.dart` — AppButton
- `lib/features/onboarding/views/welcome-back-screen.dart` — AppButton
- `lib/features/onboarding/views/onboarding-welcome-screen.dart` — AppButton
- `lib/features/scenarios/widgets/feed_scenario_card.dart` — AppText for title
- `lib/app/routes/app-page-definitions-with-transitions.dart` `_PlaceholderScreen` — AppText + AppButton

**Delete (verify first)**
- `lib/core/services/audio_service.dart` (if not already deleted in Phase 03)

## Implementation Steps

1. Create `empty_or_error_view.dart` with signature `EmptyOrErrorView({required IconData icon, required String message, VoidCallback? onRetry, String? retryLabel})`.
2. Replace `_EmptyOrError` private widgets in `flowering_tab.dart` and `for_you_tab.dart` with the shared widget.
3. Sweep raw `Text` → `AppText` in listed screens. Style params map: `fontSize`/`fontWeight`/`color`/`variant`.
4. Sweep raw `ElevatedButton` → `AppButton`. If `AppButton` lacks `icon` support and the caller needs it, either extend `AppButton` with optional `icon` slot OR keep `ElevatedButton.icon` in one-off cases with a doc comment.
5. If Phase 01 extracted `CachedScenarioImage`, confirm both card files use it.
6. Verify `audio_service.dart` deletion: grep for `audio_service` (not `audio/`), confirm zero references.
7. `flutter analyze` + smoke test visual parity.

## Todo List
- [ ] Create `empty_or_error_view.dart` shared widget
- [ ] Replace `_EmptyOrError` duplicates in feed tabs
- [ ] Replace raw `Text` with `AppText` in paywall, onboarding welcome/welcome-back
- [ ] Replace raw `ElevatedButton` with `AppButton` where branded styling expected
- [ ] Extend `AppButton` with optional `icon` slot if 3+ call sites need it (else inline OutlinedButton.icon)
- [ ] Replace `feed_scenario_card.dart` raw Text with AppText
- [ ] Replace `_PlaceholderScreen` raw widgets with App* versions
- [ ] Delete `audio_service.dart` if unreferenced
- [ ] `flutter analyze` clean
- [ ] Visual diff on each touched screen

## Success Criteria
- Zero `Text(` occurrences in screens (excluding places using `RichText.TextSpan`).
- No lint/analyze new warnings.
- Feeds show identical empty/error state to before.
- Deleted file does not break build.

## Risk Assessment
- **Risk**: `AppText` doesn't support some niche style — add that param (variant) rather than falling back to Text.
- **Risk**: `AppButton` doesn't support icons natively — option to inline exception or extend.
- **Risk**: `audio_service.dart` referenced in a test we didn't see — running tests will flag.

## Security Considerations
- None.

## Next Steps
- Phase 08 verification wrap-up.
