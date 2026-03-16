---
date: 2026-03-14
reviewer: code-reviewer
phase: Phase 05 — Subscription Controllers
---

## Code Review Summary

### Scope
- Files: `subscription-controller.dart` (24 LOC), `paywall-controller.dart` (66 LOC), `subscription-binding.dart` (13 LOC)
- Total LOC: 103 across 3 files
- Context read: `base_controller.dart`, `subscription-service.dart`, `revenuecat-service.dart`, `offering-model.dart`, `subscription-model.dart`, `global-dependency-injection-bindings.dart`
- Static analysis: 0 errors, 0 warnings, 3 info (file_names — intentional per project kebab-case convention)

### Overall Assessment

All three files are clean, minimal, and correct. The implementation follows the project architecture faithfully. No critical or high-priority issues found. Two medium items around a purchase-state race condition and a missing `StateError` guard. One low-priority note on binding scope.

---

### Critical Issues

None.

---

### High Priority

None.

---

### Medium Priority

**1. `purchase()` race condition — concurrent purchases not guarded**

File: `paywall-controller.dart`, line 39.

`isPurchasing` is set to `true` but the method does not bail out if it is already `true`. A user who taps the purchase button twice in rapid succession before the first call resolves will fire two simultaneous `purchasePackage` calls, each updating `isPurchasing` and `errorMessage` independently. The `finally` block of the first call will set `isPurchasing.value = false` while the second is still running.

Fix: guard at the top of `purchase()`:

```dart
Future<bool> purchase(OfferingModel offering) async {
  if (isPurchasing.value) return false;   // add this guard
  isPurchasing.value = true;
  ...
}
```

**2. `StateError` from `RevenueCatService._ensureConfigured()` is unhandled in `purchase()`**

File: `paywall-controller.dart`, line 39–55.

`purchase()` catches `PlatformException` but not `StateError`. If `RevenueCatService` is somehow not configured (e.g., API key missing in env, test device), `_ensureConfigured()` throws `StateError`, which propagates uncaught from `purchase()`, bubbles past `apiCall`, and surfaces as an unhandled error. `fetchOfferings()` and `restorePurchases()` route through `apiCall` which catches the generic `catch (e)` branch, so they are fine — but `purchase()` manages its own try/catch.

Fix: extend the catch block in `purchase()`:

```dart
} on PlatformException catch (e) {
  final errorCode = PurchasesErrorHelper.getErrorCode(e);
  if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
    errorMessage.value = 'Purchase failed. Please try again.';
  }
  return false;
} catch (_) {
  errorMessage.value = 'Purchase failed. Please try again.';
  return false;
}
```

---

### Low Priority

**3. `SubscriptionBinding` registers both controllers with `lazyPut` — consider whether `PaywallController` should be scoped to paywall route only**

File: `subscription-binding.dart`.

Both controllers are registered in the same binding. `SubscriptionController` makes sense as a persistent route-scoped singleton (used broadly for `isPremium` gating). `PaywallController` is self-contained and calls `fetchOfferings()` in `onInit`, so it benefits from route-level instantiation. If both are attached to the same route, the paywall fetches offerings even when the user never opens the paywall screen.

No action required if both screens share a single route binding — this is an architectural decision. Worth noting if they are on separate routes.

---

### Edge Cases Found by Scouting

- **`_revenueCatService` not configured at binding time**: `PaywallController` calls `Get.find<RevenueCatService>()` at instantiation. Services are registered globally via `AppBindings` and initialized in `main.dart`, so this is safe. However `SubscriptionBinding` does not re-register or guard services — if a test creates `PaywallController` without prior service registration, `Get.find` will throw. This is a test harness concern, not a production concern.
- **Empty offerings list after RC returns `null` current offering**: `fetchOfferings()` correctly handles `rcOfferings.current == null` by leaving `offerings` empty. The view must show an appropriate empty state — that is a view-layer concern, not a controller bug.
- **`SubscriptionController.subscription` getter exposes the service's `Rx` directly**: This is intentional (proxy, not copy). Any mutation via `subscription.value = ...` from outside the controller would bypass the service's cache logic. There is no setter, and the field is `final` in the service, so this is safe as long as callers only read.

---

### Positive Observations

- **Correct BaseController usage**: Neither controller redeclares `isLoading` or `errorMessage` — they come from `BaseController` and are used directly. This is exactly right.
- **PlatformException cancellation handling**: `purchaseCancelledError` is silently ignored (no error message set), which is the correct UX behavior — user-initiated cancellations should not show error toasts.
- **Thin delegation pattern**: `SubscriptionController` has zero business logic — all state lives in `SubscriptionService`. The controller is a pure reactive facade. YAGNI/KISS fully respected.
- **`restorePurchases` correctly chains backend sync**: After restoring, `fetchSubscriptionFromBackend()` is called, which keeps the backend as source of truth.
- **Resource cleanup in services**: `RevenueCatService` and `SubscriptionService` both cancel listeners/subscriptions in `onClose()` — controllers do not need additional cleanup.
- **File sizes**: All three files are well under 200 lines (103 combined).
- **DI correctness**: Both `RevenueCatService` and `SubscriptionService` are registered globally in `AppBindings` before controllers are instantiated via `SubscriptionBinding`, so `Get.find` calls are safe.
- **`fenix: true` on global services**: Prevents `Get.find` failures after service disposal during navigation.

---

### Recommended Actions

1. **(Medium)** Add `if (isPurchasing.value) return false;` guard at the top of `purchase()` to prevent concurrent purchase calls.
2. **(Medium)** Add a generic `catch (_)` block in `purchase()` to handle `StateError` from `_ensureConfigured()`.
3. **(Low / optional)** If `PaywallController` will be bound to a dedicated paywall route, split it into its own `PaywallBinding` to avoid eagerly loading offerings on unrelated screens.

---

### Metrics

- Type coverage: Strong — all fields typed, no `dynamic` leakage in controllers
- Linting issues: 0 errors, 0 warnings (3 info/file_name — intentional project convention)
- File size compliance: Pass (all under 200 lines)
- BaseController pattern compliance: Pass
- YAGNI/KISS/DRY compliance: Pass

---

### Unresolved Questions

- Is `PaywallController` bound to the same route as `SubscriptionController`, or to a separate paywall route? This affects point 3 above.
- Does the paywall view handle the empty `offerings` list (zero packages returned from RevenueCat)? Not visible in this review scope.
