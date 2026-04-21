# Phase 2 — Flutter: Scenario Detail Screen + Navigation

## Context Links

- Design: Pencil node `Zi0sT` (`10_scenario_detail`) in `flowering_design.pen`
- Brainstorm: [../reports/brainstorm-2026-04-21-scenario-detail.md](../reports/brainstorm-2026-04-21-scenario-detail.md)
- Phase 1: [phase-01-backend-detail-endpoint.md](phase-01-backend-detail-endpoint.md)
- Current feed tabs: `lib/features/scenarios/views/flowering_tab.dart`, `lib/features/scenarios/views/for_you_tab.dart`
- Feed cards (already have `onTap` slot, unused): `lib/features/scenarios/widgets/feed_scenario_card.dart`, `lib/features/scenarios/widgets/personal_feed_card.dart`
- Paywall: `lib/features/subscription/widgets/paywall-bottom-sheet.dart` (`PaywallBottomSheet.show()`)
- Feed service pattern: `lib/features/scenarios/services/scenarios_service.dart`
- Route definitions: `lib/app/routes/app-route-constants.dart`, `lib/app/routes/app-page-definitions-with-transitions.dart`

## Overview

**Priority:** P1
**Status:** complete
**Blocked by:** None
**Effort:** 4h

Build the scenario detail screen matching design `10_scenario_detail`. Wire tap handlers on both feed cards, fetch detail on open, render CTA whose behavior maps from server state.

## Key Insights

- `FeedScenarioCard.onTap` / `PersonalFeedCard.onTap` are already parameters — wiring requires only updating the two tab builders.
- Detail screen has 4 states: loading, success-unlocked, success-locked, error (404 / network). Lay these out explicitly; don't collapse into a generic error view without retry.
- Language switch mid-view: controller pops back to feed (user was viewing a scenario that may not exist in the new language). Mirror `FloweringFeedController._langWorker` pattern.
- `PaywallBottomSheet.show()` returns `Future<bool>`. On `true`, refetch detail so CTA flips.
- CTA implementation: a dedicated widget `ScenarioDetailCta` with 3 variants so the screen stays small.
- No cache on the detail service call (user decision).

## Requirements

### Functional
- Route: `/scenarios/detail` with `arguments: {'id': '<uuid>'}`.
- Tap on `FeedScenarioCard` (Flowering tab) or `PersonalFeedCard` (For-You tab) → navigate.
- On open: show loading, fetch detail, render.
- Hero image 300px height, full-width, uses `CachedNetworkImage` with placeholder.
- Bottom CTA full-width primary button.
- CTA label + action:
  | `userStatus` | `isLocked` | Label | Action |
  |---|---|---|---|
  | `available` | false | `scenario_detail_cta_start` | Navigate to scenario chat |
  | `learned` | false | `scenario_detail_cta_practice_again` | Navigate to scenario chat (forceNew) |
  | `locked` | true | `scenario_detail_cta_upgrade` | Open PaywallBottomSheet; refetch on success |
- Back arrow → `Get.back()`.
- 404 → inline `EmptyOrErrorView` with retry.
- Active-language change → pop back to feed.

### Non-functional
- Controller extends `BaseController`; screen extends `BaseScreen<ScenarioDetailController>`.
- All user-facing text via `.tr`.
- Uses `AppText`, `AppButton` (not raw widgets).
- Files ≤ 200 lines each (split if needed).
- Kebab-case file names (`scenario_detail_screen.dart` matches existing convention elsewhere, but convention for new files is snake_case — follow the existing `features/scenarios/` style).
- No new packages.

## Architecture

```
Feed card tap
    │
    ▼
Get.toNamed('/scenarios/detail', arguments: { id })
    │
    ▼
ScenarioDetailBinding → put(ScenarioDetailController(scenarioId))
    │
    ▼
ScenarioDetailScreen (BaseScreen<ScenarioDetailController>)
    │
    ├─► TopBar (back + 'scenario_detail_title'.tr)
    ├─► Divider
    ├─► Content (scroll):
    │     ├─► HeroImage (300px, CachedNetworkImage)
    │     └─► Info (title + description)
    ├─► Divider
    └─► BottomBar: ScenarioDetailCta(detail)
          │
          ├─ available → Get.toNamed('/scenario-chat', arguments: {...})
          ├─ learned   → Get.toNamed('/scenario-chat', arguments: {..., forceNew: true})
          └─ locked    → PaywallBottomSheet.show() → if true, controller.refresh()
```

## Data Flow

```
ScenarioDetailController.onInit
    └─► apiCall(service.getScenarioDetail(id))
        └─► detail.value = data
```

## Related Code Files

**Create:**
- `lib/features/scenarios/models/scenario_detail.dart`
- `lib/features/scenarios/models/scenario_category_ref.dart` (tiny value type, or inline)
- `lib/features/scenarios/controllers/scenario_detail_controller.dart`
- `lib/features/scenarios/bindings/scenario_detail_binding.dart`
- `lib/features/scenarios/views/scenario_detail_screen.dart`
- `lib/features/scenarios/widgets/scenario_detail_cta.dart`
- `lib/features/scenarios/widgets/scenario_hero_image.dart` (optional split if screen > 200 lines)

**Modify:**
- `lib/features/scenarios/services/scenarios_service.dart` — add `getScenarioDetail(String id)` method (NO cacheTtl).
- `lib/features/scenarios/views/flowering_tab.dart:88` — pass `onTap` to `FeedScenarioCard`.
- `lib/features/scenarios/views/for_you_tab.dart:84` — pass `onTap` to `PersonalFeedCard`.
- `lib/app/routes/app-route-constants.dart` — add `scenarioDetail = '/scenarios/detail'`.
- `lib/app/routes/app-page-definitions-with-transitions.dart` — register detail page with binding.
- `lib/l10n/english-translations-en-us.dart` + `lib/l10n/vietnamese-translations-vi-vn.dart` — add 6 keys (see below).

## Implementation Steps

1. **Model.**
   ```dart
   class ScenarioDetail {
     final String id;
     final String title;
     final String description;
     final String? imageUrl;
     final String difficulty;
     final String languageId;
     final int orderIndex;
     final ScenarioCategoryRef category;
     final ScenarioAccessTier accessTier;
     final bool isLocked;
     final String? lockReason;          // 'premium_required' when locked
     final ScenarioUserStatus userStatus; // reuse existing enum
     // const ctor + fromJson
   }
   ```
   `fromJson` accepts both snake_case + camelCase (mirror `ScenarioFeedItem`).

2. **Service method** in `scenarios_service.dart`:
   ```dart
   Future<ApiResponse<ScenarioDetail>> getScenarioDetail(String id) {
     return _apiClient.get<ScenarioDetail>(
       '${ApiEndpoints.scenarios}/$id',
       fromJson: (data) => ScenarioDetail.fromJson(data as Map<String, dynamic>),
       // no cacheTtl — fresh fetch every call
     );
   }
   ```
   Add `ApiEndpoints.scenarios = '/scenarios'` if not already present.

3. **Controller** (`scenario_detail_controller.dart`):
   ```dart
   class ScenarioDetailController extends BaseController {
     ScenarioDetailController(this.scenarioId);
     final String scenarioId;

     final _service = Get.find<ScenariosService>();
     final _langCtx = Get.find<LanguageContextService>();
     Worker? _langWorker;

     final detail = Rxn<ScenarioDetail>();
     final notFound = false.obs;

     @override
     void onInit() {
       super.onInit();
       fetch();
       _langWorker = ever<String?>(_langCtx.activeCode, (_) {
         if (Get.currentRoute == AppRoutes.scenarioDetail) Get.back();
       });
     }

     @override
     void onClose() {
       _langWorker?.dispose();
       super.onClose();
     }

     Future<void> fetch() async {
       notFound.value = false;
       await apiCall(
         () => _service.getScenarioDetail(scenarioId),
         showLoading: detail.value == null,
         onSuccess: (resp) {
           if (!resp.isSuccess || resp.data == null) {
             notFound.value = resp.statusCode == 404;
             errorMessage.value = resp.message;
             return;
           }
           detail.value = resp.data;
         },
       );
     }

     Future<void> onCtaTapped() async { /* see widget */ }
   }
   ```

4. **Binding** (`scenario_detail_binding.dart`):
   ```dart
   class ScenarioDetailBinding extends Bindings {
     @override
     void dependencies() {
       final args = Get.arguments as Map?;
       final id = args?['id'] as String? ?? '';
       Get.lazyPut(() => ScenarioDetailController(id));
     }
   }
   ```

5. **Screen** (`scenario_detail_screen.dart`) extends `BaseScreen<ScenarioDetailController>`. Structure:
   - Top bar: `Row(back IconButton, AppText title, Spacer)` — height 56, padding [0, 16].
   - Divider: `Container(height: 1, color: AppColors.dividerColor)`.
   - `Expanded(SingleChildScrollView(Column([HeroImage, InfoSection])))`.
   - Divider.
   - Bottom bar: `Container(padding: [12, 20], child: ScenarioDetailCta(...))`.
   - Obx branches: loading / error / detail.

6. **CTA widget** (`scenario_detail_cta.dart`):
   ```dart
   class ScenarioDetailCta extends StatelessWidget {
     final ScenarioDetail detail;
     final VoidCallback onStart;
     final VoidCallback onPracticeAgain;
     final VoidCallback onUpgrade;

     @override
     Widget build(BuildContext context) {
       if (detail.isLocked) {
         return AppButton(label: 'scenario_detail_cta_upgrade'.tr, onPressed: onUpgrade, ...);
       }
       if (detail.userStatus == ScenarioUserStatus.learned) {
         return AppButton(label: 'scenario_detail_cta_practice_again'.tr, onPressed: onPracticeAgain, ...);
       }
       return AppButton(label: 'scenario_detail_cta_start'.tr, onPressed: onStart, ...);
     }
   }
   ```

7. **Paywall + refetch.** In controller:
   ```dart
   Future<void> openPaywall() async {
     final purchased = await PaywallBottomSheet.show();
     if (purchased) await fetch();
   }
   ```

8. **Wire feed taps:**
   - `flowering_tab.dart:88`: `FeedScenarioCard(item: items[i], onTap: () => Get.toNamed(AppRoutes.scenarioDetail, arguments: {'id': items[i].id}))`.
   - `for_you_tab.dart:84`: same pattern on `PersonalFeedCard`.

9. **Route registration:**
   - `AppRoutes.scenarioDetail = '/scenarios/detail';`
   - Add `GetPage(name: AppRoutes.scenarioDetail, page: () => const ScenarioDetailScreen(), binding: ScenarioDetailBinding(), transition: AppRouteTransitionConfig.defaultTransition)`.

10. **Translations** (add to both en-us + vi-vn):
    - `scenario_detail_title`: "Scenario" / "Kịch bản"
    - `scenario_detail_cta_start`: "Start Conversation" / "Bắt đầu hội thoại"
    - `scenario_detail_cta_practice_again`: "Practice Again" / "Luyện lại"
    - `scenario_detail_cta_upgrade`: "Upgrade to Unlock" / "Nâng cấp để mở khóa"
    - `scenario_detail_not_found`: "Scenario not found" / "Không tìm thấy kịch bản"
    - `scenario_detail_error_generic`: "Could not load scenario" / "Không thể tải kịch bản"

11. **Temporary CTA target for `onStart` / `onPracticeAgain`:**
    - Until Phase 3 lands, both navigate to a TODO toast: `Get.snackbar('TODO', 'Scenario chat coming in phase 3')`.
    - Phase 3 replaces with real `Get.toNamed(AppRoutes.scenarioChat, arguments: {...})`.

12. **Compile + smoke test:** `flutter analyze` on touched files clean; run app; tap a scenario; verify all 3 CTA states with a seeded dataset.

## Todo List

- [ ] Create `scenario_detail.dart` model + `fromJson`
- [ ] Add `getScenarioDetail` to `scenarios_service.dart` (no cache)
- [ ] Create `scenario_detail_controller.dart` with language-switch back-nav
- [ ] Create `scenario_detail_binding.dart`
- [ ] Create `scenario_detail_screen.dart` extending `BaseScreen`
- [ ] Create `scenario_detail_cta.dart` widget
- [ ] Wire `onTap` in `flowering_tab.dart` + `for_you_tab.dart`
- [ ] Add `scenarioDetail` route + registration
- [ ] Add 6 translation keys (en-us + vi-vn)
- [ ] `flutter analyze` clean on touched files
- [ ] Manual QA: free available, free learned, premium locked, premium unlocked, 404

## Success Criteria

- [ ] Tap from both tabs opens detail.
- [ ] CTA copy matches state matrix.
- [ ] Paywall opens on locked; success refetches and flips CTA.
- [ ] 404 renders error view with retry; retry recovers.
- [ ] Language switch pops back to feed.
- [ ] No raw `Text` / `ElevatedButton` used in new files.
- [ ] No file exceeds 200 lines.

## Risk Assessment

- **Binding arg extraction** — if `Get.arguments` is null (e.g. hot-reload), controller falls through with empty ID → API returns 404 → user sees error view. Acceptable.
- **Image load flicker** — `CachedNetworkImage` + placeholder + fadeInDuration same as feed card.
- **Back-nav from paywall** — if user cancels paywall, `purchased = false`, no refetch, CTA unchanged. Correct behavior.
- **Double-tap navigation** — feed cards may fire `onTap` twice during navigation transition. Guard with `if (!Get.isDialogOpen!) Get.toNamed(...)` or rely on framework.

## Security Considerations

- Never trust feed-provided state for gating; CTA must only read `detail.value?.isLocked` / `userStatus` from the authoritative detail fetch.
- No raw JSON parsing — use `fromJson` with null-safe fallbacks like existing models.

## Next Steps

Phase 3 replaces the TODO snackbar with real scenario-chat navigation.
