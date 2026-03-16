---
type: code-review
date: 2026-03-13
scope: lib/features/subscription/services/revenuecat-service.dart
---

# Code Review: RevenueCatService

## Scope
- **File:** `lib/features/subscription/services/revenuecat-service.dart`
- **LOC:** 74
- **Focus:** New file review -- thin SDK wrapper for purchases_flutter v8.11.0
- **Dependents found:** None yet (service not wired into any controller or binding)

## Overall Assessment

Clean, well-scoped service. Correctly follows the "thin wrapper, no business logic" brief. The file is short, readable, and properly uses GetxService lifecycle. Two issues worth addressing before integration (one High, one Medium), plus minor observations.

---

## Critical Issues

None.

---

## High Priority

### 1. `_isConfigured` guard missing on SDK calls

If `init()` silently returns early (empty API key, caught exception), `_isConfigured` stays `false` but nothing prevents callers from invoking `logIn()`, `getOfferings()`, etc. Those calls will throw unrelated PlatformExceptions from the SDK because `Purchases.configure()` was never called.

**Impact:** Confusing crash at runtime on misconfigured environments (dev machines with no `.env` keys).

**Recommendation:** Either (a) throw from each method when `!_isConfigured`, or (b) guard at init and log clearly. Option (a) is safer for a wrapper:

```dart
void _ensureConfigured() {
  if (!_isConfigured) {
    throw StateError('RevenueCatService not configured. Check API keys.');
  }
}

Future<LogInResult> logIn(String userId) async {
  _ensureConfigured();
  return Purchases.logIn(userId);
}
```

This keeps PlatformException semantics for real SDK errors while giving a clear StateError for misconfiguration.

---

## Medium Priority

### 2. `purchasePackage` return type changed in SDK v8

In purchases_flutter v8.x, `Purchases.purchasePackage()` returns `Future<CustomerInfo>`. This is correct in your signature. However, be aware that prior to v8 it returned `PurchaserInfo`. Since the pubspec allows `^8.0.0`, a future v9 major could break this. Low risk but worth a note.

No action needed -- just documenting for future maintainers.

### 3. StreamController not checked before add in listener callback

If `onClose()` is called while a customer info update is in-flight (race between disposal and native callback), `_customerInfoController.add(info)` will throw `StateError: Cannot add event after closing`. This is unlikely but possible during rapid logout flows.

**Recommendation:** Guard the add:

```dart
void _onCustomerInfoUpdated(CustomerInfo info) {
  if (!_customerInfoController.isClosed) {
    _customerInfoController.add(info);
  }
}
```

### 4. Silent failure on init -- no way for callers to know why

`init()` catches all exceptions and prints to debugPrint. The caller (likely `main.dart` or global bindings) has no signal that initialization failed beyond checking `isConfigured`. This is acceptable for a non-critical service, but consider logging the specific exception type so future debugging is easier. The current `debugPrint('RevenueCat init failed: $e')` is reasonable but consider also printing the stack trace:

```dart
} catch (e, stackTrace) {
  debugPrint('RevenueCat init failed: $e\n$stackTrace');
}
```

---

## Low Priority

### 5. Unnecessary `await` on simple pass-through methods

Lines 42, 46, 50, 54, 58, 62 all use `return await Purchases.method()`. Since these methods simply return the Future, `return Purchases.method()` is equivalent and marginally more efficient (avoids an extra microtask). The `await` is only needed if you have a `try/catch` around it (which you intentionally do not, per design).

**Recommendation:** Remove `await` from pass-through methods:

```dart
Future<LogInResult> logIn(String userId) => Purchases.logIn(userId);
```

This also makes the wrapper nature more visually obvious.

### 6. Android platform detection

`Platform.isIOS` correctly selects Apple vs Google key. On non-mobile platforms (web, desktop) if Flutter expands there, `Platform.isIOS` being false would default to the Google key. Not an issue for a mobile-only app, just noting.

---

## Edge Cases Found by Scout

1. **No dependents yet** -- the service file exists but is not registered in any binding or referenced by any controller. Integration will need wiring in `global-dependency-injection-bindings.dart` and `main.dart`.
2. **Empty API key path** -- `init()` returns `this` with `_isConfigured = false` when key is empty. Any subsequent SDK call will crash (see High #1).
3. **Disposal race** -- Native listener callback can fire after `onClose()` begins (see Medium #3).

---

## Positive Observations

- Correct use of `GetxService` (not `GetxController`) for a long-lived singleton
- Proper listener cleanup in `onClose()` matching the registration in `init()`
- Broadcast StreamController is correct since multiple controllers may listen
- Clean separation: no business logic, no state mapping, no UI concerns
- Well within the 200-line file limit at 74 lines
- `kDebugMode` log level gating is a good practice

---

## Recommended Actions (prioritized)

1. **[High]** Add `_ensureConfigured()` guard to all SDK-calling methods
2. **[Medium]** Guard `_customerInfoController.add()` against closed controller
3. **[Medium]** Add stack trace to init catch block
4. **[Low]** Remove redundant `await` from pass-through methods (optional, stylistic)

## Metrics

- Type Coverage: 100% (all methods have explicit return types)
- Test Coverage: 0% (no tests yet -- expected for initial creation)
- Linting Issues: 0 (file is clean)
- File Size: 74 lines (well within 200-line limit)

## Unresolved Questions

- Where will this service be registered? Needs wiring into dependency injection before it can be used.
- Should `init()` throw on empty API key in production builds rather than silently degrading?
