# Auth / Subscription / L10n / Entry-point Review — `feat/update-onboarding`

**Summary:** Good overall structure; token storage and l10n parity are solid, but the subscription identity-link wiring is effectively disabled (RevenueCat `logIn`/`logOut` never called), dev HTTP logger leaks bearer tokens and password/id_token request bodies, and several security-sensitive errors rely on untranslated literal strings.

---

## Critical (must fix)

### C1. `SubscriptionService.onUserLoggedIn/onUserLoggedOut` are defined but never called
`lib/features/subscription/services/subscription-service.dart:36-53` vs. `lib/features/auth/controllers/auth_controller.dart:119-142` and `lib/features/profile/controllers/profile-controller.dart:33-48`.
- On login `_handleAuthSuccess` saves tokens and routes home, but never calls `SubscriptionService.onUserLoggedIn()`. Result: `Purchases.logIn(userId)` is never invoked — a purchase will be attributed to the anonymous RC user; when the same account is used on another device, `restorePurchases` won't find it.
- On logout `_performLogout` clears tokens + Hive + Firebase but never calls `onUserLoggedOut()`. If user A logs out and user B logs in on the same device, RC identity stays on user A until process restart — user B can leak A's premium entitlement through `SubscriptionGate.isPremium`.
- `fetchSubscriptionFromBackend()` is therefore also never triggered on login; `currentSubscription` stays `free()` until the next paywall open.
**Fix:** In `_handleAuthSuccess` (both email + Firebase paths) call `Get.find<SubscriptionService>().onUserLoggedIn()` after `_authStorage.saveUserId`. In `_performLogout`, call `onUserLoggedOut()` before `clearTokens`.

### C2. Dev HTTP logger prints raw `Authorization: Bearer <token>` and request bodies with passwords/id_token
`lib/core/network/http_logger_interceptor.dart:118-145`.
- The Authorization redaction is commented out (lines 128-132) so bearer tokens print as part of the curl every request.
- `_buildCurl` and `onRequest` do **not** apply `_redactSensitiveFields` to `options.data`; only `onResponse` redacts, and only for auth endpoints. So POST bodies to `/auth/login` / `/auth/register` / `/auth/firebase` / `/auth/reset-password` print raw `password`, `id_token`, `new_password`, `reset_token` to the console.
- Dev console logs routinely end up in shared terminals, Sentry/Crashlytics dev capture, QA recordings, issue screenshots.
**Fix:** Uncomment Authorization redaction. Run `_redactSensitiveFields(options.data)` before jsonEncode in `_buildCurl`. Add `'password'`, `'new_password'`, `'reset_token'` to `_sensitiveKeys`.

### C3. Hardcoded Google Web Client ID in source
`lib/features/auth/controllers/auth_controller_social.dart:15-16`.
A production OAuth client ID `898715197112-...apps.googleusercontent.com` is checked into git. Not a secret in the strict sense (public client), but it should live alongside the other OAuth config in `.env.*` + `EnvConfig` so staging/prod and any future rotation are consistent with the rest of the config. Today swapping envs requires a code change.
**Fix:** Move to `EnvConfig.googleServerClientId`; read from `.env.dev` / `.env.prod`.

### C4. `AuthInterceptor._triggerLogout` routes to `/login` but never clears app state
`lib/core/network/auth_interceptor.dart:86-89, 123-125`.
When refresh fails the interceptor clears tokens and pushes `/login`, but:
- Does not call `StorageService.clearAll()` — onboarding progress / active language survive.
- Does not call `LanguageContextService.clear()` — prior user's `x-language` header persists.
- Does not call `FirebaseAuth.instance.signOut()` — Firebase session still active.
- Does not call `SubscriptionService.onUserLoggedOut()` (compounds C1).
If session expires mid-use, the next user who logs in on the same device inherits the old user's language context and subscription state.
**Fix:** Extract `ProfileController._performLogout` body into a shared `AuthSessionManager.forceLogout()` and call from both the interceptor and profile.

---

## Important

### I1. Logout swallows all errors and shows untranslated string
`lib/features/profile/controllers/profile-controller.dart:43-45`. `catch (_)` with literal `'Something went wrong'` — not `.tr`, user can't see what failed, and a partial logout (e.g. tokens cleared, Hive failed) leaves the device half-authenticated. Either propagate the specific error or force-route to onboarding even on error so stale state never blocks logout.

### I2. `AuthInterceptor` caches hardcoded `/login` route
`lib/core/network/auth_interceptor.dart:124`. Uses the raw string `/login` instead of `AppRoutes.login` — will silently break if the route constant changes.

### I3. `onUserLoggedIn` proceeds even when RC init failed
`lib/features/subscription/services/subscription-service.dart:41-45` checks `_revenueCatService.isConfigured` and skips `logIn` if not configured, then still calls `fetchSubscriptionFromBackend()`. Backend path is fine, but subsequent `purchasePackage` calls from PaywallController will throw `StateError` which gets swallowed as "Purchase failed. Please try again." (`paywall-controller.dart:55`). Consider explicitly disabling the purchase CTA when `revenueCatService.isConfigured == false`.

### I4. Hardcoded English strings in paywall & logout paths
- `paywall-controller.dart:50,55`: `'Purchase failed. Please try again.'`
- `paywall-screen.dart:152`: `'Could not load subscription plans.'`
- `profile-controller.dart:44`: `'Something went wrong'`
Add keys to both l10n files and use `.tr`.

### I5. `PaywallBottomSheet.show()` assumes controller isn't disposed
`lib/features/subscription/widgets/paywall-bottom-sheet.dart:14-16`. If the sheet is shown, the user dismisses, and GetX disposes `PaywallController` (fenix can re-create), the next call may race. Consider `Get.create<PaywallController>(() => ...)` or explicit `Get.delete` in `Get.bottomSheet`'s `onWillPop`.

### I6. `forgot_password_controller.resendOtp` has no max-attempts guard
`lib/features/auth/controllers/forgot_password_controller.dart:87-108`. Only guarded by 47-second UI countdown. A malicious client can bypass and hammer the endpoint — backend MUST rate-limit (client check insufficient). Flag for backend review.

### I7. Password reset CTA routes with stale `_resetToken`
`forgot_password_controller.dart:146-148`. On success it clears `_resetToken` then routes. If backend returns success but `Get.offNamedUntil` races with a follow-up click, double-submit is possible. Consider disabling CTA or setting `isLoading` first. Minor, but the same controller is reused for several screens.

### I8. Firebase ID token returned by `getIdToken()` expires after ~1 hour
`auth_controller_social.dart:92-104`. Fine for the initial POST to `/auth/firebase`, but if the request is retried by Dio over a slow network it may be stale. Consider `getIdToken(true)` (force refresh) to avoid edge-case rejection.

### I9. Subscription model trusts backend `plan` strings silently
`lib/features/subscription/models/subscription-model.dart:68-82`. `orElse: SubscriptionPlan.free` / `orElse: SubscriptionStatus.expired` — a typo in a backend payload silently downgrades an active user to free. Log (at least in debug) when falling through to orElse so silent misparses don't go unnoticed.

---

## Minor

- `auth_controller_social.dart:34, 67`: `debugPrint('Google sign-in error: $e')` — `e` for `FirebaseAuthException` contains `.message` which can include email addresses. In release builds `debugPrint` is a no-op, but add `kDebugMode` guard for consistency with the rest of the codebase.
- `LoginGateBottomSheet._getAuthController()` (line 17-22) does `Get.put(AuthController())` bypassing `AuthBinding`. Works, but inconsistent with route-based DI and can leak controller lifecycle across sheets.
- `login_email_screen.dart` and `signup_email_screen.dart` allow password field paste. Consider adding `enableInteractiveSelection: true` + `obscuringCharacter` explicitly if paste-protection is wanted (usually not — password managers need paste).
- `main.dart:14-17` orientation lock is awaited but `setSystemUIOverlayStyle` (line 20) is not. Ordering is fine, but inconsistent.
- `storage_service.dart:44` — `await Hive.deleteFromDisk()` on first init failure wipes onboarding progress. Acceptable as a recovery but consider surfacing via crash reporter so silent data loss is observable.
- Init order deviates from CLAUDE.md. CLAUDE.md says: `AuthStorage → StorageService → ConnectivityService → AudioService → ApiClient`. Actual critical path: `AuthStorage → StorageService → LanguageContext → OnboardingProgress → ApiClient`; `Connectivity`/`Audio` are deferred. Either update CLAUDE.md or align. Functionally correct.

---

## L10n Parity Report

**EN keys: 258 | VI keys: 258 | missing in either: 0**

Keys with `@placeholder` (potential trParams):
- `email_hint` → `{example}` (EN + VI match)
- `lesson_count` → `{count}` (EN + VI match)

`trParams` is not currently used anywhere in the codebase (no runtime placeholder substitution), so no active placeholder mismatch bugs.

All l10n keys referenced by auth code (`google_sign_in_failed`, `apple_sign_in_failed`, `firebase_token_error`, `auth_error_*`, `password_reset_*`, `subscription_*`) verified to exist in both files.

Hardcoded English strings NOT using `.tr` (also listed in I4):
- `paywall-controller.dart:50,55` — `'Purchase failed. Please try again.'`
- `paywall-screen.dart:152` — `'Could not load subscription plans.'`
- `profile-controller.dart:44` — `'Something went wrong'`
- `api_exceptions.dart:73,142,157` — several fallback `'Something went wrong'`
- `base_controller.dart:67` — fallback error message

---

## Adversarial Findings

- **Malicious email input:** `GetUtils.isEmail` is regex-based; fine. `loginEmailController.text.trim()` is sent as-is to backend — backend must escape/parameterize. No client-side injection risk.
- **Token tampering on device:** `FlutterSecureStorage` uses iOS Keychain + Android EncryptedSharedPreferences — acceptable. Cached token in `_cachedToken` is an in-memory mirror; cleared on `clearTokens`. No disk-level exposure.
- **Subscription purchased then refunded:** Backend is source of truth (`SubscriptionService.fetchSubscriptionFromBackend`), but RC listener (`_listenToCustomerInfoChanges`) only syncs on `hasPaidEntitlement && !isPremium` — it never re-fetches on downgrade/expiry. Cached `currentSubscription` remains premium until next login/paywall open. **Flag for important review.** Fix: always re-fetch on CustomerInfo change, not just on paid→unpaid transitions.
- **User changes locale mid-purchase:** GetX `Get.updateLocale()` is app-global; purchase flow uses RC product identifiers that don't depend on locale — safe. Error strings re-resolve on next `.tr` read — safe.
- **idToken replay:** Firebase `getIdToken()` signs with Firebase project's private key, has ~1h expiry, audience-bound — replay is a backend concern. Client looks correct.
- **Logout then app resume:** Token cleared from keychain + cached token nulled. `StorageService.clearAll()` preserves `hasCompletedLogin` (intentional). However `LanguageContextService` **is** cleared in profile logout but **not** in interceptor-triggered logout (see C4). Social logout via profile calls `FirebaseAuth.signOut()` but auth error paths (`signInWithGoogle` catch) do not — user may retain a Firebase session even after backend call fails.
- **Google Sign-In cancelled:** handled (line 20 early return). Apple Sign-In cancelled: handled (`SignInWithAppleAuthorizationException`).
- **Purchase cancelled mid-flow:** handled (`purchaseCancelledError` skipped from error message). Network failure during purchase: caught → shows generic "Purchase failed" (should be translated).

---

## Unresolved Questions

1. Does the backend `/auth/firebase` endpoint verify the Firebase audience/issuer, or just trust the idToken? (out-of-scope, backend review)
2. Should `SubscriptionGate.isPremium` fail-closed (return false) when `SubscriptionService` state is stale (e.g. offline >24h)? Current behavior is fail-open to the last known value.
3. Is RevenueCat Sandbox vs Production distinguished by env or build config? Both keys load from same `.env`; if a dev accidentally runs prod with sandbox keys, behavior is undefined.
4. Should `clearOrphanBoxesOnce` also delete `access_token` / `refresh_token` from `flutter_secure_storage` on install of a new major version? (currently no versioning)
