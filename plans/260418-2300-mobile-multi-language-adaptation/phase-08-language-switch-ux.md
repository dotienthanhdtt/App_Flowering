# Phase 08 — Language Switch UX

## Context Links

- Brainstorm: [brainstorm-summary.md](brainstorm-summary.md) §2 + §Success Criteria
- Backend contract: [mobile-adaptation-requirements.md §2](../../../be_flowering/plans/260418-2238-multi-language-content-architecture/mobile-adaptation-requirements.md)
- Phase 01 service, phase 05 cache invalidator, phase 06 translations, phase 07 recovery all land first.
- Scout finding: `lib/features/settings/` does NOT exist yet — this phase creates the minimum path.

## Overview

- **Priority:** P1
- **Status:** pending
- **Description:** Add a language toggle entry point (settings screen language section) that calls `PATCH /languages/user/:id` (server-side activate) then `LanguageContextService.setActive(code, id)` (local activate → triggers cache flush + ever() subscribers). Show first-switch explanatory modal. Reactive refresh of visible screens via existing `ever()` pattern.

## Key Insights

- No existing settings feature → create minimal `lib/features/settings/` folder scaffolding + one screen ("Learning languages") with a list of enrolled languages and active-toggle. Full settings hub is out of scope.
- First-switch modal shown ONCE via a `preferences` flag `first_language_switch_seen`.
- Server activation `PATCH /languages/user/:id` returns updated `UserLanguage`; local `setActive` runs AFTER successful response. On network failure, show retry toast — DO NOT optimistically flip local state (would cause cache flush + wrong-language content fetch).
- After `setActive`, `ever()` in `CacheInvalidator` flushes caches; any visible screen re-subscribing via its own `ever()` (future screens) refetches. Existing home/profile screens don't have language-scoped state yet.

## Requirements

**Functional:**
- Screen: "Learning languages" — shows list of enrolled languages (`GET /languages/user`), marks active, allows tap-to-activate.
- On tap: `PATCH /languages/user/:id` → await success → `await langCtx.setActive(code, id)` → if `first_language_switch_seen != true`, show modal with copy "Starting fresh in <NewLang>. Progress in <PrevLang> is saved separately." → set flag.
- Back to previous screen via `Get.back()`.
- Add entry point to profile screen (existing `lib/features/profile/`) — single list tile linking to this screen.
- Add new route `AppRoutes.settingsLearningLanguage` in `app-route-constants.dart` + page definition.

**Non-functional:**
- Controller extends `BaseController`; screen extends `BaseScreen<T>`.
- All user text via `.tr` with keys in both l10n files.
- Each file < 200 lines.

## Architecture

```
ProfileScreen
   │ tap "Learning language"
   ▼
SettingsLearningLanguageScreen (BaseScreen)
   │
   ▼
SettingsLearningLanguageController (BaseController)
   │ loadEnrollments: GET /languages/user
   │ setActive(id, code):
   │   apiCall(PATCH /languages/user/:id)
   │     ├─ success → langCtx.setActive(code, id)
   │     │             └─► CacheInvalidator flushes
   │     │             └─► ever() subscribers refetch
   │     │          → show first-switch modal if unseen
   │     │          → Get.back()
   │     └─ failure → showError (via BaseController)
```

## Related Code Files

**CREATE:**
- `lib/features/settings/controllers/settings-learning-language-controller.dart`
- `lib/features/settings/views/settings-learning-language-screen.dart`
- `lib/features/settings/widgets/first-language-switch-modal.dart`
- `lib/features/settings/bindings/settings-learning-language-binding.dart`

**MODIFY:**
- `lib/app/routes/app-route-constants.dart` — add `settingsLearningLanguage = '/settings/learning-language'`.
- `lib/app/routes/app-page-definitions-with-transitions.dart` — add `GetPage` entry with binding.
- `lib/l10n/english-translations-en-us.dart` + `vietnamese-translations-vi-vn.dart` — add: `settings_learning_language_title`, `settings_learning_language_subtitle`, `language_switch_modal_title`, `language_switch_modal_body`, `language_switch_modal_cta`, `err_language_switch_failed`.
- Profile screen (grep `lib/features/profile/views/*.dart` for existing settings rows) — add list tile.

**DELETE:** none.

## Implementation Steps

1. **Routes:** add `settingsLearningLanguage` constant + `GetPage(name: AppRoutes.settingsLearningLanguage, page: () => const SettingsLearningLanguageScreen(), binding: SettingsLearningLanguageBinding())`.

2. **Binding:** `Get.lazyPut<SettingsLearningLanguageController>(() => SettingsLearningLanguageController());`

3. **Controller:**
   ```dart
   class SettingsLearningLanguageController extends BaseController {
     final ApiClient _api = Get.find();
     final LanguageContextService _langCtx = Get.find();
     final StorageService _storage = Get.find();

     final enrollments = <UserLanguageDto>[].obs;

     @override
     void onInit() { super.onInit(); loadEnrollments(); }

     Future<void> loadEnrollments() async {
       await apiCall(
         () => _api.get<List<dynamic>>(ApiEndpoints.userLanguages, fromJson: (d) => d as List),
         onSuccess: (list) => enrollments.assignAll(list.map(UserLanguageDto.fromJson)),
       );
     }

     Future<void> setActive(UserLanguageDto item) async {
       await apiCall(
         () => _api.patch(ApiEndpoints.userLanguage(item.id), data: { 'isActive': true }),
         onSuccess: (_) async {
           final prevCode = _langCtx.activeCode.value;
           await _langCtx.setActive(item.language.code, item.id);
           await _maybeShowFirstSwitchModal(prevCode: prevCode, newName: item.language.name);
           Get.back();
         },
       );
     }

     Future<void> _maybeShowFirstSwitchModal({ String? prevCode, required String newName }) async {
       final seen = _storage.getPreference<bool>('first_language_switch_seen') ?? false;
       if (seen) return;
       await _storage.setPreference('first_language_switch_seen', true);
       await Get.dialog(FirstLanguageSwitchModal(newName: newName, prevCode: prevCode));
     }
   }
   ```
   (Note: `ApiClient` currently has no `.patch` helper — add one alongside existing `get`/`post`/`put`/`delete` methods. Tiny edit to `api_client.dart` — pattern identical to `put`.)

4. **Screen:** `BaseScreen<SettingsLearningLanguageController>` overriding `buildContent()` with a list rendered via `Obx(() => ListView.builder(...))`. Each tile: `AppText(item.language.name)` + active marker. Tap → `controller.setActive(item)`.

5. **First-switch modal widget:** simple `Dialog` with `AppText` title/body (using `.trParams`), `AppButton` CTA. Under 200 lines.

6. **Profile entry point:** locate existing profile settings section in `lib/features/profile/views/*.dart` (grep). Add tile: `onTap: () => Get.toNamed(AppRoutes.settingsLearningLanguage)`.

7. Translation keys (EN):
   ```dart
   'settings_learning_language_title':    'Learning languages',
   'settings_learning_language_subtitle': 'Switch which language you are learning',
   'language_switch_modal_title':         'Starting fresh in {newLang}',
   'language_switch_modal_body':          'Progress in {prevLang} is saved separately. Switch back anytime.',
   'language_switch_modal_cta':           'Got it',
   'err_language_switch_failed':          'Could not switch languages. Please try again.',
   ```
   VI mirror with placeholder copy for review.

8. `flutter analyze` clean.

## Todo List

- [ ] Routes + binding + page registered
- [ ] `PATCH` helper added to `ApiClient`
- [ ] Controller loads enrollments, performs activate + service write
- [ ] Screen renders enrollment list with active marker
- [ ] First-switch modal shown once; flag persisted
- [ ] Profile screen links into new route
- [ ] EN + VI translation keys added
- [ ] `flutter analyze` + `flutter test` clean
- [ ] Manual E2E: authed user switches from A → B → A; progress preserved per language (verified via backend)

## Success Criteria

- [ ] `PATCH /languages/user/:id` fires on tap; on success local state follows.
- [ ] Failed `PATCH` leaves local state unchanged (no optimistic flip).
- [ ] First switch shows modal; subsequent switches do not.
- [ ] Home screen content reflects new language after switch (verified by visible lesson titles changing).
- [ ] No UI jank > 1s during switch (cache flush + refetch).

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Optimistic local flip then PATCH fails | High | Await PATCH success BEFORE `setActive()`. |
| Cache flush happens mid-refetch on home screen | Medium | Flush runs first (synchronous from user's perspective); refetch fires after via ever() — natural ordering. |
| Modal shown on anonymous user accidentally | Low | Route guarded by profile entry (authed-only); additional check in controller `if (user == null) return`. |
| Copy shows raw language code instead of name | Low | Enrollment DTO includes `language.name`; use that. |

## Security Considerations

- `PATCH /languages/user/:id` is authenticated — existing JWT flow handles.
- Flag `first_language_switch_seen` stored per-install — if user uninstalls/reinstalls, modal re-appears (acceptable).

## Next Steps

- Unblocks phase 9 QA — this is the primary interaction surface to test.
