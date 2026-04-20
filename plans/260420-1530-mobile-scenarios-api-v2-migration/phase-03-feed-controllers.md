# Phase 03 — Feed Controllers (Flowering + For You)

## Context Links

- Phase 02 service: `lib/features/scenarios/services/scenarios_service.dart`
- Pagination pattern: `lib/features/chat/controllers/chat-home-controller.dart` (existing `_currentPage`, `_hasMore`, `_mergeCategories`)
- Base: `lib/core/base/base_controller.dart`

## Overview

- **Priority:** P0
- **Status:** completed
- **Brief:** Two lean feed controllers — one per tab. Each owns its own list, pagination cursor, refresh flag. Both listen to `LanguageContextService.activeCode` changes → refresh.

## Key Insights

- Existing `ChatHomeController` is 167 lines and does too much (lessons + language). We don't edit it here — phase 6 migrates/deletes it. Phase 4 injects the new controllers alongside.
- Split over mixin/shared base: **don't** create a shared abstract `FeedController<T>`. KISS wins; two controllers with ~80 lines of duplicated pagination is fine per DRY-reasonable threshold. If a third feed appears, revisit.
- `ever(languageCtx.activeCode, ...)` → refresh on language switch. Same pattern used by `ChatHomeController`.

## Requirements

### Functional

**`FloweringFeedController`:**
- State: `items: RxList<ScenarioFeedItem>`, `isRefreshing: RxBool`, internal `_page`, `_hasMore`.
- `onInit` → `fetchFeed()` + language-change worker.
- `fetchFeed({bool refresh = false})` — paginated; `refresh` resets cursor.
- `refreshFeed()` — sets `isRefreshing`, delegates to `fetchFeed(refresh: true)`.
- `loadMore()` — called when list near bottom; noop if `!_hasMore` or `isLoading`.

**`ForYouFeedController`:** same shape, `items: RxList<PersonalScenarioItem>`.

### Non-Functional

- Each file ≤ 150 lines.
- Both extend `BaseController` (inherits `isLoading`, `errorMessage`, `apiCall()`).
- Dispose language-change worker in `onClose`.

## Architecture

```
ChatHomeScreen (becomes HomeShell with tabs)
├── FloweringTab ──► FloweringFeedController ──► ScenariosService.getDefaultFeed
└── ForYouTab   ──► ForYouFeedController   ──► ScenariosService.getPersonalFeed
```

Bindings:
- Register both as `Get.lazyPut(...)` so they're cheap and disposed when Home unmounts.

## Related Code Files

**Create:**
- `lib/features/scenarios/controllers/flowering_feed_controller.dart`
- `lib/features/scenarios/controllers/for_you_feed_controller.dart`
- `lib/features/scenarios/bindings/scenarios_binding.dart`

**Read-only:**
- `lib/features/scenarios/services/scenarios_service.dart`
- `lib/core/services/language-context-service.dart`

## Implementation Steps

1. Create `flowering_feed_controller.dart`:
   ```dart
   class FloweringFeedController extends BaseController {
     final ScenariosService _service = Get.find<ScenariosService>();
     final LanguageContextService _langCtx = Get.find<LanguageContextService>();

     final items = <ScenarioFeedItem>[].obs;
     final isRefreshing = false.obs;
     int _page = 1;
     bool _hasMore = true;
     Worker? _langWorker;

     @override
     void onInit() {
       super.onInit();
       fetchFeed();
       _langWorker = ever<String?>(_langCtx.activeCode, (_) => fetchFeed(refresh: true));
     }

     @override
     void onClose() {
       _langWorker?.dispose();
       super.onClose();
     }

     Future<void> fetchFeed({bool refresh = false}) async {
       if (isLoading.value) return;
       if (!refresh && !_hasMore) return;
       if (refresh) { _page = 1; _hasMore = true; }

       await apiCall(
         () => _service.getDefaultFeed(page: _page, limit: 20),
         showLoading: items.isEmpty,
         onSuccess: (resp) {
           if (!resp.isSuccess || resp.data == null) {
             errorMessage.value = resp.message;
             return;
           }
           final feed = resp.data!;
           if (_page == 1) {
             items.assignAll(feed.items);
           } else {
             items.addAll(feed.items);
           }
           _hasMore = _page * feed.pagination.limit < feed.pagination.total;
           _page++;
         },
       );
     }

     Future<void> refreshFeed() async {
       if (isRefreshing.value) return;
       isRefreshing.value = true;
       try { await fetchFeed(refresh: true); }
       finally { isRefreshing.value = false; }
     }

     Future<void> loadMore() => fetchFeed();
   }
   ```
2. Create `for_you_feed_controller.dart` — identical structure, swap types and call `getPersonalFeed`.
3. Create `scenarios_binding.dart`:
   ```dart
   class ScenariosBinding extends Bindings {
     @override
     void dependencies() {
       Get.lazyPut(() => FloweringFeedController());
       Get.lazyPut(() => ForYouFeedController());
     }
   }
   ```
4. Binding is wired in phase 4 when we replace the Home tab route.

## Todo List

- [x] `flowering_feed_controller.dart` with pagination + language-worker
- [x] `for_you_feed_controller.dart` mirrored for PersonalScenarioItem
- [x] `scenarios_binding.dart` with lazyPut for both
- [x] `flutter analyze` clean on all three files

## Success Criteria

- Controllers compile, pass smoke test in phase 7 unit tests.
- Pagination cursor advances correctly; `_hasMore` flips false when total consumed.
- Language switch triggers exactly one refresh per controller (observable via HTTP logger).

## Risk Assessment

- **Re-entrancy on rapid language switches** — `isLoading` guard prevents double-fetch. Verify with stress test.
- **`ever` worker leak** — always `dispose()` in `onClose`. Phase 7 unit tests must cover.
- **Empty state vs error state** — `items.isEmpty && !isLoading && errorMessage.value.isEmpty` → empty; `errorMessage.value.isNotEmpty` → error. View distinguishes.

## Security Considerations

- None beyond service inheritance — auth + language headers handled by interceptors.

## Next Steps

- Phase 4 wires these controllers into the new Home top-tabs scaffold.
