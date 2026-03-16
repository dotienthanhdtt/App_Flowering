# Code Review: SubscriptionService Implementation

**Date:** 2026-03-14
**Branch:** feat/revenucat-payment
**Reviewer:** code-reviewer

---

## Scope

- `lib/features/subscription/services/subscription-service.dart` (NEW, 117 lines)
- `lib/app/global-dependency-injection-bindings.dart` (MODIFIED, 91 lines)
- Supporting context: `subscription-model.dart`, `revenuecat-service.dart`, `api_endpoints.dart`

## Overall Assessment

Implementation is clean and correct. All phase-04 requirements are fulfilled. The service is well within the 200-line limit, follows GetxService patterns consistently, and aligns with the "backend wins" design decision. One warning and two info-level observations follow.

---

## Critical Issues

None.

---

## High Priority

None.

---

## Medium Priority (Warnings)

### 1. `_customerInfoSubscription` never re-established after `onUserLoggedIn`

**File:** `subscription-service.dart` lines 79–89

`_listenToCustomerInfoChanges()` is called only once in `init()`. The `RevenueCatService` stream (`_customerInfoController`) is a broadcast stream, so re-listening is safe, but the current code does not re-subscribe after a logout/login cycle if the stream emits between sessions.

In practice this is unlikely to cause a bug today because `RevenueCatService` holds the same broadcast `StreamController` for its lifetime and does not close/reopen it. However, it is a latent fragility: if `RevenueCatService` were ever re-created (e.g., fenix rebind triggered), the existing `_customerInfoSubscription` would point to the old stream. Worth noting for future refactors.

No code change required now — just document the assumption that `RevenueCatService` is a singleton for the app lifetime.

---

## Low Priority (Info)

### 2. `_clearCache()` is awaited in `onUserLoggedOut` but not in plan spec

**File:** `subscription-service.dart` line 56 vs plan line 77

The implementation correctly `await`s `_clearCache()`. The plan omitted the `await`. This is a positive deviation — the implementation is more correct than the plan.

### 3. Cached `toJson` serialises `plan` and `status` as `UPPERCASE` strings

**File:** `subscription-model.dart` lines 48–49

`toJson()` calls `.name.toUpperCase()`. `fromJson()` calls `.toLowerCase()` on input, so round-tripping through the Hive cache works. No bug, but the asymmetry (UPPER out, lower comparison in) could confuse a future developer reading the cache. The backend contract should also be verified to accept UPPERCASE if `toJson` is ever sent upstream. Not in scope for SubscriptionService itself; flagging for awareness.

---

## Edge Cases Verified by Scout

| Edge Case | Verdict |
|---|---|
| RC stream fires before `onUserLoggedIn` completes | Safe — `fetchSubscriptionFromBackend` is idempotent; backend state wins regardless of order |
| `getUserId()` returns null at app start | Handled — `onUserLoggedIn` early-returns on null |
| `StorageService.getPreference` returns null on first launch | Handled — `_loadCachedSubscription` guards with null check |
| Corrupted JSON in Hive cache | Handled — `jsonDecode` wrapped in try/catch, silently retains free tier |
| `RevenueCatService.isConfigured == false` (missing API key) | Handled in both `onUserLoggedIn` and `_listenToCustomerInfoChanges` |
| `onClose` called before stream subscribed | Safe — `_customerInfoSubscription?.cancel()` null-safe cancel |
| Double `onUserLoggedIn` call (rapid re-auth) | Two concurrent `fetchSubscriptionFromBackend` calls possible; both are idempotent GET requests; last writer to `.value` wins which is fine since backend returns same data |

---

## DI Registration Order

`initializeServices()` in `global-dependency-injection-bindings.dart` initialises dependencies in the correct order:

```
AuthStorage → StorageService → ConnectivityService → AudioService
  → ApiClient → RevenueCatService → SubscriptionService
```

All four dependencies that `SubscriptionService` resolves via `Get.find<>()` at field-declaration time are already in the container before `Get.put(SubscriptionService())` is called. No ordering issue.

The `lazyPut` registrations in `AppBindings.dependencies()` are also fine — lazy resolution defers `Get.find()` until first access, so declaration order there is irrelevant.

---

## Positive Observations

- `dart:convert` used for JSON caching rather than adding a new dependency — KISS.
- `_revenueCatService.isConfigured` checked consistently before every RC call.
- `StreamSubscription` stored and cancelled in `onClose()` — no memory leak.
- `fetchSubscriptionFromBackend` is a public method, enabling manual refresh from a controller without exposing internals.
- `SubscriptionModel.free()` used as safe default throughout — no nullable state exposed to callers.
- File is 117 lines, well under the 200-line limit.

---

## Flutter Analyze Results

```
info • file_names (kebab-case filenames) — 2 issues
```

Both are pre-existing project-wide conventions (the project deliberately uses kebab-case per `development-rules.md` File Naming section). Not a defect.

Zero warnings or errors.

---

## Plan TODO Checklist (Phase 4)

- [x] Create subscription-service.dart
- [x] Implement onUserLoggedIn (RC logIn + backend fetch)
- [x] Implement onUserLoggedOut (RC logOut + clear state)
- [x] Implement fetchSubscriptionFromBackend
- [x] Implement CustomerInfo stream listener
- [x] Implement Hive caching (cache/load/clear)
- [x] Run `flutter analyze`

All phase-04 todos are complete.

---

## Recommended Actions

1. **No blocking issues** — implementation is ready for phase-05 (controllers).
2. Add a brief inline comment in `init()` noting that `_listenToCustomerInfoChanges` is intentionally called once per service lifetime, relying on `RevenueCatService` singleton stability (addresses warning #1).
3. Verify backend `/subscriptions/me` payload uses matching case for `plan`/`status` fields to ensure `fromJson` round-trips correctly.

---

## Unresolved Questions

- Does the backend `POST /subscriptions/me` (if it exists for purchase webhook confirmation) expect `plan` as `UPPERCASE` or `lowercase`? The cache round-trip is fine, but upstream writes should be confirmed.
- Is there a plan to call `onUserLoggedIn` / `onUserLoggedOut` from the auth controller? Phase 5 plan file should clarify the call site.
