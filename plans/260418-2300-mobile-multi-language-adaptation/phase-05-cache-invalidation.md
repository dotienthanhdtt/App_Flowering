# Phase 05 — CacheInvalidator

## Context Links

- Brainstorm: [brainstorm-summary.md](brainstorm-summary.md) §2 + §Cache Flush on Switch
- Referenced files: `lib/core/services/storage_service.dart`, `lib/app/global-dependency-injection-bindings.dart`, phase 01 service
- Spec: [mobile-adaptation-requirements.md §7](../../../be_flowering/plans/260418-2238-multi-language-content-architecture/mobile-adaptation-requirements.md)

## Overview

- **Priority:** P0
- **Status:** done
- **Description:** `CacheInvalidator` service subscribes to `ever(activeCode)` and flushes language-scoped caches on every change. Also performs a one-time flush on first launch of the updated app version for existing installs with pre-partition cache.

## Key Insights

- Per brainstorm §2: flush-on-switch chosen over keyed Hive boxes (avoids migration complexity).
- Current codebase has `lessons_cache`, `lessons_access`, `chat_cache`, `preferences` boxes. `chat_cache` currently holds anonymous onboarding chat messages; post-onboarding, authenticated chat may reuse it — clear on switch is correct.
- Preserve keys: `active_language_code`, `active_language_id`, `has_completed_login`, auth tokens (in `AuthStorage` separately — not in `preferences`).
- First-launch flush triggered by comparing `preferences.last_lang_migration_version` to current version constant; if mismatch, flush once and bump.
- Controllers self-clear their own RxList/RxMap on `ever()` — brainstorm §5 rejected an enumerated `.clear()` controller list. This service handles **storage** only.

## Requirements

**Functional:**
- Subscribe to `LanguageContextService.activeCode` via `ever()` in `onInit()`.
- On change (except first emission mirroring the already-persisted code on boot): call `_flushLanguageScopedBoxes()`.
- `_flushLanguageScopedBoxes()`:
  - `await storageService.clearLessonsCache()` (covers `lessons_cache` + `lessons_access`)
  - `await storageService.clearChatCache()`
  - Walk `preferences` keys; delete any starting with `progress_` or `attempt_` (if present).
- One-time first-launch flush: check `preferences.lang_migration_v1_done`; if false, run `_flushLanguageScopedBoxes()` and set flag true.
- `init()` is idempotent and non-blocking for the rest of the boot.

**Non-functional:**
- Target file ~100 lines; under 200.
- No network calls inside invalidator (pure storage).
- Ever() listener disposed on `onClose()`.

## Architecture

```
┌────────────────────────────────────┐
│ LanguageContextService.activeCode  │
└───────────────┬────────────────────┘
                │ ever()
                ▼
      ┌────────────────────────┐
      │ CacheInvalidator       │
      │  - skipFirstEmission   │
      │  - flushOnChange       │
      └─────────┬──────────────┘
                │ reads
                ▼
      ┌────────────────────────┐
      │ StorageService         │
      │  clearLessonsCache()   │
      │  clearChatCache()      │
      │  removePreference(*)   │
      └────────────────────────┘

Boot path (once per install after upgrade):
  init() → check `lang_migration_v1_done` → if false → flushLanguageScopedBoxes()
         → set flag true
```

## Related Code Files

**CREATE:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/services/cache-invalidator-service.dart`

**MODIFY:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/app/global-dependency-injection-bindings.dart` — register + init after `LanguageContextService`, before `ApiClient`.
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/services/storage_service.dart` — add helper `Iterable<String> preferenceKeysMatching(bool Function(String) test)` so invalidator doesn't reach into Hive directly. Also add `Future<void> removePreferencesMatching(bool Function(String) test)`. Keep domain-agnostic (accept predicate).

## Implementation Steps

1. Extend `storage_service.dart`:
   ```dart
   /// Returns all preference keys matching [test].
   Iterable<String> preferenceKeysMatching(bool Function(String) test) =>
       _preferences.keys.cast<String>().where(test);

   /// Deletes all preference keys matching [test].
   Future<void> removePreferencesMatching(bool Function(String) test) async {
     final keys = preferenceKeysMatching(test).toList();
     for (final k in keys) { await _preferences.delete(k); }
   }
   ```
   Keep file < 200 lines (currently 265 — already over; flag as debt but add these two small helpers only).

2. Create `lib/core/services/cache-invalidator-service.dart`:
   ```dart
   class CacheInvalidatorService extends GetxService {
     static const _migrationFlag = 'lang_migration_v1_done';
     Worker? _worker;
     bool _seeded = false;

     Future<CacheInvalidatorService> init() async {
       final storage = Get.find<StorageService>();
       final langCtx = Get.find<LanguageContextService>();

       // One-time flush for existing installs pre-partition.
       final done = storage.getPreference<bool>(_migrationFlag) ?? false;
       if (!done) {
         await _flush(storage);
         await storage.setPreference(_migrationFlag, true);
       }

       _worker = ever<String?>(langCtx.activeCode, (code) async {
         if (!_seeded) { _seeded = true; return; } // skip boot mirror
         await _flush(storage);
       });
       _seeded = true; // prevent double-fire if activeCode null at boot
       return this;
     }

     Future<void> _flush(StorageService s) async {
       await s.clearLessonsCache();
       await s.clearChatCache();
       await s.removePreferencesMatching(
         (k) => k.startsWith('progress_') || k.startsWith('attempt_'),
       );
     }

     @override
     void onClose() { _worker?.dispose(); super.onClose(); }
   }
   ```

3. Register in `AppBindings.dependencies()`:
   ```dart
   Get.lazyPut<CacheInvalidatorService>(() => CacheInvalidatorService(), fenix: true);
   ```
   In `initializeServices()` (after `LanguageContextService` init, before `ApiClient.init`):
   ```dart
   final cacheInvalidator = Get.put(CacheInvalidatorService());
   await cacheInvalidator.init();
   ```

4. Verify `has_completed_login` and `active_language_*` are preserved by `_flush` (they don't match `progress_*` / `attempt_*` prefixes, and `clearLessonsCache`/`clearChatCache` only touch those boxes — `preferences` is NOT wholesale cleared).

5. `flutter analyze` clean. Manual test: set active code to `en`, save a fake `progress_lesson1` pref, switch to `es`, verify pref deleted but `active_language_code`/`has_completed_login` survive.

## Todo List

- [ ] Add `preferenceKeysMatching` + `removePreferencesMatching` to `StorageService`
- [ ] Create `cache-invalidator-service.dart` with first-launch flush + ever() listener
- [ ] Register + init in global bindings (after language ctx, before ApiClient)
- [ ] First-launch flag `lang_migration_v1_done` set after first flush
- [ ] Skip-first-emission logic prevents boot flush of fresh install
- [ ] Smoke test: switch languages → lessons/chat boxes empty, auth + language keys preserved
- [ ] `flutter analyze` clean

## Success Criteria

- [ ] On language switch: `lessons_cache`, `lessons_access`, `chat_cache` boxes empty.
- [ ] `preferences` box: `progress_*` and `attempt_*` keys removed.
- [ ] Preserved keys: `active_language_code`, `active_language_id`, `has_completed_login`, `lang_migration_v1_done`.
- [ ] Fresh install (no active code) → no unnecessary flush.
- [ ] Upgrade from pre-feature version → flush runs exactly once.

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Flush runs on every boot (listener fires on init) | High | `_seeded` gate + explicit "skip first emission" comment. |
| `removePreferencesMatching` deletes auth-related keys | High | `AuthStorage` uses a separate Hive box — not in `preferences`. Double-check via grep on `preferences` keys used app-wide. |
| `chat_cache` clear wipes in-flight onboarding chat checkpoint | Medium | `OnboardingProgressService` persists to `preferences` (key `onboarding_progress`), NOT `chat_cache`. Verify during implementation. |
| Storage service file exceeds 200 lines further | Low | Accepted debt; two helpers only. Future refactor tracked separately. |

## Security Considerations

- Auth tokens in separate `AuthStorage` box — unaffected by this phase.
- No credentials in cleared caches.

## Next Steps

- Unblocks phase 7 (403 resync triggers `setActive` which in turn triggers flush + retry).
- Unblocks phase 8 (switch UX relies on flush for the "starting fresh" copy to be accurate).
