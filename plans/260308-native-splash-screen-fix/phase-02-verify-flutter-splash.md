---
phase: 2
priority: medium
status: pending
---

# Phase 2: Verify & Adjust Flutter Splash + Status Bar

## Overview
Ensure Flutter SplashScreen and status bar config work seamlessly with the new native splash. The native splash should hold until Flutter is ready, then smoothly show the Flutter SplashScreen (same visual), then navigate based on auth.

## Related Code Files

### Files to verify (no changes expected)
- `lib/features/onboarding/views/splash_screen.dart` — already uses orange bg + white status bar icons
- `lib/app/routes/app-page-definitions-with-transitions.dart` — fade transition already configured

### Files potentially modified
- `lib/main.dart` — status bar style may need adjustment (currently `Brightness.dark`, splash uses `Brightness.light`)

## Implementation Steps

### 1. Verify status bar consistency
`main.dart` sets `statusBarIconBrightness: Brightness.dark` globally but `splash_screen.dart` overrides to `Brightness.light` via `AnnotatedRegion`. This is correct — no change needed.

### 2. Test on Android
```bash
flutter run --dart-define=ENV=dev
```
- Verify: orange native splash → seamless orange Flutter splash → navigation
- Test on Android 12+ emulator/device specifically

### 3. Test on iOS
```bash
flutter run --dart-define=ENV=dev
```
- Verify: orange native splash → seamless orange Flutter splash → navigation

### 4. Test dark mode (Android)
- Enable dark mode in device settings
- Verify native splash still shows orange (not dark theme override)

## Todo List
- [ ] Build and run on Android device/emulator
- [ ] Build and run on iOS simulator/device
- [ ] Test Android 12+ splash behavior
- [ ] Test dark mode on Android
- [ ] Verify no white flash between splashes
- [ ] Verify status bar icons are light (white) on splash

## Success Criteria
- Zero visual discontinuity between native and Flutter splash
- Works correctly on Android <12, Android 12+, and iOS
- Dark mode doesn't break the splash color
- Status bar icons remain white/light on orange background
