# Phase 3: Flutter Splash — Text Fade-In Animation

## Overview
- **Priority:** Medium
- **Status:** Complete
- **Description:** Add fade-in animation to "Flowering" title and tagline so the transition from native splash (logo only) to Flutter splash (logo + text) feels intentional

## Architecture

Current `SplashScreen` is a `StatelessWidget`. Need to convert to `StatefulWidget` to use `AnimationController` for fade-in.

Alternative: Use `TweenAnimationBuilder` to keep it simpler (no StatefulWidget needed).

**Chosen approach:** `TweenAnimationBuilder` — simpler, no dispose needed, KISS.

## Related Code Files

### Files to Modify
- `lib/features/onboarding/views/splash_screen.dart`

## Implementation Steps

1. Wrap the title `Text` and tagline `Text` widgets (and the `SizedBox` between logo and title) in a `TweenAnimationBuilder<double>`:
   - Tween: `0.0 → 1.0`
   - Duration: `600ms`
   - Curve: `Curves.easeIn`
   - Builder applies `Opacity` widget with the animated value
2. Keep logo with NO animation (it's already visible on native splash)
3. Keep everything else unchanged

## Code Sketch

```dart
// Wrap text section in fade animation
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.0, end: 1.0),
  duration: const Duration(milliseconds: 600),
  curve: Curves.easeIn,
  builder: (context, opacity, child) {
    return Opacity(
      opacity: opacity,
      child: child,
    );
  },
  child: Column(
    children: [
      const SizedBox(height: AppSizes.spacingL),
      Text('Flowering', ...),
      const SizedBox(height: AppSizes.spacingS),
      Text('Bloom in your own way', ...),
    ],
  ),
),
```

## Success Criteria
- [x] Logo appears instantly (matching native splash)
- [x] Text fades in smoothly over ~600ms
- [x] Transition from native → Flutter splash feels seamless
- [x] No visual "jump" or layout shift
