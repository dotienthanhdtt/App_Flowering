# Phase 09 — QA Matrix + Unit/Integration Tests

## Context Links

- Brainstorm: [brainstorm-summary.md](brainstorm-summary.md) §Success Criteria
- Backend spec: [mobile-adaptation-requirements.md §9](../../../be_flowering/plans/260418-2238-multi-language-content-architecture/mobile-adaptation-requirements.md)
- All previous phases — this phase exercises them.

## Overview

- **Priority:** P0 (launch gate)
- **Status:** pending
- **Description:** Execute 8-point manual QA matrix from spec + add unit tests for `LanguageContextService`, `ActiveLanguageInterceptor`, `CacheInvalidatorService`, `detectLanguageContextError()`. One integration test for language switch flow.

## Key Insights

- Prior scout found no existing test infrastructure for Dio interceptors in repo — add minimal harness.
- `flutter test` already wired; just add under `test/` mirroring `lib/` layout.
- Integration test for switch flow uses `flutter_test` widget tester with `FlutterTestGetxBindings` (existing patterns in repo — grep before choosing).

## Requirements

**Functional (QA manual matrix — must all pass):**
1. Fresh install → language picker → onboarding → every request carries `X-Learning-Language` (verified via HTTP logger + Charles/Proxyman).
2. Authenticated user switches active language → home refetches → new lessons visible.
3. Switch A→B→A multiple times → progress preserved per language (verify via backend DB / responses).
4. Offline mode: pre-cached `/lessons` response served from cache; attempt uncached request fails gracefully.
5. Clear app data → no crashes → language picker shown on relaunch.
6. 403 "not enrolled" (simulate server-side) → app recovers via `/languages/user` resync + retry.
7. AI chat body: inspect `/onboarding/chat` and `/ai/chat/correct` requests — no `targetLanguage` / `target_language` keys.
8. Language switch while chat session open (authed) → new language header on next request; old conversation archived server-side (verify via backend).

**Functional (unit tests):**
- `LanguageContextService`:
  - `setActive` persists + emits.
  - `clear` wipes + emits null.
  - `resyncFromServer` picks active or first; returns null on empty.
- `ActiveLanguageInterceptor`:
  - Sets header on `/lessons`.
  - Skips header on `/auth/login`, `/languages`, `/users/me`, `/subscription`, `/admin`.
  - Per-request override preserved.
- `CacheInvalidatorService`:
  - First-launch flush runs exactly once.
  - Skip-first-emission works (no flush on boot with pre-existing code).
  - On change: lessons + chat boxes empty; `progress_*` preferences removed; `active_language_*` + `has_completed_login` survive.
- `detectLanguageContextError`:
  - Each of 4 backend message literals maps to correct enum.
  - Unknown message → null.

**Functional (integration test):**
- Language switch flow: simulate PATCH success → assert `activeCode` updated + invalidator fired + first-switch flag set + subsequent switch does not show modal.

**Non-functional:**
- Test files < 200 lines; split by concern if needed.
- All tests pass locally on `flutter test`.

## Architecture

Test layout:
```
test/
├── core/
│   ├── services/
│   │   ├── language-context-service-test.dart
│   │   └── cache-invalidator-service-test.dart
│   └── network/
│       ├── active-language-interceptor-test.dart
│       └── language-context-error-test.dart
└── features/
    └── settings/
        └── settings-learning-language-flow-test.dart  (integration)
```

## Related Code Files

**CREATE (tests):**
- `test/core/services/language-context-service-test.dart`
- `test/core/services/cache-invalidator-service-test.dart`
- `test/core/network/active-language-interceptor-test.dart`
- `test/core/network/language-context-error-test.dart`
- `test/features/settings/settings-learning-language-flow-test.dart`

**MODIFY:** none (production code unchanged — tests drive from outside).

## Implementation Steps

1. **Unit tests — LanguageContextService:**
   - Setup: `Hive.initFlutter()` in `setUpAll`, use `Hive.init(Directory.systemTemp)` pattern; mock `StorageService` or use a real in-memory instance.
   - Tests: construct → init → setActive → assert `activeCode.value == 'en'` + Hive persisted → new instance → init → still `'en'`.
   - `resyncFromServer` test: mock Dio via `DioMock` / use `MockAdapter` from `dio` test helpers. Return fixture with `isActive: true` on the second entry → assert picked. Empty list → assert null return + clear emitted.

2. **Unit tests — ActiveLanguageInterceptor:**
   - Construct `Dio()` with only this interceptor + a mock adapter that echoes headers.
   - Register real `LanguageContextService` in Get, pre-seeded with `'fr'`.
   - Table test: `['/lessons', '/ai/chat', '/vocabulary']` → header set; `['/auth/login', '/languages', '/users/me', '/subscription/me', '/admin/foo']` → header absent.
   - Override case: request options with explicit header → interceptor leaves it untouched.

3. **Unit tests — CacheInvalidatorService:**
   - Temp Hive dir; real `StorageService.init()`.
   - Seed `lessons_cache` + `chat_cache` with a value; seed `preferences.progress_xyz` + `preferences.has_completed_login`.
   - Construct `LanguageContextService`, seed `activeCode.value = 'en'`.
   - Init `CacheInvalidatorService` → first-launch flag missing → flush runs → assert boxes empty, `progress_*` gone, `has_completed_login` preserved.
   - Second init (flag now true) → no flush.
   - Set new code → flush fires again.

4. **Unit tests — detectLanguageContextError:**
   - Table test over 4 literals + 2 negative cases.

5. **Integration test — Settings switch flow:**
   - Pump `SettingsLearningLanguageScreen` with mocked `ApiClient` (Dio mock adapter returning success for PATCH).
   - Tap a language tile → await → assert controller's `langCtx.activeCode.value` updated, invalidator ran (assert `lessons_cache` empty), first-switch modal appeared.
   - Second tap → assert modal NOT reshown.

6. Run `flutter test` — all green.

7. Execute manual QA matrix (8 items) against staging backend build. Record results in a checklist at the bottom of this phase doc as they pass.

## Todo List

- [ ] `language-context-service-test.dart` — 4 tests
- [ ] `active-language-interceptor-test.dart` — 3 tests (path matrix, skip matrix, override)
- [ ] `cache-invalidator-service-test.dart` — 4 tests (first-launch, idempotent, switch-flush, preserved-keys)
- [ ] `language-context-error-test.dart` — 6 tests
- [ ] `settings-learning-language-flow-test.dart` — integration
- [ ] `flutter test` passes
- [ ] `flutter analyze` clean
- [ ] Manual QA matrix: all 8 items pass on staging
- [ ] Log manual QA outcomes inline here

## Success Criteria

- [ ] 100% of unit tests pass.
- [ ] Integration test reliably passes (no flakes over 5 consecutive runs).
- [ ] All 8 QA matrix items documented as pass/fail with timestamp + tester.
- [ ] No test uses real network — fully mocked.

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Hive test setup flaky | Medium | Use `setUp`/`tearDown` to create/clean temp dir; isolate per test. |
| Dio mock adapter behavior differs from real | Low | Phase 9 validates mocks; real flow validated via manual QA items 1, 6, 7, 8. |
| Manual QA blocked by backend staging not yet deployed | High | Gate phase 9 on backend deploy complete; phase 1-8 implementation can land earlier on feature branch. |

## Security Considerations

- Tests avoid real tokens; use stub `AuthStorage` returning fake bearer.

## Next Steps

- After green: ready for code review + merge.
- Phase 10 (version gating) can merge in parallel since it's orthogonal to this test set.
