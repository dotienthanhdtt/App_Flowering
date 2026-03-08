# Code Review: Onboarding Feature (First Half)

**Date:** 2026-02-28
**Reviewer:** code-reviewer
**Overall Quality:** 7/10

## Scope

- **Files reviewed:** 15 (4 modified, 11 new)
- **LOC:** ~650
- **Focus:** Onboarding flow (splash, welcome steps, language selection)
- **Analyzer:** 0 errors, 0 warnings (2 pre-existing info-level naming lints)

## Overall Assessment

Solid implementation following the project's feature-first architecture. Clean widget decomposition, correct GetX patterns, and good UI code. Several issues need attention, primarily around controller lifecycle, navigation safety, and missing `BaseController` usage.

---

## Critical Issues

### C1. SplashController instantiated inside `build()` -- recreated on every rebuild

**File:** `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/views/splash_screen.dart` (line 13)

```dart
Widget build(BuildContext context) {
  Get.put(SplashController()); // BAD: runs on every build call
```

`build()` can be called multiple times (theme changes, parent rebuilds, etc.). Each call creates a new `SplashController`, triggering duplicate `_checkAuthAndNavigate()` calls, which causes duplicate navigation.

**Fix:** Use a binding for SplashScreen (like the other onboarding pages), or use `Get.put` with `permanent: true` outside build, or at minimum guard with `Get.isRegistered`:

```dart
// Option A (preferred): Add SplashBinding and register in page definition
// Option B: Guard inside build
Get.put(SplashController(), permanent: true);
```

Also: SplashScreen has no binding in `app-page-definitions-with-transitions.dart` (line 52-57) unlike all other onboarding pages.

### C2. `SystemChrome.setSystemUIOverlayStyle` called inside `build()`

**Files:**
- `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/views/splash_screen.dart` (line 15)
- `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/views/welcome_problem_screen.dart` (line 72)

Platform channel calls in `build()` are side effects that run on every rebuild. This should be in `initState`, `onInit`, or via `AnnotatedRegion<SystemUiOverlayStyle>`.

**Fix:**
```dart
// Use AnnotatedRegion instead
return AnnotatedRegion<SystemUiOverlayStyle>(
  value: const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ),
  child: Scaffold(...),
);
```

---

## High Priority

### H1. OnboardingController uses `lazyPut` but is accessed across multiple routes

**File:** `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/bindings/onboarding_binding.dart`

Each onboarding page has its own `OnboardingBinding` that does `Get.lazyPut`. When navigating from `NativeLanguageScreen` to `LearningLanguageScreen`, the controller may be disposed and recreated if GetX garbage-collects it between route transitions, losing `selectedNativeLanguage`.

**Fix:** Either:
- Use `Get.put` with `permanent: true` for the duration of onboarding, or
- Use `Get.lazyPut(..., fenix: true)` to auto-recreate (but state is still lost), or
- **(Best)** Register the controller once at the first onboarding page and use `Get.find()` on subsequent pages without re-binding.

### H2. SplashController does not extend BaseController

**File:** `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/controllers/splash_controller.dart`

The project convention (per `CLAUDE.md`) states all controllers should extend `BaseController`. `SplashController` extends `GetxController` directly and has a bare `catch (_)` that silently swallows all errors including non-network errors.

**Fix:**
```dart
class SplashController extends BaseController {
  // ...
  Future<bool> _validateToken() async {
    if (!_authStorage.isLoggedIn) return false;
    final response = await apiCall(
      () => _apiClient.get(ApiEndpoints.userMe),
      showLoading: false,
    );
    return response?.isSuccess ?? false;
  }
}
```

### H3. `Future.delayed` for navigation delay is fragile and not cancellable

**File:** `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/controllers/onboarding_controller.dart` (lines 10, 18)

```dart
Future.delayed(const Duration(milliseconds: 400), () {
  Get.toNamed(AppRoutes.onboardingLearningLanguage);
});
```

If the controller is disposed before the 400ms delay completes (user rapidly navigates back), the navigation callback still fires, causing navigation to a stale/unexpected screen. Also, rapid taps on a language card will queue multiple navigations.

**Fix:** Track the timer and cancel it in `onClose()`:
```dart
Timer? _navTimer;

void selectNativeLanguage(String code) {
  selectedNativeLanguage.value = code;
  _navTimer?.cancel();
  _navTimer = Timer(const Duration(milliseconds: 400), () {
    Get.toNamed(AppRoutes.onboardingLearningLanguage);
  });
}

@override
void onClose() {
  _navTimer?.cancel();
  super.onClose();
}
```

### H4. `.timeout()` on `ApiResponse` future throws `TimeoutException` not caught specifically

**File:** `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/controllers/splash_controller.dart` (line 38)

```dart
final response = await _apiClient
    .get(ApiEndpoints.userMe)
    .timeout(const Duration(seconds: 5));
```

The `ApiClient.get` already has `receiveTimeout: 30s` at the Dio level. Adding `.timeout(5s)` at the Future level means a `TimeoutException` (from `dart:async`) is thrown, bypassing Dio's exception handling. The generic `catch (_)` handles it but masks the real issue. This is also redundant with the Dio timeout config.

**Fix:** Remove the `.timeout()` call. Rely on Dio's built-in timeout, or if a shorter timeout is needed, pass it via `Options`:
```dart
final response = await _apiClient.get(
  ApiEndpoints.userMe,
  options: Options(receiveTimeout: const Duration(seconds: 5)),
);
```

---

## Medium Priority

### M1. `_welcomeSteps` array access not bounds-checked

**File:** `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/views/welcome_problem_screen.dart` (line 70)

```dart
final data = _welcomeSteps[step]; // step comes from constructor, no validation
```

If `step` is out of range (0-2), this throws `RangeError`. Add an assertion or clamp.

### M2. Language selections not persisted

**File:** `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/controllers/onboarding_controller.dart`

`selectedNativeLanguage` and `selectedLearningLanguage` are only in-memory `.obs` values. If the app is killed during onboarding, all progress is lost. Consider persisting to Hive/StorageService after each selection.

### M3. Back button on NativeLanguageScreen uses custom widget instead of system back

**File:** `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/views/native_language_screen.dart` (lines 25-40)

The custom back button works, but `LearningLanguageScreen` has no back button at all. Users cannot go back from the learning language selection step, which is a UX issue.

### M4. Hardcoded strings throughout

All screen text is hardcoded English. The project has a localization system (`l10n/` with `.tr`). These strings should use translation keys for consistency.

### M5. `OnboardingTopBar` hardcodes top padding of 56

**File:** `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/lib/features/onboarding/widgets/onboarding_top_bar.dart` (line 11)

Should use `MediaQuery.of(context).padding.top` or wrap in `SafeArea` to handle different device safe areas properly. On devices with larger notches, 56px may not be enough.

---

## Low Priority

- `WelcomeProblemScreen` step 2 uses `data.ctaLabel!` with force-unwrap (line 126). Safe due to data structure, but a `?? 'Continue'` fallback is safer.
- `OnboardingLanguage.isEnabled` defaults to `false` -- parameter name could be clearer (`isAvailable`).
- `UserModel` additions (nativeLanguageId, nativeLanguageCode, nativeLanguageName) look correct but `copyWith` cannot set fields back to `null` (standard Dart limitation with optional params -- consider nullable wrapper if needed later).

---

## Positive Observations

- Clean feature-first directory structure matching project conventions
- Good widget decomposition: `LanguageListCard` / `LanguageGridCard` separation
- Proper use of `const` constructors throughout
- `StepDotsIndicator` is reusable and parameterized
- Correct use of `Obx` wrapping only the reactive parts
- `OnboardingLanguage` model with static lists is a clean data pattern
- `ApiEndpoints` stays well-organized
- Splash auth check with `Future.wait` (parallel delay + validation) is a nice pattern

---

## Recommended Actions (Priority Order)

1. **Create SplashBinding** and remove `Get.put` from `build()` [C1]
2. **Replace `SystemChrome` calls** with `AnnotatedRegion` [C2]
3. **Fix OnboardingController lifecycle** -- single registration, not per-route binding [H1]
4. **Cancel delayed navigation** in `onClose()` to prevent use-after-dispose [H3]
5. **Extend BaseController** in SplashController [H2]
6. **Remove `.timeout()` call** or use Dio options [H4]
7. **Add back button** to LearningLanguageScreen [M3]
8. **Use translation keys** instead of hardcoded strings [M4]

---

## Unresolved Questions

- Is the onboarding flow intended to be completable without authentication? Currently splash routes unauthenticated users to onboarding, but onboarding ends by navigating to `/chat` which is a placeholder. What should the terminal route be?
- Should language selection be sent to the backend API during onboarding, or only after account creation?
- The "Log in" button in `OnboardingTopBar` has an empty `onTap`. Is this blocked on auth feature implementation?
