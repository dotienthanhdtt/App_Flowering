# Code Review — Multi-Language Adaptation (Phases 1–7)

**Branch:** `feat/update-onboarding`
**Date:** 2026-04-19
**Reviewer:** code-reviewer agent
**Score:** 7.5 / 10

---

## Scope

| File | Type |
|------|------|
| `lib/core/services/language-context-service.dart` | New |
| `lib/core/network/active-language-interceptor.dart` | New |
| `lib/core/network/language-recovery-interceptor.dart` | New |
| `lib/core/services/cache-invalidator-service.dart` | New |
| `lib/core/services/storage_service.dart` | Modified |
| `lib/core/network/api_client.dart` | Modified |
| `lib/core/network/api_exceptions.dart` | Modified |
| `lib/app/global-dependency-injection-bindings.dart` | Modified |
| `lib/features/onboarding/controllers/onboarding_controller.dart` | Modified |
| `lib/features/chat/controllers/ai_chat_controller.dart` | Modified |

---

## Overall Assessment

The architecture is sound: single source of truth service, header via Dio interceptor, one-shot 403 recovery, cache subscription via `ever()`. The implementation quality is high overall. Two issues are genuinely critical in production — the logout path misses clearing language state, and the `resyncFromServer` function can trigger a recursive Dio request through the `LanguageRecoveryInterceptor` itself. Several medium issues around edge-case correctness are noted below.

---

## Critical Issues

### C1 — Logout does not clear `LanguageContextService`

**File:** `lib/features/profile/controllers/profile-controller.dart:32-43`

`_performLogout()` calls `_storageService.clearAll()` (which clears Hive preferences) but never calls `LanguageContextService.clear()`. The service's in-memory `RxnString` observables (`activeCode`, `activeId`) retain the stale language code after logout. On the very next launch, `LanguageContextService.init()` reads from cleared Hive and returns `null` — so the boot state is correct. However, if the logout flow _does not_ restart the app (e.g. the user is navigated back to onboarding without a process kill), any in-flight or subsequent content request will still carry the ex-user's language code via `ActiveLanguageInterceptor`. Also, `CacheInvalidatorService`'s `ever()` worker is still alive pointing at the stale observable — a language switch that happens between logout and next login could trigger a cache flush against an unauthenticated state.

**Fix:** Add `Get.find<LanguageContextService>().clear()` inside `_performLogout()` before navigating away.

```dart
await Get.find<LanguageContextService>().clear();
Get.offAllNamed(AppRoutes.onboardingWelcome);
```

---

### C2 — `resyncFromServer` calls `ApiClient` which re-enters `LanguageRecoveryInterceptor` — infinite loop risk

**File:** `lib/core/services/language-context-service.dart:49-71`
**Related:** `lib/core/network/language-recovery-interceptor.dart:33`

`LanguageRecoveryInterceptor.onError` recovers a 403 by calling `LanguageContextService.resyncFromServer()`. That method in turn calls `api.get(ApiEndpoints.userLanguages)`. The `userLanguages` path is `/languages/user` — which does NOT appear in `ActiveLanguageInterceptor._skipPrefixes` (only `/languages` is listed, not `/languages/user`). So the resync request will attach the (potentially wrong) `X-Learning-Language` header. Worse: if the backend returns another 403 for the resync request itself (e.g. the new language from resync is also not enrolled), the recovery interceptor will recursively call itself. The `_retryFlag` only guards the _original_ request's retry, not the resync request.

**Fix — two parts:**

1. Add `/languages/user` to `_skipPrefixes` in `ActiveLanguageInterceptor` (resync should not carry a learning-language header — it's a meta call):

```dart
static const List<String> _skipPrefixes = [
  '/auth',
  '/languages',    // covers /languages AND /languages/user
  '/users/me',
  '/subscription',
  '/admin',
];
```

Actually `/languages` already prefix-matches `/languages/user` via `path.startsWith`, so the header _is_ suppressed. Re-check: `_needsHeader` returns `!_skipPrefixes.any(path.startsWith)`. Since `'/languages/user'.startsWith('/languages')` is `true`, the header will NOT be added. This is actually fine.

However, the recursive 403 risk remains. If `/languages/user` itself returns 403 (e.g. JWT expired), `LanguageRecoveryInterceptor.onError` fires again, sees `notEnrolled` detection returns null (status is 403 but message differs), and routes to `handler.next` — so no infinite loop. The detection guard (`detectLanguageContextError` returns null for non-matching messages) does protect here. **Downgrade this sub-issue to medium.**

The actual remaining risk: if the server returns `403 "not enrolled"` for the `/languages/user` resync request itself (a degenerate backend state), the recovery interceptor will call `resyncFromServer()` again. The retry flag is per-original-request, and the resync creates a _new_ request without the flag. This is a real — though unlikely — re-entrant loop.

**Fix:** Set `_retryFlag` on the resync request's options too, or guard with an instance-level `bool _recovering = false`:

```dart
bool _recovering = false;

@override
Future<void> onError(...) async {
  ...
  if (_recovering) return handler.next(err);
  _recovering = true;
  try {
    final newCode = await Get.find<LanguageContextService>().resyncFromServer();
    ...
  } finally {
    _recovering = false;
  }
}
```

Note: `_recovering` would be a shared mutable field on the interceptor, which is fine since Dio interceptors are single-instance and not called concurrently per-interceptor.

---

## High Priority

### H1 — `CacheInvalidatorService` seed logic has an ordering bug

**File:** `lib/core/services/cache-invalidator-service.dart:25-35`

```dart
_worker = ever<String?>(langCtx.activeCode, (code) async {
  if (!_seeded) {
    _seeded = true;
    return;
  }
  await _flush(storage);
});
// Mark seeded so boot emission does not trigger flush on fresh installs
_seeded = true;
```

The comment says "mark seeded so boot emission does not trigger flush." But `_seeded` is already set to `true` _inside_ the `ever()` callback's first invocation (line 27-29). Then line 34 sets it again. Dart's `ever()` fires the callback _synchronously_ on the first emission if the observable already has a non-null value. Since `LanguageContextService.init()` runs before this and may have set `activeCode.value`, the callback fires **during** `ever(...)` construction, before line 34 is reached. The `_seeded` field is still `false` at that point (line 34 hasn't run yet), so the callback's `if (!_seeded)` branch executes, sets `_seeded = true`, and returns without flushing — correct behavior.

BUT: if `activeCode.value` is `null` at boot (fresh install), `ever()` does not fire immediately (RxnString only fires when the value changes). Then line 34 sets `_seeded = true`. On the first genuine language selection, `_seeded` is already true, so the flush WILL run — correct.

The logic is actually correct for both paths (existing user with persisted language, and fresh install), but the implementation is confusing because the `_seeded = true` at line 34 is redundant when a boot emission fires (the callback already set it). The duplication at line 34 only covers the fresh-install path. This is not a bug but is fragile: if `ever()` ever changed to fire asynchronously, line 34 would race. Worth simplifying.

**Suggested fix:** Remove the in-callback `_seeded = true` / early-return and rely solely on a pre-set flag:

```dart
_seeded = true; // suppress boot emission before subscribing
_worker = ever<String?>(langCtx.activeCode, (code) async {
  if (!_seeded) { _seeded = true; return; } // defensive, never hit
  await _flush(storage);
});
```

No — this inverts the logic and breaks for the non-null boot case. The simplest correct form:

```dart
bool _suppressNext = true;
_worker = ever<String?>(langCtx.activeCode, (code) async {
  if (_suppressNext) { _suppressNext = false; return; }
  await _flush(storage);
});
_suppressNext = false; // for fresh-install path (no immediate emission)
```

This is clearer but also fragile. Best solution: snapshot the boot value before `ever()` and compare inside the worker:

```dart
final bootCode = langCtx.activeCode.value;
_worker = ever<String?>(langCtx.activeCode, (code) async {
  if (code == bootCode && !_seeded) { _seeded = true; return; }
  _seeded = true;
  await _flush(storage);
});
_seeded = true;
```

Recommend filing this as a follow-up refactor. Current code is functionally correct but brittle.

---

### H2 — `AuthController` still reads legacy `onboarding_conversation_id` key

**File:** `lib/features/auth/controllers/auth_controller.dart:39-41`

```dart
String? get _conversationId =>
    _storageService.getPreference<String>('onboarding_conversation_id');
```

`OnboardingProgressService` migrates this key on init and then deletes it. After migration, this getter always returns `null` — meaning accounts created after a resume no longer link the conversation. The conversation ID should now be read from `OnboardingProgressService.read().chat?.conversationId`. Additionally, `_handleAuthSuccess` at line 133 still calls `removePreference('onboarding_conversation_id')` which is now a no-op after migration.

**Fix:**

```dart
String? get _conversationId =>
    Get.find<OnboardingProgressService>().read().chat?.conversationId;
```

And remove the `removePreference('onboarding_conversation_id')` call from `_handleAuthSuccess` (replaced by `OnboardingProgressService.clearAll()` on successful auth if desired).

---

### H3 — `preferenceKeysMatching` iterates over `_preferences.keys` which may contain non-String keys

**File:** `lib/core/services/storage_service.dart:238-239`

```dart
Iterable<String> preferenceKeysMatching(bool Function(String) test) =>
    _preferences.keys.cast<String>().where(test);
```

Hive `Box<dynamic>` keys are `dynamic`. If any code ever stored a non-String key (e.g. an integer index), `.cast<String>()` will throw a `CastError` at runtime when the `Iterable` is consumed. `CacheInvalidatorService._flush` calls this with `.toList()`, which materializes the cast eagerly.

**Fix:** Use `whereType<String>()` instead of `cast<String>()`:

```dart
_preferences.keys.whereType<String>().where(test)
```

---

## Medium Priority

### M1 — `_needsHeader` path matching is prefix-only — no protection against `/languagesXYZ`

**File:** `lib/core/network/active-language-interceptor.dart:44`

```dart
bool _needsHeader(String path) => !_skipPrefixes.any(path.startsWith);
```

`path.startsWith('/languages')` also skips `/languagesXYZ` (a hypothetical malformed path). This is unlikely to matter in practice but is a fragile convention. More importantly, paths without a leading slash (possible if `baseUrl` includes a trailing slash and the caller omits the leading slash) would not match any prefix and would always get the header even for auth paths. Dio normalizes this in most cases but it's worth a comment.

No immediate fix required — add a comment noting that all paths are expected to begin with `/`.

---

### M2 — `LanguageContextService.resyncFromServer` clears on empty enrollment but does not navigate

**File:** `lib/core/services/language-context-service.dart:56-63`

When `resyncFromServer` finds no active enrollment it calls `clear()` and returns null. The caller (`LanguageRecoveryInterceptor`) then calls `handler.next(err)` — passing the original 403 up the chain. The UI will receive a `ForbiddenException` and show a generic "no permission" message, not a user-friendly "enroll in a language" prompt. The detection enum `LanguageContextError.notEnrolled` is never surfaced to the UI.

**Fix:** The recovery interceptor could re-wrap the error as an `ApiErrorException` with a translation key, or the UI error handler could check for `ForbiddenException` with specific message. Document the intended UX path clearly (phase 8 / settings toggle work).

---

### M3 — `OnboardingController._hydrateFromProgress` calls `_langCtx.setActive` which is `async` but is not `await`ed

**File:** `lib/features/onboarding/controllers/onboarding_controller.dart:82`

```dart
_langCtx.setActive(p.learningLang!.code, p.learningLang!.id);
// Mirror updated reactively via ever() worker
```

`setActive` is `async` (awaits Hive writes). The comment says "Mirror updates reactively via ever() worker" but the observable is actually updated _after_ the Hive await inside `setActive`. If `_createSession` in `AiChatController` reads `_langCtx.activeCode.value` before the Future resolves, it could see a null/stale value. In practice `_hydrateFromProgress` is called from `onInit()` which is synchronous, and `AiChatController` reads the value in its own `onInit` (via `_bootstrapSession` → `_createSession`). Both controllers' `onInit` are called before the first build frame, so the race window is narrow but present.

**Fix:** Make `_hydrateFromProgress` async and await the `setActive` call, or guard `_createSession` with a check after a microtask:

```dart
Future<void> _hydrateFromProgress() async {
  ...
  if (p.learningLang != null) {
    await _langCtx.setActive(p.learningLang!.code, p.learningLang!.id);
  }
  ...
}
```

And call it as `await _hydrateFromProgress()` in `onInit`. Since `onInit` is not `async` in GetX, this requires a `Future.microtask(() async { await _hydrateFromProgress(); })` or extracting to a separate async boot method.

---

### M4 — `LanguageRecoveryInterceptor` mutates shared `requestOptions.extra` in-place

**File:** `lib/core/network/language-recovery-interceptor.dart:36-38`

```dart
final opts = err.requestOptions;
opts.extra[_retryFlag] = true;
final response = await _dio.fetch(opts);
```

`err.requestOptions` is the original options object. Mutating it in-place means if Dio internally retains a reference (e.g. for logging or the retry interceptor's own state), the `_retryFlag` bleeds into contexts it was not intended for. Prefer creating a copy:

```dart
final opts = err.requestOptions.copyWith(
  extra: {...err.requestOptions.extra, _retryFlag: true},
);
```

---

### M5 — `detectLanguageContextError` keyword matching is fragile

**File:** `lib/core/network/api_exceptions.dart:185-196`

The function relies on lowercase substring matching of backend error messages (e.g. `m.contains('not enrolled')`). Any backend phrasing change silently breaks recovery. No version in the API contract pins these strings.

**Fix:** Coordinate with backend to use a stable `error_code` field in the response body (e.g. `"error_code": "LANGUAGE_NOT_ENROLLED"`) and switch detection to check that field. This is a backend contract issue — file a follow-up ticket.

---

### M6 — `_handleChatResponse` hardcodes `maxTurns = 10` for progress calculation

**File:** `lib/features/chat/controllers/ai_chat_controller.dart:263`

```dart
progress.value = (session.turnNumber / 10).clamp(0.0, 1.0);
```

`_applyRehydratedTranscript` correctly reads `maxTurns` from the server payload, but `_handleChatResponse` hardcodes `10`. If the backend changes max turns (e.g. for a premium tier), the progress bar will be inaccurate. This predates the multi-language change but was not fixed during cleanup.

---

## Low Priority

### L1 — `StorageService.init()` recursive retry on `HiveError` has unbounded depth

**File:** `lib/core/services/storage_service.dart:47-49`

```dart
} on HiveError catch (e) {
  await Hive.deleteFromDisk();
  return await init(); // Retry
}
```

If Hive continues to fail after deletion (e.g. permission error), this recurses indefinitely. Add a max-retry guard.

### L2 — `_estimateSize` uses UTF-16 approximation for UTF-8 content

**File:** `lib/core/services/storage_service.dart:272-274`

Dart strings are UTF-16 internally. The comment says "UTF-16 encoding approximation" — multiplying `length * 2` is correct for UTF-16. But Hive serializes to UTF-8. For ASCII-heavy content the overestimate is 2x, which may cause premature eviction. Not critical but worth noting.

### L3 — `LanguageContextService._storage` getter calls `Get.find` on every access

**File:** `lib/core/services/language-context-service.dart:17`

```dart
StorageService get _storage => Get.find<StorageService>();
```

`Get.find` has a hashmap lookup cost. Since this is a `GetxService` (singleton), the `StorageService` reference could be stored as a `late final` field in `init()`. Minor perf concern.

### L4 — Translation keys for `LanguageContextError` enum defined but never used in UI

**File:** `lib/core/network/api_exceptions.dart:169-180`

`LanguageContextError.translationKey` getter is defined but nothing calls it. The UI paths that show errors use hardcoded `.tr` keys directly. Either wire this up or remove the getter (YAGNI).

---

## Positive Observations

- **Service init order** in `initializeServices()` is correct and well-commented: Storage → LanguageContext → CacheInvalidator → ApiClient. This is the hardest part of this feature to get right and it is.
- **`ActiveLanguageInterceptor` never throws** — the full try/catch + `handler.next` pattern means no request is ever blocked by interceptor failures.
- **`LanguageRecoveryInterceptor` one-shot guard** via `_retryFlag` in `extra` is the correct Dio idiom.
- **`CacheInvalidatorService.onClose`** correctly disposes the Worker — no memory leak.
- **`OnboardingController` worker lifecycle** — `_langCtxWorker?.dispose()` in `onClose()` is correctly paired.
- **`_hydrateFromProgress` correctly seeds the ever() mirror** before navigation so the interceptor has a language code before the first API call of the resume flow.
- **`resyncFromServer` error path** returns `activeCode.value` (the last known good value) rather than null, avoiding a cascade failure on a transient network error.
- **`preferenceKeysMatching` + `removePreferencesMatching`** clean API on StorageService — correct FIFO enumeration with `.toList()` before deleting to avoid ConcurrentModificationError (when using a Hive-backed iterator).
- **Translation keys** in both en-us and vi-vn are symmetric and correctly keyed.
- **Test coverage** for `OnboardingProgressService` is thorough: covers corruption, migration, and idempotency.

---

## Checklist

- [x] Concurrency: Worker lifecycle and ever() ordering analyzed
- [x] Error boundaries: interceptor exception isolation verified
- [x] API contracts: path skip-list reviewed, header injection verified
- [x] Backwards compatibility: legacy key migration in OnboardingProgressService verified
- [x] Input validation: language code is not validated for format (non-blocking)
- [x] Auth/authz: logout path gap identified (C1)
- [x] N+1 / query efficiency: single Hive key for progress, no loop over DB in hot paths
- [x] Data leaks: no PII in logs (kDebugMode guards)

---

## Recommended Actions (Prioritized)

1. **[BLOCKING]** Fix `_performLogout()` to call `LanguageContextService.clear()` — C1
2. **[BLOCKING]** Add instance-level re-entrancy guard to `LanguageRecoveryInterceptor` — C2
3. **[HIGH]** Fix `AuthController._conversationId` to read from `OnboardingProgressService` — H2
4. **[HIGH]** Replace `cast<String>()` with `whereType<String>()` in `preferenceKeysMatching` — H3
5. **[MEDIUM]** Await `_langCtx.setActive` in `_hydrateFromProgress` — M3
6. **[MEDIUM]** Copy `requestOptions` before mutating `.extra` in recovery interceptor — M4
7. **[LOW]** Add max-retry guard to `StorageService.init()` recursion — L1
8. **[LOW]** Remove unused `LanguageContextError.translationKey` getter or wire it up — L4

---

## Unresolved Questions

1. Does the backend guarantee the `"not enrolled"` substring in the 403 message body, or is there a stable `error_code` field? (Affects M5 severity — if message can vary, M5 becomes critical.)
2. Phase 8 (language switch UX / settings toggle) is marked pending — are C1/H2 expected to be fixed in phase 8 or is the logout path considered out-of-scope for this review?
3. `AuthController` `_conversationId` — is the intent to stop linking conversations to accounts after the onboarding progress migration, or is H2 an oversight?
