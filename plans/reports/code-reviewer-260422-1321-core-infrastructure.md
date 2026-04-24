# Core Infrastructure Review — feat/update-onboarding

Infrastructure is well-factored but has **3 critical security/auth bugs** shipping today, plus token-refresh races that will cause phantom logouts under load.

## Critical (must fix)

### C1. HTTP logger prints Bearer tokens in dev builds
`lib/core/network/http_logger_interceptor.dart:127-133` — the Authorization-redaction branch is commented out. Every dev-build request prints `curl ... -H 'Authorization: Bearer eyJ...'`. Anyone with the console log or a bug-report screenshot owns the account.
**Fix:** uncomment the redaction branch; always print `Bearer ***` for `authorization` key (case-insensitive).

### C2. HTTP logger prints refresh_token in request bodies
Same file, `_buildCurl` line 135-142. Request body for `/auth/refresh`, `/auth/login`, `/auth/register` is `jsonEncode`'d verbatim. Only *response* bodies get `_redactSensitiveFields`. Refresh tokens, passwords, and id_tokens are printed.
**Fix:** before `jsonEncode(options.data)`, if `_isAuthEndpoint(options.path)`, run `_redactSensitiveFields` on the request body too (add `password`, `id_token` to `_sensitiveKeys`).

### C3. Token-refresh race triggers cascading logouts
`lib/core/network/auth_interceptor.dart:46-91`. `QueuedInterceptor` serializes `onError` callbacks, so the second 401 only starts **after** the first onError finishes — by that point `_refreshGate` has been reset to null in the `finally` block (line 73). The second caller takes the "no gate" branch and starts **another** refresh. If the backend rotates refresh tokens (common), the second refresh fails, `clearTokens()` runs, user is kicked to `/login`.
**Fix:** stash the token value used for the failing request (snapshot in onRequest via `options.extra['_auth_token']`). In onError, compare to `_authStorage.cachedAccessToken`; if they differ, the refresh already happened — just re-fetch with the current token, skip the refresh path entirely.

## Important

### I1. RetryInterceptor recursion can leak handler
`lib/core/network/retry_interceptor.dart:49-55` — on a DioException inside the recursive retry, `onError(e, handler)` re-enters but passes the SAME `handler`. Dio expects exactly one terminal call per handler; if `_shouldRetry` returns false the `next(err)` fires, but the recursion lacks a guard that `retryCount` was actually updated before recursion on fetch failure. Recommend converting to a loop.

### I2. Refresh endpoint uses an ad-hoc Dio, bypasses retry
`auth_interceptor.dart:99-103` — creates a throwaway `Dio()` per refresh. No connectivity check, no retry on transient 500, no logger. On flaky networks the refresh silently fails and user is logged out. Use `_retryDio` (which has no interceptors — add one-shot retry there) or share a configured refresh client.

### I3. `_retryDio` in AuthInterceptor bypasses ALL interceptors
`api_client.dart:36-40, auth_interceptor.dart:53, 80`. The retry Dio has no interceptors by design, so the retried request skips `ActiveLanguageInterceptor`. If the active language changed between the original failure and the retry (rare but possible during `resyncFromServer`), the retry sends a stale header. Re-apply `X-Learning-Language` in `AuthInterceptor` before `_retryDio.fetch` (same way Authorization is set).

### I4. `BaseController.apiCall` leaks 2-second loading hang
`lib/core/base/base_controller.dart:81-89`. The `finally` block always delays up to 2s after **cancelled** API calls complete. The inner `if (!_lifecycleToken.isCancelled)` gates the eventual `isLoading=false` set, but `Future.delayed` still runs. Not a memory leak, but `onClose` completes, then 2s later the `isLoading` write targets a disposed RxBool (no-op guarded). More concerning: user perceives hang if controller is re-created quickly. Compute `elapsed` **before** awaiting delay; early-return on cancelled.

### I5. LoadingOverlay global timer state is not test-safe
`lib/shared/widgets/loading_overlay.dart:12-19`. `_loadingDialogTimer`, `_loadingDialogMinDurationTimer`, and `_loadingDialogShownAt` are file-top globals. Concurrent `showLoadingDialog()` calls from different screens share state. Tests that don't reset them leak across tests. Wrap in a singleton class or move to a `Get.find<>()`-registered service.

### I6. LanguageRecoveryInterceptor registered AFTER HttpLogger in comment but BEFORE in code
`api_client.dart:42-49`. Comment says "Order: retry → auth → language header → language 403 recovery → logger" and code matches. However Dio executes `onError` top-down — so recovery runs **before** logger. Logger will never see the recovered 200 response. Docs fine, behavior fine, but add a unit test to lock it down.

### I7. StorageService.init wipe-and-retry loses user data silently
`lib/core/services/storage_service.dart:43-44` — on box open failure, calls `Hive.deleteFromDisk()` which nukes **all** boxes, not just the corrupted one. If `_preferences` fails to open but `encryption_keys` box is fine, both are deleted. User loses onboarding progress + `has_completed_login` flag. Prefer `Hive.deleteBoxFromDisk(_preferencesBox)` targeted delete.

### I8. CLAUDE.md claims Hive boxes sized 100MB/10MB/1MB with LRU/FIFO — doesn't exist
`storage_service.dart` only has `_preferences` box, no size enforcement, no eviction policy. Old boxes (`lessons_cache`, `chat_cache`) removed but docs/CLAUDE.md still advertise limits. Update docs or reinstate eviction — a future contributor will trust the CLAUDE.md contract.

## Minor

- **M1.** `api_response.dart:22`: `json['code'] as int? ?? 0` — backend `code: 1` success check silently drops `"1"` string. Not currently an issue but one cross-serializer change away.
- **M2.** `api_client.dart:177`: SSE parser buffers on `\n` split but SSE spec requires `\r\n` or `\r` handling. Some servers/proxies emit `\r\n` and the trailing `\r` lingers in the payload.
- **M3.** `auth_interceptor.dart:23`: `options.path.contains(ApiEndpoints.refreshToken)` — `contains` matches `/auth/refresh/anything`. Use `endsWith` or exact-match. Same smell in `onError` line 41.
- **M4.** `retry_interceptor.dart:37`: `1 << retryCount` — at `maxRetries=3`, shift is 8, delay up to 12s. Fine but no cap.
- **M5.** `connectivity_service.dart:30`: returning "online" on any non-`none` result includes Bluetooth/VPN — may show online when unreachable. Consider a real reachability probe before emitting back-online.
- **M6.** `app_text.dart`: no `semanticsLabel` passthrough. Screen readers cannot be told "$42" should be read as "forty-two dollars".
- **M7.** `app_text_field.dart:59`: `_obscureText = true` initial, then overwritten in `initState`. Default constant should be `false` for clarity.
- **M8.** `env_config.dart:7`: `apiBaseUrl` silently defaults to `''` on missing env — a request to `''+'/auth/login'` becomes a relative URL. Better to `throw StateError` on boot if missing.
- **M9.** `global-dependency-injection-bindings.dart:169-171`: `Get.put<TtsProviderContract>(FlutterTtsProvider())` in deferred init creates a SECOND instance despite line 62-74 already registering lazyPut versions. `Get.put` overrides lazyPut — so the factory registered earlier is discarded, creating dead code in `AppBindings.dependencies()`.

## Adversarial findings (race conditions & failure modes)

- **A1. Parallel 401s → phantom logout.** See C3. Reproduce: fire two authenticated requests simultaneously while token expired. Second one logs the user out.
- **A2. Network flip mid-refresh.** Refresh POST hits `connectionTimeout` → `_refreshToken` returns false → user logged out even though network just blipped. C2 fix (retry refresh) addresses this.
- **A3. Token expires mid-onRequest.** `AuthInterceptor.onRequest` reads `cachedAccessToken` which may be stale by microseconds. Request sent with stale token → 401 → refresh → retry. Works, but wastes a round-trip on every expiration boundary. Accept.
- **A4. Corrupted Hive box on boot.** `StorageService.init` nukes **all** Hive boxes including any future encryption-key box. Combined with `AuthStorage` (secure storage, separate from Hive) — user stays logged in but loses onboarding progress and language context. Re-login without a path to recover language → app hits `activeRequired` error → resync loop. See I7.
- **A5. `.env.dev` missing in bundle.** `dotenv.load` throws; `main.dart:29` doesn't catch. App crashes on launch, silently, with no crash-reporter hint (Firebase init hadn't run yet on line 34). Consider loading env before/after `try` block reordering.
- **A6. Language context null during boot race.** `ActiveLanguageInterceptor` line 27 checks `Get.isRegistered<LanguageContextService>()` and drops the header if not. Boot order is right, but if a widget fires a request **during** `initializeCriticalServices` (first-frame prefetch mentioned in comments) before language service registers, header is missing → 400 error.
- **A7. `base_controller.apiCall` after lifecycle cancel.** Second caller to cancelled `cancelToken` gets silent `null` result — caller may not distinguish "error" vs "cancelled" vs "success with null data". Document this or return a sealed result type.

## Unresolved questions

- Why does the comment in `api_client.dart:35` say "retried requests bypass the full chain" but the retry Dio is only used by AuthInterceptor and LanguageRecoveryInterceptor, not by RetryInterceptor (which uses the main `_dio`)? Audit whether RetryInterceptor should also use `_retryDio` to avoid re-triggering auth refresh on 5xx retries.
- Should `hasCompletedLogin` survive `Hive.deleteFromDisk()` fallback (I7)? Product intent suggests yes — confirm with onboarding owner.
- Is there a rate-limit backoff contract with the backend for `/auth/refresh`? If so, double-refresh (C3) could trigger lockout.
- `Get.lazyPut(..., fenix: true)` + `Get.put(...)` in deferred init (M9): is this intentional override or bug?
