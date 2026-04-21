# Adversarial Red-Team Review — feat/update-onboarding
Range: `0f148155..cc1e49f6` (32 files).
Stage 3 of 3. Prior stages already flagged: mixed casing, retryDio in LanguageRecoveryInterceptor, `_recovering` race, clearLessonsCache blast radius, CacheInvalidator `_seeded` race, permanent OnboardingController, silent catches, resync fallback, fromServerJson timestamp, postStream sub leak, schema-bump wipe, 538-line controller, missing tests.
This report only lists **NEW** findings and **adjudications**.

---

## CRITICAL

### C1 — AuthInterceptor double-refresh race overwrites new token with old
- **File:** `lib/core/network/auth_interceptor.dart:41-75`
- **Severity:** CRITICAL  **Verdict:** ACCEPT
- **Proof:** `AuthInterceptor extends QueuedInterceptor`, but the override is `void onError(...)` (not `Future<void>`). `QueuedInterceptor` only serializes a handler when the method signature it invokes is awaited; because this `onError` is declared `void` and uses internal `await`, the queued-interceptor chain does NOT actually wait for the refresh to finish. In parallel, two 401 responses A and B arrive:
  1. A enters, sets `_isRefreshing=true`, starts `_refreshToken()`.
  2. B enters; sees `_isRefreshing==true` → calls `handler.next(err)` which **emits the unmodified 401 upward** instead of queuing the retry. The caller sees 401 and may log the user out, while A refreshes successfully in the background. Conversely, if the queue does defer (race), A fails refresh, clears tokens in the `catch`, then B's `catch` *also* fires `clearTokens()` → idempotent but triggers a duplicate `Get.offAllNamed('/login')` stacking two navigations. Worse: `_isRefreshing` is never guarded; B's `catch` path can run while A is still inside `_refreshToken()` and wipe the freshly-saved token.
  3. If refresh succeeds but `response.data['data']['refresh_token']` is the *same* token the backend echoed (idempotent re-issue) and A's save races with B's save, the second save can persist a stale body if B read its response data from a retry after A rotated the refresh token → next boot logs user out.
- **Fix sketch:** Serialize with a `Completer<bool>`: first 401 creates it, subsequent 401s `await` the existing one, then read `_authStorage.getAccessToken()` once resolved. Move retry into same Dio (not a second one) OR pass the full interceptor chain.

### C2 — `X-Learning-Language` override in ChatHomeController bypasses future sanity check
- **File:** `lib/features/chat/controllers/chat-home-controller.dart:49-51`
- **Severity:** CRITICAL  **Verdict:** ACCEPT
- **Proof:** `ChatHomeController.fetchLessons` sets the header manually via `Options(headers: {'X-Learning-Language': activeCode})`. The `ActiveLanguageInterceptor` explicitly honors per-request overrides (`if (options.headers.containsKey(_headerName)) return handler.next(options);`). `activeCode` is read from `LanguageContextService.activeCode.value` which is hydrated from Hive prefs (`active_language_code`). **Hive prefs are NOT secure storage** — a rooted device, a malicious backup-restore, or a future "change language" bug can inject any string here (e.g. `"'; DROP…"`, `..%2F`, `\r\nX-Admin: 1`). Since Dio does not validate header values for CRLF, an attacker-controlled `activeCode` can inject a second header via header-splitting on older HTTP stacks.
  Additionally: duplicating the header-attach logic at call sites defeats the interceptor's purpose (every new screen has to remember to do it). Drop the override and let the interceptor handle it uniformly.
- **Fix sketch:** (1) validate `code` against `^[a-z]{2,3}(-[A-Z]{2})?$` in `LanguageContextService.setActive`; (2) remove the per-call `Options(headers: …)` override in ChatHomeController.

### C3 — LanguageContextService trusts server payload without schema validation
- **File:** `lib/core/services/language-context-service.dart:60-66, 73-84`
- **Severity:** CRITICAL  **Verdict:** ACCEPT
- **Proof:** `_pickFromEnrollments` does `picked['code'] as String` and `picked['id'] as String?`. If the backend returns `{"code": 123}` (int) or `{"code": null}` (which passes `(e) => e['isActive'] == true` predicate when `firstWhere` fallback kicks in), the cast throws inside the `try` and the `catch` swallows it, returning the stale cached `activeCode`. The `LanguageRecoveryInterceptor` then checks `newCode == null` to gate the retry — but resync returned a non-null stale value, so it retries with the *same bad* header → infinite 403 loop until `_recovering=true` flag saves us for that single request, but the next request repeats.
  Second attack: a compromised intermediate (or a dev proxy) could inject `'code': '../../admin'` and `'id': some-uuid` — path never checks format. Combined with C2, this flows into a header on subsequent requests.
- **Fix sketch:** After the cast, validate the shape: `if (code is! String || code.isEmpty || !RegExp(r'^[a-z]{2,3}(-[A-Z]{2})?$').hasMatch(code)) return null;`. Also change catch branch to return `null` not `activeCode.value` (scout flagged the return-stale part; the trust issue is new).

### C4 — `/auth/firebase` idToken payload missing on Apple cancel path leaks error message
- **File:** `lib/features/auth/controllers/auth_controller.dart:199-202`
- **Severity:** IMPORTANT (raised to CRITICAL if Crashlytics is wired to `errorMessage`)
- **Verdict:** ACCEPT
- **Proof:** Google path catches `FirebaseAuthException` and sets `errorMessage.value = e.message ?? 'google_sign_in_failed'.tr`. **`FirebaseAuthException.message` can include tokens, emails, and internal backend messages** (e.g. "The credential is invalid. The OAuth access token 'ya29.a0AfH6SMB…' was rejected"). Surfacing raw `e.message` to the UI (visible via Obx) and potentially to Crashlytics breaches user-data hygiene. Same applies to `FirebaseAuth.signInWithCredential` thrown up from `_authenticateWithFirebase`.
- **Fix sketch:** Map `e.code` to a translation key (`account-exists-with-different-credential`, `invalid-credential`, etc.); never surface `e.message` raw. Log to Crashlytics via `FirebaseCrashlytics.recordError(e, null)` which scrubs tokens.

---

## IMPORTANT

### I1 — Deep-link to `/chat` cold-resume bypasses auth gate
- **File:** `lib/features/chat/bindings/ai_chat_binding.dart:7-15` + `splash_controller.dart:34-57`
- **Severity:** IMPORTANT  **Verdict:** ACCEPT
- **Proof:** `computeOnboardingResumeTarget` routes to `AppRoutes.chat` if `p.chat != null` OR `p.learningLang != null`, **without checking `_authStorage.isLoggedIn`**. The `else` branch at line 54 is only reached if `!isValid && !hasToken && !hasCompletedLogin`. That means a **fresh-install user who completed onboarding flows (anonymous chat)** gets routed straight to `/chat`. Any push-notif/deep-link handler that calls `Get.toNamed('/chat')` for a returning user whose token silently expired will also land in `AiChatBinding` → `OnboardingBinding` → `AiChatController._bootstrapSession` → `_rehydrateFromBackend` → unauthenticated `GET /onboarding/conversations/:id/messages`. If the backend permissively serves anonymous conversation messages (per the smoke test's `POST /onboarding/chat` being Tier 1 public), an attacker who knows a conversation UUID can enumerate message history. Even if the backend 403s, the app caches content locally. This is also a unit-testing gap.
- **Fix sketch:** In `computeOnboardingResumeTarget`, take `hasToken` as second arg and require it for `.chat` branch when `profileComplete`.

### I2 — `_performLogout` does not clear `OnboardingProgress` → next login sees prior user's conversation
- **File:** `lib/features/profile/controllers/profile-controller.dart:33-47`
- **Severity:** IMPORTANT  **Verdict:** ACCEPT
- **Proof:** `_performLogout` clears `authStorage.clearTokens()`, `storageService.clearAll()`, `languageContext.clear()`, but `StorageService.clearAll` preserves `_hasCompletedLoginKey` **and does not clear `onboarding_progress`** (the preferences box is cleared, which *does* wipe the key — wait: `clearAll()` calls `clearPreferences()` then re-sets `hasCompletedLogin`. So it DOES clear onboarding_progress. REVERSE: the issue is `OnboardingProgressService` holds no internal state but `conversationId` lives in `OnboardingController` which is `permanent:true` (prior finding). **New angle:** after logout → login as a different account, `OnboardingController.conversationId` and `.selectedNativeLanguage` persist in memory. The next call to `AuthController._handleAuthSuccess` awaits `_progressSvc.clearChat()` but doesn't touch the permanent OnboardingController instance. The NEW user's `/auth/register` request sends the PREVIOUS user's `conversationId` via `if (_conversationId != null) 'conversationId': _conversationId` — cross-user data leak to the backend linker.
- **Fix sketch:** In `_performLogout`, `Get.delete<OnboardingController>(force: true)` (or drop `permanent:true`).

### I3 — Storage corruption recovery is a reboot loop, not a graceful degrade
- **File:** `lib/core/services/storage_service.dart:42-49`
- **Severity:** IMPORTANT  **Verdict:** ACCEPT
- **Proof:** On `HiveError`, `init()` calls `Hive.deleteFromDisk()` then `return await init()`. If the disk error is non-recoverable (readonly FS, permission denied after OS update), this recurses infinitely → ANR → user uninstalls. Also catches only `HiveError`; an `IOException` from `Hive.initFlutter()` on first launch with no `getApplicationDocumentsDirectory` would crash. Finally, `deleteFromDisk()` silently wipes `access_token` metadata from the *other* Hive boxes — but tokens live in secure storage, so auth survives. What does NOT survive: `hasCompletedLogin` flag, meaning recovering users are sent back to onboarding. That's a UX regression masked as "recovery".
- **Fix sketch:** Add retry counter: `if (_initAttempts++ > 1) rethrow; await Hive.deleteFromDisk(); return await init();` and surface a user-visible error screen on second failure.

### I4 — CacheInvalidator missing deletion of `userLanguages` / `users/me` caches
- **File:** `lib/core/services/cache-invalidator-service.dart:38-44`
- **Severity:** IMPORTANT  **Verdict:** ACCEPT
- **Proof:** `_flush` wipes `_lessons`, `_chat`, and preference keys matching `progress_` / `attempt_` prefixes. But `LanguageContextService.resyncFromServer` calls `GET /users/languages` — if there's a Dio-level cache or if future screens cache enrollments under any other prefix (e.g. `enrollments_`, `scenarios_`), they keep the pre-switch content. Even today, the `OnboardingProgressService._key = 'onboarding_progress'` blob contains `learning_lang` — a language switch triggers flush but **does not update the progress blob**, so the next cold-resume computes target route from stale learning lang.
- **Fix sketch:** Flush should also call `_progress.setLearningLang(newCode, id: newId)` OR the progress blob should be keyed off activeLang so it moves with the switch.

### I5 — `postStream` SSE parser vulnerable to partial UTF-8 + no heartbeat timeout
- **File:** `lib/core/network/api_client.dart:140-173`
- **Severity:** IMPORTANT  **Verdict:** ACCEPT
- **Proof:** `buffer += String.fromCharCodes(chunk)` treats each byte as a code unit (Latin-1). A multi-byte UTF-8 char split across chunks produces mojibake. Users typing in Vietnamese/Chinese will see `Ã¡` glyphs mid-stream. Second: there is no upstream cancellation when the subscribing controller disposes (scout flagged the sub leak — I reject the "not cancelled" claim as already flagged but add this NEW angle: the Dio `receiveTimeout: 30s` applies only to the FIRST byte; once streaming starts there is no server-heartbeat timeout. A half-open TCP connection will park indefinitely until OS FIN. For on-device battery: a suspended phone reconnecting sees the stream still "open" and the controller's `isTyping` stays true.
- **Fix sketch:** Use `utf8.decoder.bind(stream)` instead of `String.fromCharCodes`. Add a watchdog timer that cancels the subscription if no event arrives for 20s.

### I6 — Splash backgrounded mid-cold-resume → dual-navigation race
- **File:** `lib/features/onboarding/controllers/splash_controller.dart:34-57`
- **Severity:** IMPORTANT  **Verdict:** ACCEPT
- **Proof:** `_checkAuthAndNavigate` does `Future.wait([Future.delayed(3s), _validateToken()])` then `Get.offAllNamed(...)`. If the user backgrounds the app mid-flight, `onInit()` is NOT cancelled. On resume, Flutter re-attaches; meanwhile the original Future completes and fires `offAllNamed` → user lands on home while still staring at splash. Combined with any other `onResume`-driven navigation (e.g. Firebase push intent), you get Navigator stack corruption. Also: the unconditional 3s delay is bad UX for authenticated returning users; removing it would speed cold-start by ~3s.
- **Fix sketch:** Guard with `if (!Get.isRegistered<SplashController>()) return;` before navigation OR use a `bool _disposed` flag set in `onClose`. Remove the 3s artificial delay.

### I7 — `api-smoke-test.sh` leaks Authorization token to process table / mktemp race
- **File:** `scripts/api-smoke-test.sh:42, 47, 50`
- **Severity:** IMPORTANT  **Verdict:** ACCEPT
- **Proof:** `auth_hdr=(-H "Authorization: Bearer ${ACCESS_TOKEN}")` then `curl …  "${auth_hdr[@]}"` — curl arguments are visible in `ps -ef` on a shared host (CI box). Anyone with shell access sees the bearer token. Also, `tmp=$(mktemp)` writes response bodies to `/tmp/tmp.XXXX` world-readable by default. `trap 'rm -f "$tmp"' EXIT` is missing so SIGINT leaves tokens on disk. No `set -euo pipefail`; pipelines after `jq` fail silently. `python3 -c 'import time;print(int(time.time()*1000))'` forks twice per request — prefer `date +%s%3N` (GNU) or `perl -MTime::HiRes -e 'print int(Time::HiRes::time*1000)'`.
- **Fix sketch:** `curl … -H @<(printf 'Authorization: Bearer %s\n' "$ACCESS_TOKEN")` via `--config` or `-K`; `chmod 600 "$tmp"`; add `set -euo pipefail` and `trap 'rm -f "${tmp:-}"' EXIT`.

### I8 — `_checkGrammar` concurrent with `sendMessage` racing `messages` list mutations
- **File:** `lib/features/chat/controllers/ai_chat_controller.dart:211-232, 429-460`
- **Severity:** IMPORTANT  **Verdict:** ACCEPT
- **Proof:** `sendMessage` fires `_checkGrammar(userMessageId, …)` as fire-and-forget. Meanwhile, `_rehydrateFromBackend` can run on a retry (`retrySession` branch) and calls `messages.assignAll(parsed)` — this wipes the pending userMessageId. When `_checkGrammar` returns and calls `messages.indexWhere((m) => m.id == messageId)`, index is -1 → silent data loss. Worse, if the user sends two messages rapidly, the second's grammar-check may complete before the first's; both execute `messages[idx].showCorrection = true`, `messages.refresh()` — no harm today but `messages.refresh()` is called outside any `update()` guard; multiple rapid fires degrade UI smoothness on low-end Android.
- **Fix sketch:** After `messages.assignAll`, tag a request-id; drop grammar results whose requestId is stale. Or pass a `CancelToken`.

### I9 — `onboarding_progress` preference key has no per-user namespacing
- **File:** `lib/features/onboarding/services/onboarding_progress_service.dart:16`
- **Severity:** IMPORTANT  **Verdict:** ACCEPT
- **Proof:** Key is `'onboarding_progress'` (global). If user A logs out (progress wiped via `clearAll`? No — `clearAll` clears `_key` but `_performLogout` calls `_storageService.clearAll()` which nukes the whole preferences box, OK). However, the **anonymous pre-login phase** writes progress with no user attribution. If device is shared between accounts on the same phone before either logs in, account A's native-lang selection leaks into account B's signup form. Combined with I2 (`conversationId` in signup body), this sends account A's conversation to account B's registration.
- **Fix sketch:** Prefix with a device-install UUID; clear on logout; re-hydrate only if install UUID matches.

### I10 — Language switch during in-flight `postStream` sends stale `X-Learning-Language`
- **File:** `api_client.dart:142-150` + `ActiveLanguageInterceptor`
- **Severity:** IMPORTANT  **Verdict:** ACCEPT
- **Proof:** `postStream` fires `_dio.post(...)` — the language header is fixed at REQUEST time (interceptor runs once). If the user switches language mid-stream, the server keeps streaming in the old language. No in-progress cancel. Backend LLM prompts are locked to the request's header. Doubly: the CacheInvalidator fires `_flush` which nukes `_chat` Hive box MID-STREAM; the stream's message-append path will save a partial AI response with `language=newCode` to the newly-flushed box → cache inconsistency between DB and UI.
- **Fix sketch:** Subscribe to `langCtx.activeCode.stream`; cancel stream on change.

---

## NITS

### N1 — `hit` tier field "T3" skip branch prints fixed-width padding with spaces
- `scripts/api-smoke-test.sh:109` — cosmetic.  **Verdict:** DEFER.

### N2 — `OnboardingProgress.fromJson` silently drops data on ANY schema mismatch
- `lib/features/onboarding/models/onboarding_progress_model.dart:25-26`
- `if (version != schemaVersion) return empty()` — scout noted this wipes. Adding: no telemetry event fired. If we bump to v2, users silently lose progress with no Sentry breadcrumb. **Verdict:** ACCEPT, log before returning empty.

### N3 — `_addAiMessage` early-returns on empty text but `_handleChatResponse` still calls `_addQuickReplies`
- `ai_chat_controller.dart:263-272, 484-498`
- If `session.reply == null || empty`, progress advances but no visible AI message — user sees a disembodied quick-reply row. **Verdict:** ACCEPT as NIT.

---

## ADJUDICATION

### A1 — Scout claim "ActiveLanguageInterceptor added before LanguageContextService init"
- **Verdict: REJECT (false positive).**
- **Proof:** `lib/main.dart:42` calls `initializeServices()`. In `lib/app/global-dependency-injection-bindings.dart:131-132`, `LanguageContextService` is `Get.put(…)` and `init()` **awaited** before `apiClient.init(authStorage)` at lines 159-160. `ApiClient.init` builds interceptors (line 38 of api_client.dart). Additionally, `ActiveLanguageInterceptor.onRequest` defensively checks `Get.isRegistered<LanguageContextService>()` (line 27 of the interceptor). No timing bug exists; the scout's claim is incorrect.

### A2 — Scout claim "`postStream` subscription not cancelled on controller dispose"
- **Verdict: ACCEPT** (not my call to re-adjudicate; just noting I5 above adds UTF-8 + heartbeat angle).

---

## RESOURCE EXHAUSTION ANSWERS
- **403 storm:** `_recovering` flag not queued (scout). After first 403-resolved-success, cache of `activeCode` updated — subsequent 403s bypass via retry flag. Bounded to one retry per request; no wedge. But CPU/battery burn from chained `resyncFromServer` on every request is real when server misconfigures enrollments globally.
- **Hive corrupt/full boot loop:** Covered in I3.
- **Chat cold-resume 10k messages:** `_applyRehydratedTranscript` does `.toList()` then `messages.assignAll(parsed)` — O(n), no jank issue. But `_scrollToBottom` animates over 300ms regardless of list size; no infinite-scroll pagination on rehydrate endpoint. If backend returns >500 messages, Flutter ListView rebuild can frame-drop. **DEFER** (product decision).

---

## OBSERVABILITY GAPS
- No breadcrumb on `LanguageRecoveryInterceptor` success/fail → oncall cannot distinguish "server flapped" from "client stuck".
- `resyncFromServer` catch returns stale code with only `kDebugMode` debugPrint — **release builds emit zero telemetry**.
- `AuthInterceptor._triggerLogout` hardcoded to `/login` not `AppRoutes.login` constant → search fails on refactor.
- `CacheInvalidatorService._flush` has no log of what was flushed — "user reports progress lost" is un-debuggable.

---

## UNRESOLVED QUESTIONS
1. Does backend `/ai/chat/correct` accept camelCase? Smoke test uses camelCase; `toggleTranslation` sends snake_case to `/ai/translate`. If backend is strict, one of them 400s.
2. Is `onboarding_progress` JSON ever larger than the `_preferencesBox` 1MB soft cap mentioned in CLAUDE.md? Ten conversations of JSON blobs = unbounded. Not today's problem but worth a size check.
3. Firebase `idToken` rotation on Apple sign-in — what's the max TTL? If <1min, registration POST can fail if network is slow.
4. Does backend 429 rate-limit headers include `Retry-After`? If so, client ignores it.

---

**Status:** DONE_WITH_CONCERNS
**Summary:** 4 CRITICAL (auth double-refresh race, header injection via tamperable Hive, unvalidated server payload, Firebase error leak), 10 IMPORTANT, 3 NITS. Scout claim A1 (interceptor ordering) rejected — timing is correct. Top fix priorities: C1 (auth refresh), C3 (schema validation), I1 (deep-link auth bypass), I2 (cross-user conversationId leak).
