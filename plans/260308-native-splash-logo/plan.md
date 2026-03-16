# Native Splash Screen — Logo on Orange Background

## Overview
Make the native splash screen (Android + iOS) show the app logo centered on the orange primary background, so the transition to the Flutter splash is seamless. When Flutter loads, only the text "Flowering" and tagline fade in.

## Phases

| # | Phase | Status | Effort |
|---|-------|--------|--------|
| 1 | Android native splash — add logo | complete | small |
| 2 | iOS native splash — update LaunchImage | complete | small |
| 3 | Flutter splash — add text fade-in animation | complete | small |

## Key Context
- Primary color: `#FF7A27` (both platforms already use this)
- Logo source: `assets/logos/logo.png` (1.3MB, needs resizing per density)
- Flutter splash shows logo at 180x180 logical pixels
- Android density folders: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
- iOS uses LaunchImage asset catalog with 1x/2x/3x scales

## Dependencies
- Phase 1 and 2 are independent (parallel)
- Phase 3 is independent (can run in parallel)
