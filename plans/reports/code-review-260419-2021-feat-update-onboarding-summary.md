# Code Review Summary — `feat/update-onboarding` (5 commits)

**Range:** `0f148155..cc1e49f6` — 32 code/test files, +1510 / −145

**Pipeline:** scout (Explore) → code-reviewer → adversarial red-team. All three stages complete.

**Source reports:**
- `plans/reports/code-reviewer-260419-2022-feat-update-onboarding-5-commits.md` (Stage 2)
- `plans/reports/code-reviewer-260419-2021-adversarial-feat-update-onboarding.md` (Stage 3)

---

## Verdict: DO NOT MERGE

6 Critical and 10+ Important issues. Merging ships token-wipe auth race, deep-link auth bypass, cross-user conversationId leak, header-injection on tamperable Hive prefs, and a cache flush that destroys 100MB on every language toggle.

---

## CRITICAL (must fix before merge)

| # | Issue | Cite | Fix |
|---|---|---|---|
| C1 | Mixed camelCase/snake_case payload — `/ai/translate`, `/onboarding/complete`. Two callers of same endpoint disagree. | `ai_chat_controller.dart:294-296, 384, 467` | Pick one casing project-wide |
| C2 | `LanguageRecoveryInterceptor._dio.fetch` re-enters full interceptor chain — cross-contaminates retry counts | `api_client.dart:37-41`, `language-recovery-interceptor.dart:44` | Use separate `retryDio` like `auth_interceptor.dart:56-60` |
| C3 | `_recovering` flag non-queued → concurrent 403 race | `language-recovery-interceptor.dart:16` | Convert to `QueuedInterceptor` |
| C4 | `clearLessonsCache` wipes entire 100MB Hive box on every language toggle | `cache-invalidator-service.dart:39-43` | Language-prefix keys; scope invalidation; move off main thread |
| C5 | `OnboardingController` `permanent:true` never disposed; `ever()` worker leaks | `onboarding_binding.dart:23-25` | Drop `permanent` or `Get.delete` on logout |
| C6 | **NEW (adversarial):** `AuthInterceptor` double-refresh race — concurrent 401s race `clearTokens()` → just-saved token wiped | `auth_interceptor.dart:41-75` | Single `Completer<bool>` gate |
| C7 | **NEW:** Header injection via tamperable Hive prefs — `activeCode` → `X-Learning-Language` unvalidated (CRLF, arbitrary strings) | `chat-home-controller.dart:49-51` | Regex-validate `^[a-z]{2,3}(-[A-Z]{2})?$` in `setActive` |
| C8 | **NEW:** Server enrollment payload `picked['code'] as String` unvalidated → flows into outbound header | `language-context-service.dart:73-84` | Regex-validate post-cast |
| C9 | **NEW:** Firebase `e.message` leaks OAuth token fragments to UI/Crashlytics | `auth_controller.dart:168-172` | Switch on `e.code` not `e.message` |

---

## IMPORTANT

1. **Deep-link/cold-resume to `/chat` bypasses `isLoggedIn` check** (`splash_controller` resume target uses `p.chat != null` alone) — auth bypass vector
2. **Cross-user `conversationId` leak** — `permanent` OnboardingController + no logout cleanup → next login sends prior user's conversationId to `/auth/register`
3. `StorageService.init` HiveError handler is unbounded recursion — boot loop on non-transient disk error
4. `CacheInvalidator._flush` doesn't update `onboarding_progress` blob → stale `learning_lang` on next cold-resume
5. `postStream` uses `String.fromCharCodes` (Latin-1) — splits multibyte UTF-8; no SSE heartbeat timeout → half-open TCP hangs `isTyping` forever
6. Splash navigation has no disposed-guard — backgrounded app on resume → Navigator stack corruption; unconditional 3s splash delay
7. `api-smoke-test.sh` — `Bearer $TOKEN` in argv visible via `ps`; no `trap … EXIT`; no `set -euo pipefail`; `mktemp` not chmodded
8. `_checkGrammar` fire-and-forget races `_rehydrateFromBackend.assignAll` → grammar result silently dropped
9. `onboarding_progress` preference key not user-namespaced → leaks across accounts on shared device pre-login
10. Language switch during in-flight `postStream` — server keeps old header while `CacheInvalidator` nukes chat box mid-stream → UI/DB divergence
11. `refetchProfileIfNeeded` fire-and-forget microtask; silent `catch(_)` → empty scenario grid, no retry
12. `LanguageContextService.resyncFromServer` returns current code on exception → defeats recovery null-check at `language-recovery-interceptor.dart:39`
13. `ChatMessage.fromServerJson` falls back to `DateTime.now()` when `created_at` null → misaligned rehydrated timeline
14. `postStream` subscription not cancelled on controller dispose
15. File-size rule violations: `ai_chat_controller.dart` 538 lines (2.7× over), `storage_service.dart` 276, `auth_controller.dart` 260

---

## ADJUDICATION

- **Scout A1** — "ActiveLanguageInterceptor added before LanguageContextService.init" → **REJECTED**. `initializeServices()` awaits `LanguageContextService.init()` (`bindings:131-132`) before `apiClient.init()` (`:159-160`), plus `Get.isRegistered` guard. Timing is correct.

---

## OBSERVABILITY GAPS (file GitHub issues, don't block merge)

- No breadcrumb on `LanguageRecoveryInterceptor` success/fail → oncall cannot diagnose 403 loops from logs alone
- `resyncFromServer` only `debugPrint`s under `kDebugMode` → release builds silent
- `CacheInvalidator._flush` emits no log of what was flushed
- No telemetry when `OnboardingProgress.fromJson` wipes on schema mismatch

---

## TEST COVERAGE GAPS

No unit tests for: `LanguageRecoveryInterceptor`, `ActiveLanguageInterceptor`, `CacheInvalidatorService`, `AuthInterceptor` refresh retry, `refetchProfileIfNeeded`. Happy-path-only on progress service. Highest ROI given C2/C3/C6 are all concurrency bugs.

---

## SUGGESTED MERGE ORDER

1. C6 (auth double-refresh) + C1 (payload casing) — ship blockers
2. C2 + C3 (recovery retryDio + queued) — security+correctness
3. C7 + C8 (header validation) — security
4. C5 + I2 (permanent controller lifecycle) — data-leak
5. C4 (scoped cache flush) — perf + I4 correctness
6. C9 (Firebase message leak) — security
7. I1 (deep-link auth gate) — security
8. Rest as cleanup pass

---

## UNRESOLVED QUESTIONS

1. Correct casing for `conversationId` on `/onboarding/complete` — camel or snake? (backend contract)
2. Should `/users/me` carry `X-Learning-Language`? (currently excluded)
3. Canonical prefix contract for language-scoped preference keys?
4. Should `OnboardingController` really be `permanent`, or route-scoped?
5. Is `X-Learning-Language` validated server-side, or are we trusting client? (determines whether C7/C8 are defence-in-depth or hard requirements)
