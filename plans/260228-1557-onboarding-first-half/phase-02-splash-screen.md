# Phase 2 — Splash Screen

**Priority:** Critical
**Status:** completed
**Effort:** Small
**Depends on:** Phase 1

---

## Context

- Design node: `e7K5c` (Screen 0 — Splash)
- Full orange bg (#FF7A27), centered flower logo, "Flowering" white bold, "Bloom in your own way" subtitle

## Overview

Implement splash screen with 3-second minimum display and real API token validation. Navigates to /home (valid token) or /onboarding/welcome (invalid/missing).

## Implementation Steps

### 1. Create `splash_controller.dart`

```dart
class SplashController extends GetxController {
  final _authStorage = Get.find<AuthStorage>();
  final _apiClient = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      _validateToken(),
    ]);

    final isValid = results[1] as bool;

    if (isValid) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.onboardingWelcome);
    }
  }

  Future<bool> _validateToken() async {
    if (!_authStorage.isLoggedIn) return false;

    try {
      final response = await _apiClient.get(
        ApiEndpoints.userMe,
      ).timeout(const Duration(seconds: 5));
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }
}
```

Key points:
- `Future.wait` runs 3s delay and token check in parallel
- Any error (network, 401, timeout) → `false` → onboarding
- Uses `Get.offAllNamed` to clear navigation stack
- 5s timeout on API call to prevent hanging

### 2. Create `splash_screen.dart`

Layout from design:
- `Scaffold` with no AppBar
- Full orange background (#FF7A27 / AppColors.primary)
- Centered column: logo image (180x180), "Flowering" text (white, 36px, bold), tagline (white 80%, 15px)
- Status bar: light icons (white) on orange bg

```dart
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller auto-inits via binding
    Get.put(SplashController());

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flower logo — use Image.asset
            Image.asset('assets/images/flower_logo.png', width: 180, height: 180),
            const SizedBox(height: 16),
            Text('Flowering', style: ...white 36px bold...),
            const SizedBox(height: 16),
            Text('Bloom in your own way', style: ...white80 15px...),
          ],
        ),
      ),
    );
  }
}
```

### 3. Add flower logo asset

- Export logo from design or use existing `Flowering logo (1).png`
- Place in `assets/images/`
- Add to `pubspec.yaml` assets section

### 4. Set status bar to light on splash

In `SplashScreen.build()`:
```dart
SystemChrome.setSystemUIOverlayStyle(
  const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // White icons on orange
  ),
);
```

Reset to dark icons when leaving splash (in welcome screen).

## Files Created

| File | Purpose |
|------|---------|
| `lib/features/onboarding/controllers/splash_controller.dart` | Token check + navigation |
| `lib/features/onboarding/views/splash_screen.dart` | Splash UI |

## Assets

- `assets/images/flower_logo.png` — flower logo for splash (export from design)

## Todo

- [x] Create `splash_controller.dart` with Future.wait pattern
- [x] Create `splash_screen.dart` matching design
- [x] Add flower logo asset + pubspec.yaml entry
- [x] Handle status bar color (light on splash)
- [x] Test: no token → goes to welcome
- [x] Test: valid token → goes to home
- [x] Test: API timeout → goes to welcome
- [x] `flutter analyze` passes

## Success Criteria

- Splash displays for minimum 3 seconds
- Token check calls GET /users/me
- Valid → /home, invalid/error → /onboarding/welcome
- Visual matches design (orange bg, centered logo+text)
