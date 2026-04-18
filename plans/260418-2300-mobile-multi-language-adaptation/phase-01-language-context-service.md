# Phase 01 — LanguageContextService

## Context Links

- Brainstorm: [brainstorm-summary.md](brainstorm-summary.md) §1 + §Final Architecture
- Backend contract: [mobile-adaptation-requirements.md §1](../../../be_flowering/plans/260418-2238-multi-language-content-architecture/mobile-adaptation-requirements.md)
- Referenced files: `lib/core/services/storage_service.dart`, `lib/app/global-dependency-injection-bindings.dart`, `lib/core/network/api_client.dart`

## Overview

- **Priority:** P0 (blocks phases 2-5, 7, 8)
- **Status:** pending
- **Description:** New `LanguageContextService extends GetxService` — single source of truth for active learning language code + id, persisted to Hive `preferences` box. Exposes reactive `RxnString` observables for `ever()` subscribers.

## Key Insights

- Onboarding controller currently owns `selectedLearningLanguage` but disposes post-onboarding → cannot be long-lived SoT.
- `StorageService` must stay domain-agnostic — do NOT add language-specific helpers there.
- Service init MUST run before `ApiClient.init` so the interceptor (phase 2) never sees a null service during boot.
- Persistence keys reused across restarts; naming locked to `active_language_code` + `active_language_id` for interceptor + storage consistency.

## Requirements

**Functional:**
- Expose `activeCode: RxnString` and `activeId: RxnString`.
- `setActive(String code, String? id)` persists both and emits.
- `clear()` wipes both and emits null (used on logout).
- `resyncFromServer()` calls `GET /languages/user`, picks the `isActive: true` entry or first entry, persists it. Returns the picked code, or null if user has no enrollments.
- On `init()`, hydrate from Hive preferences.

**Non-functional:**
- File under 200 lines (target ~120).
- No network call in `init()` — pure read from Hive. Network resync triggered explicitly (phase 7 / first-launch in phase 5).
- Thread-safe: Hive write awaited before `activeCode.value =` assignment so a crash mid-write leaves old-or-new state, never inconsistent.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ LanguageContextService (GetxService, permanent)     │
│  ─────────────────────────────────────────────────  │
│  activeCode: RxnString  ──► ever() subscribers      │
│  activeId:   RxnString                              │
│                                                     │
│  setActive(code, id)  ─► Hive.preferences.put       │
│                         └► activeCode.value = code  │
│  clear()              ─► Hive.preferences.delete    │
│                         └► activeCode.value = null  │
│  resyncFromServer()   ─► GET /languages/user        │
│                         └► setActive(picked)        │
└─────────────────────────────────────────────────────┘
           ▲                         ▲
           │ read                    │ DI: ApiClient (phase 2)
           │ StorageService          │
           │ (preferences box)
```

Hive keys (in `preferences` box):
- `active_language_code` → String (e.g. `"en"`)
- `active_language_id` → String (UUID; nullable for anonymous onboarding pre-enrollment)

## Related Code Files

**CREATE:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/services/language-context-service.dart`

**MODIFY:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/app/global-dependency-injection-bindings.dart` — register service; init between `StorageService` and `ApiClient`.

**DELETE:** none.

## Implementation Steps

1. Create `lib/core/services/language-context-service.dart`:
   - Import `package:get/get.dart`, `storage_service.dart`, `api_client.dart`, `api_endpoints.dart`.
   - Class `LanguageContextService extends GetxService`.
   - Hive key constants:
     ```dart
     static const String _codeKey = 'active_language_code';
     static const String _idKey   = 'active_language_id';
     ```
   - `final activeCode = RxnString();` and `final activeId = RxnString();`
   - `Future<LanguageContextService> init() async { final s = Get.find<StorageService>(); activeCode.value = s.getPreference<String>(_codeKey); activeId.value = s.getPreference<String>(_idKey); return this; }`
   - `Future<void> setActive(String code, String? id) async { ... await put ... ; activeCode.value = code; activeId.value = id; }`
   - `Future<void> clear() async { await remove both; activeCode.value = null; activeId.value = null; }`
   - `Future<String?> resyncFromServer()`:
     - `final api = Get.find<ApiClient>();`
     - `final resp = await api.get<List<dynamic>>(ApiEndpoints.userLanguages, fromJson: (d) => d as List);`
     - Iterate response items; pick `isActive == true`, else first.
     - If found → `await setActive(picked.code, picked.id)` → return code.
     - If empty → `await clear()` → return null.
     - Wrap in try/catch; on failure, log and return current `activeCode.value`.
   - Keep file under 200 lines; extract helper `_pickFromEnrollments(List)` if needed.

2. In `lib/app/global-dependency-injection-bindings.dart`:
   - `AppBindings.dependencies()`: add `Get.lazyPut<LanguageContextService>(() => LanguageContextService(), fenix: true);`
   - `initializeServices()`: after `StorageService` init, BEFORE `ApiClient.init`, add:
     ```dart
     final languageContext = Get.put(LanguageContextService());
     await languageContext.init();
     ```
   - Keep comment stating init order rationale.

3. Run `flutter analyze` — expect zero errors.

## Todo List

- [ ] Create `language-context-service.dart` (< 200 lines)
- [ ] Register in `AppBindings.dependencies()` (lazy + fenix)
- [ ] Init between `StorageService` and `ApiClient` in `initializeServices()`
- [ ] Verify `flutter analyze` clean
- [ ] Smoke test: on first launch, `activeCode.value == null`
- [ ] Smoke test: after `setActive('en', 'uuid')`, relaunch → `activeCode.value == 'en'`

## Success Criteria

- [ ] Service compiles, registered, initialized in correct order.
- [ ] Observable emits on `setActive` (verified by temporary `ever()` print in dev).
- [ ] Hive persistence round-trips across app restarts.
- [ ] `resyncFromServer()` handles empty enrollments without throwing.

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Init order mistake crashes interceptor | High | Explicit sequence in `initializeServices()`; phase 2 assertion logs and skips header if service missing. |
| Hive write failure leaves stale observable | Low | `await` write before assigning observable. |
| `GET /languages/user` response shape shift | Medium | Use `fromJson` defensively; verify against `be_flowering/src/modules/language/dto/user-language.dto.ts`. |

## Security Considerations

- No auth tokens handled here — `AuthInterceptor` owns those.
- `activeCode`/`activeId` are user-scoped but not sensitive; Hive box is not encrypted.

## Next Steps

- Unblocks: phase 2 (interceptor reads from this service), phase 3 (onboarding ctrl delegates), phase 5 (cache invalidator subscribes via `ever()`).
- Follow-up: phase 3 migrates onboarding ctrl writes to call `setActive()`.
