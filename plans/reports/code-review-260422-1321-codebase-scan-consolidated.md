# Codebase Scan — Consolidated Review (feat/update-onboarding)

**Date:** 2026-04-22 13:21
**Scope:** Full Flutter app (`lib/`), ~16.6k LoC across 201 Dart files.
**Reviewers:** 4 parallel code-reviewer subagents + adversarial pass.
**Branch state:** 248 files changed vs `main`, +19.5k/-2.5k LoC.

Source reports:
- `code-reviewer-260422-1321-scenario-chat-features.md`
- `code-reviewer-260422-1321-onboarding-home-features.md`
- `code-reviewer-260422-1321-core-infrastructure.md`
- `code-reviewer-260422-1321-auth-subscription-l10n.md`

---

## Verdict

Ship-blocking: **7 Critical** issues confirmed via direct source verification. Branch **should not merge** until C1–C7 resolved.

Positive signal: onboarding progress-resume architecture, Hive token storage, l10n parity (EN/VI = 258/258, 0 missing), and GetX lifecycle hygiene are solid. Problems are concentrated in auth infrastructure, subscription wiring, and three UI-correctness bugs.

---

## Critical — Must Fix Before Merge

### C1. HTTP logger leaks Bearer tokens in dev builds
**File:** `lib/core/network/http_logger_interceptor.dart:127-133`
**Verified:** Authorization redaction literally commented out. Every dev request prints full `Authorization: Bearer eyJ...` in console/curl output.
**Exploit:** Token capture via screen-share, bug-report screenshot, Sentry dev capture, QA video recording → full account takeover.
**Fix:** Uncomment lines 128-132 so Authorization renders as `Bearer ***`.

### C2. HTTP logger leaks refresh_token, passwords, id_token in request bodies
**File:** `lib/core/network/http_logger_interceptor.dart:135-142`
**Verified:** `_buildCurl` does `jsonEncode(options.data)` without redaction; `_redactSensitiveFields` only runs on responses. POST to `/auth/login`, `/auth/refresh`, `/auth/firebase`, `/auth/reset-password` prints raw credentials.
**Fix:** Apply `_redactSensitiveFields` to `options.data` before jsonEncode in `_buildCurl`; add `password`, `new_password`, `reset_token`, `id_token` to `_sensitiveKeys`.

### C3. Token-refresh triggers N+1 refreshes; logout on rotating-token backends
**File:** `lib/core/network/auth_interceptor.dart:46-91`
**Verified:** `QueuedInterceptor` serializes `onError`, so the `if (_refreshGate != null)` waiter branch is effectively dead code — by the time call B enters onError, call A has completed and reset `_refreshGate = null`. Every failing 401 triggers its own sequential refresh.
**Impact:** 5 parallel requests with expired token → 5 sequential refreshes. If backend rotates refresh_tokens (invalidating old on use) and has already burned the first token, subsequent refreshes may fail → phantom logout.
**Fix:** Snapshot token in `options.extra['_auth_token']` in `onRequest`. In `onError`, if stored token ≠ `cachedAccessToken`, skip the refresh path and retry with current token.

### C4. `_triggerLogout` leaves stale session state on device
**File:** `lib/core/network/auth_interceptor.dart:86-89, 123-125`
**Verified:** `_triggerLogout` only calls `Get.offAllNamed('/login')`. No `StorageService.clearAll()`, no `LanguageContextService.clear()`, no `FirebaseAuth.signOut()`, no `SubscriptionService.onUserLoggedOut()`.
**Impact:** User A's session expires → interceptor forces /login. User B signs in on same device → inherits A's `x-language` header, active onboarding progress, RC identity, potentially A's premium entitlement.
**Fix:** Extract `ProfileController._performLogout` body into shared `AuthSessionManager.forceLogout()`; call from both interceptor and profile screen. Route constant: use `AppRoutes.login`, not raw `'/login'`.

### C5. Subscription identity never linked — `onUserLoggedIn`/`onUserLoggedOut` are zero-call-site
**File:** `lib/features/subscription/services/subscription-service.dart:36-53`
**Verified:** `grep -rn "onUserLoggedIn\|onUserLoggedOut" lib/` returns only the declarations. Nothing calls them.
**Impact:**
  - `Purchases.logIn(userId)` never fires → purchases attributed to anonymous RC user → `restorePurchases` won't find them on another device.
  - Same device, user-switch: RC identity sticks to user A → user B may leak A's premium state through `SubscriptionGate.isPremium`.
  - `fetchSubscriptionFromBackend()` never runs on login → `currentSubscription` stays `free()` until paywall opens.
**Fix:** In `auth_controller.dart:_handleAuthSuccess` (both email + Firebase paths) call `Get.find<SubscriptionService>().onUserLoggedIn()` after `_authStorage.saveUserId`. In `profile-controller.dart:_performLogout` call `onUserLoggedOut()` before clearing tokens.

### C6. Unsanitized HTML rendering of server-controlled string
**File:** `lib/features/chat/widgets/grammar_correction_section.dart:48`
**Verified:** `HtmlWidget(correctedText, …)` renders `/ai/chat/correct` response with no tag allowlist, no `factoryBuilder`, no `onTapUrl` guard.
**Mitigation already in place:** HTTPS prevents MITM; `HtmlWidget` doesn't execute JS. But tap-hijack via `<a href="https://phish">` is viable on any backend compromise.
**Fix:** Pass a strict `factoryBuilder` that allows only `<b>`, `<i>`, `<u>`, `<strong>`, `<em>`, `<span>`. Or, if the correction is only emphasis, replace with `AppText` + `TextSpan` styling.

### C7. ObxError crash on entry to scenario chat
**File:** `lib/features/scenario-chat/views/scenario_chat_screen.dart:31`
**Verified:** `scenario_chat_controller.dart:29` declares `final String scenarioTitle` (plain value, not `.obs`). Wrapping non-reactive read in `Obx()` throws `ObxError: the improper use of a GetX has been detected` in GetX 4.6.
**Fix:** Remove `Obx(…)` wrapper: `ChatTopBar(title: controller.scenarioTitle)`.

---

## High-Impact Important (fix this sprint)

| # | File:line | Issue | Fix |
|---|-----------|-------|-----|
| I1 | `scenario-chat/controllers/…_translation.dart:26-29` | Word/sentence translation in scenario chat omits `sourceLang`/`targetLang` → silently defaults to EN→VI for every locale | Pass `_targetLanguage` + user native, mirror ai_chat variant |
| I2 | `onboarding-welcome-screen.dart:47`, `welcome-back-screen.dart:46`, `onboarding-welcome-screen.dart:103` | Translation keys `onboarding_welcome_headline`, `welcome_back_headline`, `log_in` undefined in both EN & VI files | Add to both l10n files |
| I3 | `onboarding/controllers/splash_controller.dart:37-40` | Splash hardcoded `Future.wait([Future.delayed(3s), _validateToken()])` → returning users wait ≥3s every launch | Reduce min-hold to ≤600ms or show splash until first frame |
| I4 | `chat/controllers/ai_chat_controller_session.dart:114` | `_progressSvc.setChatConversationId(_conversationId!)` — `!` on possibly-null backend field → NSE crash | Guard: `if (_conversationId == null) { errorMessage.value = 'chat_session_error'.tr; return; }` |
| I5 | `core/services/storage_service.dart:43-44` | Box-open failure calls `Hive.deleteFromDisk()` → wipes ALL Hive boxes, not just corrupted one | Use `Hive.deleteBoxFromDisk(boxName)` targeted delete |
| I6 | `profile-controller.dart:44`, `base_controller.dart:67`, `api_exceptions.dart:142,157` | Hardcoded `'Something went wrong'` English literal ships to VI users | Use `'unknown_error'.tr` |
| I7 | `auth/controllers/auth_controller_social.dart:15-16` | Google Web Client ID hardcoded in source — staging/prod swap requires code change | Move to `EnvConfig.googleServerClientId` + `.env.*` |
| I8 | `subscription/services/subscription-service.dart` (CustomerInfo listener) | Only syncs on `hasPaidEntitlement && !isPremium` — never re-fetches on downgrade/expiry. Cached `currentSubscription` stays premium until next login | Always re-fetch on CustomerInfo change |
| I9 | `core/network/retry_interceptor.dart:49-55` | Recursive retry may leak handler / miss retryCount increment on inner DioException | Convert to iterative loop |
| I10 | `auth_interceptor.dart:99-103` | Refresh uses throwaway `Dio()` — no retry on transient 5xx/connect-timeout → one flaky network blip = logout | Share configured refresh client with single-shot retry |
| I11 | Multiple onboarding + profile + vocabulary screens use raw `ElevatedButton`/`OutlinedButton`/`TextField` | Violates CLAUDE.md base-widget rule (`AppButton`/`AppTextField`) | Migrate to shared base widgets |
| I12 | `ai_chat_controller_voice.dart:50`, `scenario_chat_controller_voice.dart:46` | Transcription result replaces text in LAST user message by position. Double-tap voice sends corrupt wrong bubble | Capture `userMessageId` when bubble added; match by id |
| I13 | `onboarding/widgets/scenario_card.dart:218` violates Text→AppText, and file is 225 lines (>200 cap) | Two-in-one | Extract `_CardBody`/`_LevelDots`/`_PlaceholderBg` subfiles, use AppText |

---

## Files Over 200-Line Rule

| File | Lines | Action |
|------|-------|--------|
| `core/network/api_client.dart` | 240 | Split SSE parser, auth-retry logic |
| `features/chat/views/ai_chat_screen.dart` | 228 | Extract overlay + error banner + list |
| `features/onboarding/widgets/scenario_card.dart` | 225 | Extract body/dots/placeholder |
| `features/auth/views/login_email_screen.dart` | 219 | Extract validation + social section |
| `features/scenarios/views/scenario_detail_screen.dart` | 212 | Extract header / content sections |
| `features/scenario-chat/views/scenario_chat_screen.dart` | 208 | Extract message list / input areas |
| `core/network/api_exceptions.dart` | 208 | Group by exception type |
| `features/onboarding/controllers/onboarding_controller.dart` | 202 | Split `_hydrateFromProgress` into part file |

(l10n files at 343 are data, not code — exempt.)

---

## Adversarial Findings (Red-Team)

Confirmed exploit paths beyond the Critical list:

- **A1.** Parallel 401 with rotating refresh-token backend → phantom logout (see C3).
- **A2.** Empty `reply` from `/scenario/chat` → UI renders nothing, user sees typing bubble vanish → perceives crash. Fix: fallback message.
- **A3.** Very long AI reply → `AppTappablePhrase` builds thousands of `TapGestureRecognizer`s with no virtualization → OOM risk.
- **A4.** Scenario chat `ever<String?>(_langCtx.activeCode)` fires `Get.back()` on ANY change — can pop two routes if pushed during a race.
- **A5.** `/scenario/chat` STT upload: user cancels, temp file purged, `MultipartFile.fromFile` throws, silently caught (`catch (_)`) → transcription lost with no analytics.
- **A6.** `.env.dev` missing in bundle → `dotenv.load` throws at `main.dart:29` before Firebase init → silent launch crash with no crash-reporter.
- **A7.** Binding calls `Get.back()` during `dependencies()` (scenario_chat_binding.dart:12, scenario_detail_binding.dart:12) → partial route stack + un-registered controller → next `Get.find<…>()` throws.
- **A8.** Non-deterministic user message IDs `user_${DateTime.now().millisecondsSinceEpoch}` — two rapid sends in same ms collide → grammar correction applied to wrong bubble. (Scenario-chat already uses UUID; chat does not.)

---

## Scoring

| Domain | Critical | Important | Minor | Health |
|--------|----------|-----------|-------|--------|
| Scenario/chat features | 4 | 9 | 6 | amber |
| Onboarding/home | 3 | 8 | 10 | amber |
| Core infrastructure | 3 | 8 | 9 | red |
| Auth/subscription/l10n | 4 | 9 | 6 | red |
| **Total (deduplicated)** | **7** | **13 tier-1** | — | **red** |

---

## Recommended Remediation Order

**Phase 1 — Security & data integrity (blocks merge)**
1. C1 + C2 (logger redaction) — single file, 5 lines
2. C5 (subscription identity wire-up) — 2 controllers, ~10 lines
3. C4 (shared forceLogout) — extract method, 2 call sites
4. C3 (token snapshot + skip refresh if already fresh)
5. C7 (remove stray Obx) — 1 line

**Phase 2 — UX correctness (same sprint)**
6. C6 (HtmlWidget allowlist or AppText swap)
7. I2 (missing translation keys)
8. I4 (null-guard on `_conversationId!`)
9. I1 (scenario-chat translation lang args)

**Phase 3 — Polish**
10. I5 (targeted Hive delete)
11. I3 (splash min-hold)
12. Remaining I + file-size splits

---

## Suggested Plan Structure

Create `plans/260422-1321-codebase-review-fixes/`:
- `plan.md` — overview
- `phase-01-security-fixes.md` — C1, C2, C3, C4, C5
- `phase-02-ui-correctness.md` — C6, C7, I1, I2, I4
- `phase-03-hardening.md` — I5, I8, I10, storage recovery
- `phase-04-widget-compliance.md` — I11, I13, file splits

---

## Unresolved Questions

1. **Backend refresh-token rotation policy** — does it invalidate old refresh_tokens on use? Determines whether C3 causes logouts or just wastes calls.
2. **Backend `conversation_id` contract** — can `/onboarding/chat` POST return 200 with null conversation_id? If no, I4 is theoretical; if yes, it's a live crash path.
3. **`correctedText` format contract** — is HTML intentional (rich `<b>` emphasis) or should backend return plain text? Shapes C6 fix.
4. **Hive `deleteFromDisk` vs targeted delete on `StorageService.init` failure** — is wipe-all intentional for corruption recovery, or an oversight?
5. **Google Sign-In client-id** — any reason it's not in `.env.*` like other OAuth config?
6. **RC Sandbox vs Production** — both keys load from same `.env`; how is sandbox/prod switching enforced?
