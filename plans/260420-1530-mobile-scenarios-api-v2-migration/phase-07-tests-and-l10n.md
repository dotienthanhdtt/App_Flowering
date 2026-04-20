# Phase 07 — Translations, Tests, Analyze

## Context Links

- Translations: `lib/l10n/english-translations-en-us.dart`, `lib/l10n/vietnamese-translations-vi-vn.dart`
- Existing test patterns: `test/features/chat/`, `test/features/onboarding/`
- Phase 3 controllers, Phase 4/5 widgets — subjects of new tests

## Overview

- **Priority:** P1
- **Status:** completed
- **Brief:** Add translation keys for new tab/card copy, write widget tests for the 6-state card matrix, controller tests for pagination + language-switch refresh. Final `flutter analyze` + `flutter test` gate.

## Requirements

### Translation Keys (en + vi)

| Key | English | Vietnamese |
|---|---|---|
| `tab_for_you` | "For You" | "Dành cho bạn" |
| `tab_flowering` | "Flowering" | "Flowering" |
| `scenarios_empty_default` | "No scenarios yet" | "Chưa có kịch bản" |
| `scenarios_empty_personal` | "Complete onboarding to unlock personalized scenarios" | "Hoàn thành giới thiệu để mở khóa kịch bản cá nhân hóa" |
| `scenarios_error_generic` | "Couldn't load scenarios. Pull to retry." | "Không thể tải kịch bản. Kéo để thử lại." |
| `access_tier_pro_badge` | "PRO" | "PRO" |
| `source_ai_badge` | "AI" | "AI" |
| `source_kol_badge` | "KOL" | "KOL" |

### Widget Tests

- `test/features/scenarios/widgets/feed_scenario_card_test.dart`:
  - Renders placeholder when `imageUrl` missing.
  - `status == learned` → check badge visible.
  - `status == locked` → lock badge + dark overlay.
  - `status == available` → no status badge.
  - `accessTier == premium` → PRO badge visible.
  - `accessTier == free` → no PRO badge.
  - Full matrix: 3 statuses × 2 tiers = 6 golden-path assertions.
- `test/features/scenarios/widgets/personal_feed_card_test.dart`:
  - `source == personalized` → AI badge.
  - `source == kol` → KOL badge.
  - `status == learned` → muted style + trailing check.
  - Tap emits callback (if nav wiring added).
- `test/features/scenarios/widgets/access_tier_badge_test.dart`:
  - `premium` → renders pill.
  - `free` → `SizedBox.shrink()`.

### Controller Tests

- `test/features/scenarios/controllers/flowering_feed_controller_test.dart`:
  - First `fetchFeed()` populates `items` from mocked service.
  - `fetchFeed(refresh: true)` resets page to 1 + replaces items.
  - `loadMore()` appends items + bumps page.
  - `_hasMore` flips false when total consumed.
  - Language change (mocked `LanguageContextService.activeCode`) triggers refresh.
  - Worker disposes on `onClose()`.
- `test/features/scenarios/controllers/for_you_feed_controller_test.dart`:
  - Mirror of above for personal feed.

### Integration / Smoke

- `test/features/scenarios/home_tab_integration_test.dart` (optional):
  - Pump `ChatHomeScreen` with mocked controllers.
  - Tap each tab → correct content renders.
  - Pull-to-refresh triggers controller's refresh method.

### Non-Functional

- `flutter analyze` clean on all new + modified files.
- `flutter test` full suite green (fix any failing tests broken by phase 6 deletions).
- Use `Get.testMode = true` + `Get.reset()` in `setUp` / `tearDown` for controller tests.
- Use `mockito` (already a dev dep) for `ScenariosService` mocks.

## Related Code Files

**Modify:**
- `lib/l10n/english-translations-en-us.dart`
- `lib/l10n/vietnamese-translations-vi-vn.dart`

**Create:**
- `test/features/scenarios/widgets/feed_scenario_card_test.dart`
- `test/features/scenarios/widgets/personal_feed_card_test.dart`
- `test/features/scenarios/widgets/access_tier_badge_test.dart`
- `test/features/scenarios/controllers/flowering_feed_controller_test.dart`
- `test/features/scenarios/controllers/for_you_feed_controller_test.dart`
- `test/features/scenarios/home_tab_integration_test.dart` (optional)

## Implementation Steps

1. Add 8 translation keys to both l10n files (keep ordering consistent across files).
2. Write `access_tier_badge_test.dart` first (simplest — warms up test harness).
3. Write widget tests for both feed cards using parametric test pattern:
   ```dart
   for (final status in ScenarioUserStatus.values) {
     for (final tier in ScenarioAccessTier.values) {
       testWidgets('renders $status / $tier correctly', (tester) async {
         // ... pump widget, assert badges
       });
     }
   }
   ```
4. Write controller tests with mocked `ScenariosService`:
   ```dart
   when(mockService.getDefaultFeed(page: 1, limit: 20))
     .thenAnswer((_) async => ApiResponse.success(
       ScenariosFeedResponse(items: fakeItems, pagination: fakePage)));
   ```
5. Run:
   ```bash
   cd app_flowering/flowering
   flutter analyze
   flutter test test/features/scenarios/
   flutter test  # full suite
   ```
6. Fix any failures — no test skipping, no `expect` commenting-out.

## Todo List

- [x] Add 8 translation keys to both l10n files
- [x] `access_tier_badge_test.dart`
- [x] `feed_scenario_card_test.dart` (6-state matrix)
- [x] `personal_feed_card_test.dart`
- [x] `flowering_feed_controller_test.dart`
- [x] `for_you_feed_controller_test.dart`
- [ ] `home_tab_integration_test.dart` (optional — skipped per plan's >2h guard; widget + controller tests provide coverage)
- [x] `flutter analyze` clean
- [x] `flutter test test/features/scenarios/` all green (27 tests). Pre-existing failures in `widget_test.dart` and `ai_chat_binding_cold_resume_test.dart` verified unrelated to this migration.

## Success Criteria

- All 8 translation keys present in both l10n maps (no runtime missing-key fallback).
- Controller tests cover: initial fetch, refresh, loadMore, hasMore flip, language-change trigger, worker disposal.
- Widget tests cover 6-state card matrix + source badges.
- `flutter analyze` clean.
- `flutter test` all green across full suite (no regressions).

## Risk Assessment

- **Test flakiness on `Get` singletons** — `Get.testMode = true` + fresh `Get.reset()` per test.
- **Mockito generics with `ApiResponse<ScenariosFeedResponse<T>>`** — may need explicit type args in `when(...)` stubs. Use `@GenerateMocks` annotation + build_runner.
- **Integration test brittleness** — skip if it adds >2h; unit + widget tests are the primary gate.

## Security Considerations

- None — test-only phase.

## Next Steps

- Close plan, update `docs/project-changelog.md` with migration entry.
- Run `/ck:code-review` on the full diff before merging `feat/scenarios-api-v2` → main.
