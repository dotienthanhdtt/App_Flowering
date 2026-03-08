---
status: in-progress
created: 2026-03-08
type: fix
---

# Native Splash Screen Fix — Seamless Splash Experience

## Problem
App shows white native splash (Android) / default LaunchImage (iOS) before the orange Flutter SplashScreen, creating a jarring two-splash experience.

## Solution
Use `flutter_native_splash` package to make native splash match the Flutter splash (orange background + logo), creating a seamless single-splash perception.

## Phases

| # | Phase | Status | File |
|---|-------|--------|------|
| 1 | Install & configure flutter_native_splash | done | [phase-01](phase-01-configure-native-splash.md) |
| 2 | Verify & adjust Flutter splash + main.dart | pending | [phase-02](phase-02-verify-flutter-splash.md) |

## Key Details
- Primary color: `#FF7A27` (AppColors.primary)
- Logo: `assets/logos/logo.png`
- Must handle Android 12+ splash API
- Preserve existing Flutter SplashScreen behavior (3s + auth check)
