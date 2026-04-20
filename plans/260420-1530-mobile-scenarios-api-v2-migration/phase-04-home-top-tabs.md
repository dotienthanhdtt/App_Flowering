# Phase 04 — Home Top-Tabs Restructure

## Context Links

- Current home: `lib/features/chat/views/chat-home-screen.dart` (170+ lines, owns header + body)
- Current controller: `lib/features/chat/controllers/chat-home-controller.dart`
- Existing header widgets (keep): `lib/features/chat/widgets/home-language-button.dart`, `lib/features/chat/widgets/language-picker-sheet.dart`
- Phase 03 controllers: `FloweringFeedController`, `ForYouFeedController`

## Overview

- **Priority:** P0
- **Status:** completed
- **Brief:** Insert a `TabBar` + `TabBarView` between the existing header and body. Header (language flag) stays at top. Old category-grouped body migrates into a new `FloweringTab` widget that consumes the new flat-feed controller. Add `ForYouTab` alongside.

## Key Insights

- Existing `ChatHomeScreen` is registered as a tab child inside `main-shell-screen.dart` (bottom nav IndexedStack). It does NOT have its own Scaffold — per `CLAUDE.md`, tab children avoid nested Scaffold.
- `DefaultTabController` is the least-ceremony way to host two tabs. Alternative: `TabController` owned by a state widget — overkill here.
- Keep `AutomaticKeepAliveClientMixin` on each tab widget to prevent state loss when user flips between For You / Flowering.
- Language-switch is handled by controllers via `ever()` (phase 3) — no tab-level wiring needed.

## Requirements

### Functional

- `ChatHomeScreen` layout:
  ```
  SafeArea
  └── Column
      ├── Header (existing, unchanged)
      ├── TabBar ("For You" | "Flowering")
      └── Expanded(TabBarView)
          ├── ForYouTab
          └── FloweringTab
  ```
- Tab bar visual: underline indicator, text-only tabs (icons optional — skip for V1 simplicity).
- Default tab: `Flowering` (index 1) — preserves historical landing UX.
- Both tabs:
  - Pull-to-refresh via `PullToRefreshList`
  - Infinite scroll — fire `loadMore()` near bottom
  - Empty state widget
  - Error state widget
- `ForYouTab` cards: text-only (icon + title + difficulty + source badge).
- `FloweringTab` cards: thumbnail + title + difficulty + access_tier badge (existing `ScenarioCard` adapted OR new widget — see phase 5).
- `ChatHomeController` stays in place for V1 — only responsible for language header state (already does this). The body-related logic (`categories`, `fetchLessons`, `_mergeCategories`) becomes unused; deletion in phase 6.

### Non-Functional

- `ChatHomeScreen` file ≤ 200 lines after edit (currently ~110 — OK).
- New tab widgets each ≤ 200 lines.
- `DefaultTabController(length: 2, initialIndex: 1, child: ...)`.
- Bindings: update `lib/features/chat/bindings/chat-home-binding.dart` to also register `ScenariosBinding` dependencies (or merge).

## Architecture

```
main-shell-screen.dart (bottom nav, unchanged)
└── ChatHomeScreen (modified)
    ├── [Header row] — HomeLanguageButton + spacer (unchanged)
    ├── [TabBar]     — For You | Flowering
    └── [TabBarView]
        ├── ForYouTab     → ForYouFeedController → ScenariosService.getPersonalFeed
        └── FloweringTab  → FloweringFeedController → ScenariosService.getDefaultFeed
```

## Related Code Files

**Modify:**
- `lib/features/chat/views/chat-home-screen.dart` — add TabBar + TabBarView, stop rendering old category list.
- `lib/features/chat/bindings/chat-home-binding.dart` — add lazyPut for both feed controllers (or compose via `ScenariosBinding`).

**Create:**
- `lib/features/scenarios/views/for_you_tab.dart`
- `lib/features/scenarios/views/flowering_tab.dart`
- `lib/features/scenarios/widgets/feed_scenario_card.dart` (thumbnail card — used in Flowering)
- `lib/features/scenarios/widgets/personal_feed_card.dart` (text-only — used in For You)
- `lib/features/scenarios/widgets/source_badge.dart` (small pill for `personalized` / `kol`)

**No change:**
- `lib/features/chat/widgets/home-language-button.dart`
- `lib/features/chat/widgets/language-picker-sheet.dart`
- `lib/features/home/views/main-shell-screen.dart` — bottom nav untouched.

## Implementation Steps

1. Add translation keys (en + vi) — included in phase 7, but use placeholders `tab_for_you`, `tab_flowering` here.
2. Create `feed_scenario_card.dart`:
   - Reuse image + frosted overlay from existing `ScenarioCard` (copy — DO NOT inherit, they'll diverge on `access_tier` vs `status` badges).
   - Takes `ScenarioFeedItem` directly.
   - Renders `access_tier == premium` badge in top-right when applicable.
   - Status: `learned` → check, `locked` → lock + dark overlay, `available` → no badge.
3. Create `personal_feed_card.dart`:
   - Horizontal row: icon circle (accent color from hash of id or fixed) + column(title, difficulty + source badge).
   - No thumbnail — text-only per brainstorm decision.
   - Tap → navigate to scenario detail (route TBD; wire same as current `ScenarioCard` navigation).
4. Create `source_badge.dart`:
   - Tiny pill: `AI` for `personalized`, `KOL` for `kol`.
   - Distinct colors (primary vs accent).
5. Create `flowering_tab.dart`:
   - `StatefulWidget` + `AutomaticKeepAliveClientMixin` (keep alive across tab switches).
   - `Get.find<FloweringFeedController>()`.
   - `GridView.builder` (2 cols) with `NotificationListener<ScrollNotification>` to trigger `loadMore()` within 300px of bottom.
   - Wrap in `PullToRefreshList` equivalent for grid (use `RefreshIndicator` if `PullToRefreshList` is list-only).
   - Empty state: `'scenarios_empty_default'.tr`.
   - Error state: `errorMessage.value` visible with retry button.
6. Create `for_you_tab.dart`:
   - Same scaffold; `ListView.separated` instead of grid.
   - Empty state: `'scenarios_empty_personal'.tr` with copy about completing onboarding.
7. Modify `chat-home-screen.dart`:
   - Wrap body in `DefaultTabController(length: 2, initialIndex: 1, child: Column([...]))`.
   - Replace `_buildBody` with `TabBarView([ForYouTab(), FloweringTab()])`.
   - Delete `_buildEmptyState`, `_buildCategorySection` helpers (dead code post-migration) — or leave for phase 6 to avoid muddying this phase's diff. **Decision: leave stale helpers in place; phase 6 deletes.**
8. Update `chat-home-binding.dart`:
   ```dart
   class ChatHomeBinding extends Bindings {
     @override
     void dependencies() {
       Get.lazyPut(() => ChatHomeController());
       Get.lazyPut(() => FloweringFeedController());
       Get.lazyPut(() => ForYouFeedController());
     }
   }
   ```
9. Run app manually:
   - Tap flag → picker → switch language → both tabs refetch with new `X-Learning-Language`.
   - Swipe between tabs → state preserved.
   - Pull-to-refresh on each tab → list reloads.

## Todo List

- [x] `feed_scenario_card.dart` (with access_tier premium badge)
- [x] `personal_feed_card.dart` (text-only row)
- [x] `source_badge.dart`
- [x] `flowering_tab.dart` (grid + keep-alive + pagination)
- [x] `for_you_tab.dart` (list + keep-alive + pagination)
- [x] Modify `chat-home-screen.dart` → insert TabBar + TabBarView
- [x] Update `main-shell-binding.dart` → register feed controllers (no separate `chat-home-binding.dart` exists in this project)
- [ ] Manual test: tab switching, pull-to-refresh, pagination, language switch (requires running device; automated coverage in phase 7)
- [x] `flutter analyze` clean

## Success Criteria

- Home renders two tabs under the language header.
- Both tabs paginate independently.
- Language switch triggers refresh on whichever tab is visible AND on re-entry to the hidden one.
- Scroll position preserved across tab swaps.
- Old categories-grouped list no longer renders (dead body code kept for phase 6 cleanup).

## Risk Assessment

- **TabBar styling drift from design** — defer pixel-perfect alignment to a follow-up. V1 uses Material defaults.
- **KeepAlive memory** — two tab states held indefinitely while on Home. Acceptable for 2 tabs; revisit if we add more.
- **`FloweringFeedController` double-init** — `lazyPut` guards; if manually `Get.put` elsewhere, instance is reused.
- **Pull-to-refresh on GridView** — wrap in `RefreshIndicator` (not `PullToRefreshList` if that widget expects ListView). Verify.

## Security Considerations

- None. UI-only phase; data flow unchanged from phase 3.

## Next Steps

- Phase 5 updates card rendering for new `status`/`access_tier` semantics.
- Phase 6 deletes dead `/lessons` flow from `ChatHomeController`.
