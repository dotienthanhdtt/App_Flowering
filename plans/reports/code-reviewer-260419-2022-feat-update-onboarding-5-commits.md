# Code Review — feat/update-onboarding (5 commits)

Scope: `git diff 0f148155..cc1e49f6` — 32 files (~1510 / −145)
Focus: interceptors, cold-resume, DI/GetX, translations, security, perf, tests

## Critical

### C1. API body-key casing inconsistency — broken request contract
`lib/features/chat/ai_chat_controller.dart:294-296, 384, 467`
After migrating `/auth/register`, `/auth/login`, and `/chat/correct` to camelCase (`conversationId`, `userMessage`, `targetLanguage`), three payloads were left in snake_case:
- `/ai/translate` (line 294-296): `source_lang`, `target_lang`, `conversation_id`
- `onWordTap` / word-translation endpoint (line 384): `conversation_id`
- `/onboarding/complete` (line 467): `'conversation_id': _conversationId`
The smoke script (`scripts/api-smoke-test.sh:110`) confirms server expects `sourceLang`/`targetLang`. On a server that enforces DTO shape, sentence translation and `/onboarding/complete` will silently drop the `conversationId` or 400. Note that `refetchProfileIfNeeded` in `onboarding_controller.dart:178` already uses the correct snake_case `conversation_id` for `/onboarding/complete` — so the two callers of the same endpoint disagree. Pick one; suspect backend wants `conversationId` (matches auth). **Fix:** unify all `/onboarding/complete` + `/ai/translate` payload keys to camelCase and align `refetchProfileIfNeeded`.

### C2. Retry interceptor bypasses language-recovery on 5xx retries
`lib/core/network/api_client.dart:37-41` + `retry_interceptor.dart:41`
Registration order is `RetryInterceptor → AuthInterceptor → ActiveLanguageInterceptor → LanguageRecoveryInterceptor`. `RetryInterceptor.fetch(err.requestOptions)` re-enters the full interceptor chain — good for 5xx. But `LanguageRecoveryInterceptor._dio.fetch(opts)` (line 44) also re-enters RetryInterceptor, which itself may retry a 5xx that happens on the recovery fetch, potentially spamming `/languages/user`. More critically: if the original request is retried by RetryInterceptor (5xx → retry → 403 not-enrolled), the language recovery runs on the retry attempt, `opts.extra[_retryFlag] = true`, and **the retry is NOT re-retried by RetryInterceptor** because `_retry_count` already got bumped — this is fine. But the real bug is: when LanguageRecovery's retry returns 5xx, the RetryInterceptor sees `_retryFlag == true` but no `_retry_count` increment from itself for the *new* request flow, and will retry; meanwhile the language flag is still set, blocking re-recovery. Net effect: retry cascade works but every code path should verify: **Fix:** add `opts.extra['_retry_count'] = 0` reset before `_dio.fetch` in language-recovery OR skip recovery retry from re-entering RetryInterceptor (use `retryDio` pattern like `auth_interceptor.dart:56-60`).

### C3. `_recovering` flag on `LanguageRecoveryInterceptor` is not concurrency-safe
`lib/core/network/language-recovery-interceptor.dart:16, 36, 48`
Plain `bool` field; two simultaneous 403s both check `!_recovering`, both see `false`, both enter. In Dart single-isolate this is only safe if set synchronously before any `await` — which it is (line 36 before `await Get.find...resyncFromServer()`), so this is OK in practice. But the `finally` unsets it before `handler.resolve/next` completes, so if a *second* 403 arrives while the resolved retry is still in-flight, it too will attempt resync. Acceptable, but the class should either be a `QueuedInterceptor` (like `AuthInterceptor`) to serialize 403s, or use an in-flight `Completer` so concurrent 403s share the single resync outcome. **Fix:** convert to `QueuedInterceptor` for symmetry with auth.

### C4. `clearLessonsCache` fires on every language switch — destroys offline lesson library
`lib/core/services/cache-invalidator-service.dart:39-43`
Flushing the entire 100 MB lessons box and all chat cache on every language toggle will wreck UX for multi-language learners and cause large Hive writes on UI thread (Hive is single-writer). The caches are language-partitioned per the API contract (server returns language-specific content), but the *keys* in `lessons_cache` include the language already. Scoped invalidation (delete keys starting with `lang_<oldcode>_`) is safer and respects the 100 MB investment. **Fix:** make cache keys language-prefixed in `StorageService` and only delete matching keys on switch. At minimum, measure the flush cost and move off the main isolate. Also: `progress_`/`attempt_` prefix filter silently assumes every future feature uses that prefix — document the contract or centralize.

### C5. `CacheInvalidatorService.init` seeding race — first real switch may be dropped
`lib/core/services/cache-invalidator-service.dart:25-36`
`ever(...)` fires asynchronously; `_seeded = true` at line 35 runs synchronously before the first emission lands. If `activeCode` changes during `init()` itself (e.g. legacy migration set a code after `Get.find<LanguageContextService>()` but before `ever` registers), the callback will fire with the new code and — because `_seeded == true` already — trigger a flush. Since the post-migration `languageContext.init()` completes before cache-invalidator init (see `global-dependency-injection-bindings.dart:136-141`), this is probably benign today but fragile. **Fix:** capture baseline code synchronously (`_baselineCode = langCtx.activeCode.value`) and in the callback skip when `code == _baselineCode`. Drop the `_seeded` boolean entirely.

### C6. `OnboardingController` registered with `fenix: true` via AiChatBinding — duplicate lifecycle vs `permanent: true`
`lib/features/chat/bindings/ai_chat_binding.dart:7-12` + `onboarding_binding.dart:23-25`
`OnboardingBinding.dependencies()` uses `Get.put(..., permanent: true)` — so on cold-resume via `AiChatBinding → OnboardingBinding`, the controller is permanent. After successful auth, the CLAUDE.md rule says "Call `Get.delete<OnboardingController>()` after successful auth." Grepping shows no such call exists anywhere. Net effect: the controller, its `Worker` subscription to `_langCtx.activeCode`, and its timer continue to live after onboarding completes, leaking memory and keeping the `ever` worker active for the session lifetime. **Fix:** add `Get.delete<OnboardingController>(force: true)` inside `AuthController._processAuthResponse` (after `Get.offAllNamed(home)`), AND in `AiChatController._finalizeOnboarding` on the non-auth path.

## Important

### I1. Async button handlers not awaited — navigation races with persistence
`lib/features/onboarding/views/learning_language_screen.dart:26-27`, `native_language_screen.dart:26`
The callback is `(lang) => controller.selectLearningLanguage(lang.code, id: lang.id)`, fire-and-forget. `selectLearningLanguage` is now `async`, and its internal `_langCtx.setActive` + `_progress.setLearningLang` are awaited *before* the 50 ms timer navigates. But if the user backs out or the widget rebuilds between await points, the unawaited Future survives the tree. More importantly: `Future.microtask(refetchProfileIfNeeded)` in `onboarding_controller.dart:66` is fire-and-forget — if it fails, `isRefetchingProfile` stays false and the empty scenario grid is shown. **Fix:** callbacks stay sync but the controller already awaits properly; just add error-state UI for the rehydrate failure path so users aren't stuck with empty grid.

### I2. Silent swallowing in `refetchProfileIfNeeded` + no retry affordance
`lib/features/onboarding/controllers/onboarding_controller.dart:176-188`
`catch (_)` hides every failure (network, 401, 5xx). `isRefetchingProfile` flips off and `onboardingProfile` stays null; `_ScenarioGrid` renders an empty grid with no error message and no retry. This is a dead-end screen for cold-resume users on flaky network. **Fix:** mirror `AiChatController._rehydrateFromBackend` (use `on ApiException`), surface `errorMessage.value`, render `ScenarioGiftScreen` with a retry button reusing the `err_language_required` / `resume_chat_failed` pattern.

### I3. `LanguageContextService.resyncFromServer` silently no-ops on error, blocking recovery
`lib/core/services/language-context-service.dart:58-69`
On `catch`, it returns the *current* `activeCode.value` (not null). `LanguageRecoveryInterceptor:38-40` reads: `if (newCode == null) return handler.next(err);` — so recovery will always proceed to retry with the SAME code that just got a 403, re-hitting the same 403, which the `_retryFlag` then blocks. Net: no recovery, just an extra request. **Fix:** on exception return `null` so the caller skips retry.

### I4. `scripts/api-smoke-test.sh` uses `set -u`-incompatible patterns but no `set -euo pipefail`
`scripts/api-smoke-test.sh:11`
No `set -euo pipefail` at top. Multiple `${VAR:-}` with missing pipefail means a failing `jq` inside a pipe silently yields empty strings and the pass/fail report can mislead. PASS count incremented even when `body_msg` parse errored. **Fix:** add `set -uo pipefail` after shebang. Not `-e` because the script already tracks failures manually.

### I5. Login-gate shown only when `hasCompletedLogin`, but cold-resume to `/chat` bypasses this gate
`lib/features/onboarding/controllers/splash_controller.dart:46-55`
If a user never completed login (fresh install), they reach `computeOnboardingResumeTarget`. If a malicious or stale `onboarding_progress` map says `profileComplete: true`, they jump to `scenarioGift` and see `_showLoginGate` via CTA — fine. But if the app was killed right after `_progress.setLearningLang` but before chat loaded, they resume at `/chat` with an anonymous session and `AiChatController._bootstrapSession` reads `chat == null` → `_createSession()` → anonymous `/onboarding/chat` without `X-Learning-Language` (skipped per `ActiveLanguageInterceptor._skipPrefixes`). That's correct, just verifying — **no fix needed**, but add an integration comment.

### I6. `AuthController` grows to 260 lines, exceeds 200-line rule; `ai_chat_controller.dart` is 538
`lib/features/auth/controllers/auth_controller.dart` (260), `lib/features/chat/controllers/ai_chat_controller.dart` (538)
Project CLAUDE.md mandates <200 lines/file. AiChatController is 2.7× over. Extract: rehydrate logic → `_chat_rehydrate_mixin.dart` or service, translation/correction helpers → `chat-ai-utils-service.dart`. AuthController: extract overlay helpers and social-auth branch. **Fix:** split before merge; 538 lines is beyond the threshold for any future change to be reviewable.

### I7. `_showLoadingOverlay` uses `Get.back()` to dismiss — races with user-dismissed dialogs
`lib/features/auth/controllers/auth_controller.dart:215-224`
`Get.isDialogOpen` is a best-effort flag; if any other dialog (error snackbar upgraded to dialog, or permission prompt) opened between show/hide, `Get.back()` will pop the wrong thing — e.g. dismiss the underlying screen. **Fix:** keep a `BuildContext? _overlayContext` captured from `Get.dialog` future and call `Navigator.of(_overlayContext).pop()` only if still mounted; or use the existing `BaseScreen` loading overlay already inherited from `BaseController.isLoading` by triggering it via a second `showOverlay` observable.

### I8. `chat_message_model.ChatMessage.fromServerJson` doesn't validate or sanitize `content`
`lib/features/chat/models/chat_message_model.dart:30-48`
Server `content` is piped straight into the UI. If backend accidentally includes markdown/HTML, the `word-tap` parser (`ai_chat_controller.dart:325`) does clean quoting, but any rich-text widget downstream would render it raw. Not a critical bug today, but recommended to strip control chars and cap length at the model layer (defensive). **Fix:** add a `_sanitize(content)` helper that strips ANSI / control chars; limit to e.g. 8 KB.

### I9. `ActiveLanguageInterceptor` skips `/users/me` — but profile controller writes user lang
`lib/core/network/active-language-interceptor.dart:11-14`
`/users/me` is skipped from the header, so profile updates never propagate the active language to the server. If the backend uses `X-Learning-Language` as a hint when editing profile (e.g. to tag audit logs), that context is lost. **Fix:** verify with backend whether `PATCH /users/me` wants the header; if yes, remove from skip list.

### I10. Legacy `onboarding_conversation_id` migration only deletes key, doesn't touch actual cached lesson data tied to it
`lib/features/onboarding/services/onboarding_progress_service.dart:25-36`
Migration is `setChatConversationId(legacy); remove legacy`. No verification that `legacy` is a valid UUID; a corrupt non-UUID string will be silently persisted into the new format. **Fix:** regex validate UUID before migrating; else remove legacy and skip.

## Nice-to-have

### N1. `detectLanguageContextError` relies on server message string matching
`lib/core/network/api_exceptions.dart:185-196`
`m.contains('not enrolled')` and `'unknown or inactive language code'` are fragile — any server i18n or minor wording change breaks recovery. **Fix:** ask backend for a stable error code (`error_code: "LANG_NOT_ENROLLED"`) in response payload. Track as backend contract requirement.

### N2. `OnboardingProgress.schemaVersion = 1` but no migration on version bump
`lib/features/onboarding/models/onboarding_progress_model.dart:7, 22`
Currently: version mismatch → treat as empty → user restarts onboarding. That's data loss, not migration. Fine for v1→v2 in testing, hostile to prod users. **Fix:** add a `_migrate(json, fromVersion)` hook before returning empty.

### N3. `OnboardingProgressService` uses `print` in `kDebugMode` blocks — should be `debugPrint`
`onboarding_progress_service.dart:38, 54` — minor consistency with rest of codebase which uses `debugPrint`.

### N4. `LanguageRecoveryInterceptor` logs via `print` only in `kDebugMode`, same
`language-recovery-interceptor.dart:46` — fine, but inconsistent.

### N5. Test: `ai_chat_binding_cold_resume_test.dart:42` instantiates real `ApiClient`
`test/features/chat/bindings/ai_chat_binding_cold_resume_test.dart:42`
`Get.put<ApiClient>(ApiClient());` without calling `.init()` works only because `OnboardingBinding` doesn't touch it synchronously — but this is brittle. Any future controller added to `OnboardingBinding` that reads `Get.find<ApiClient>()._dio` crashes the test. **Fix:** register a `_FakeApiClient` stub.

### N6. Test coverage gap: no test for `LanguageRecoveryInterceptor` 403 retry, resync failure, or re-entry guard
No tests for `language-recovery-interceptor.dart`, `active-language-interceptor.dart`, or `cache-invalidator-service.dart`. Given C2/C3/C5 exist, these are the highest-ROI tests to add. **Fix:** mock Dio + LanguageContextService, assert single retry, no recursion on persistent 403, skip when not registered.

### N7. Test coverage gap: `refetchProfileIfNeeded` untested despite being the only cold-resume scenario-gift path
No unit test for `OnboardingController.refetchProfileIfNeeded`. Given I2 silent-failure bug, regression risk is high.

### N8. `permanent: true` + worker in `OnboardingController.onClose` — `onClose` never runs for permanent controllers
`onboarding_controller.dart:186-191`
`onClose` disposes the `_langCtxWorker`, but `permanent: true` means `onClose` is only called if `Get.delete(force: true)` is called. See C6. **Fix:** couples with C6 — explicit delete after auth.

### N9. Import ordering
`lib/features/auth/controllers/auth_controller.dart:10` — `'../../../shared/widgets/loading_widget.dart'` interleaved between core imports. Per CLAUDE.md: Flutter/Dart → external → internal. Minor.

### N10. `lib/core/services/storage_service.dart` at 276 lines, over 200-line rule.
Already over; N8 added 30 more lines. Consider splitting the cache-eviction logic into `storage-eviction-policy.dart`.

### N11. Translation parity present; but `err_language_not_enrolled` uses `"` quote type mixed
English value `"You haven't enrolled in this language yet."` uses double-quoted string (no escape needed), consistent with nearby entries. No issue. Flag only because single-quoted strings elsewhere use `\'`.

## Unresolved Questions

1. Does backend `/onboarding/complete` actually accept `conversationId` or `conversation_id`? (C1 resolution hinges on this.)
2. Is `/users/me` expected to carry `X-Learning-Language`? (I9)
3. What's the prefix convention for future language-scoped preference keys? `progress_` + `attempt_` today — is there a canonical list? (C4)
4. Should `OnboardingController` actually be permanent, or should it be scoped to the onboarding route tree?

---
**Status:** DONE_WITH_CONCERNS
**Summary:** Cold-resume + multi-language refactor works on the happy path but has a real payload-casing bug (C1) that will break translation and /onboarding/complete, cache-flush policy (C4) destroys the 100 MB lesson cache on every language toggle, and controller lifecycle (C6/N8) leaks workers. Recovery interceptor is correct in steady state but has reentry edges (C2/C3) and a broken null-return contract (I3). File-length violations in AiChatController (538) and AuthController (260) are cross-cutting concerns for future maintenance.
