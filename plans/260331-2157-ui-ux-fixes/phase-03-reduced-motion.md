# Phase 3: Reduced Motion Support

## Context
- Report: `plans/reports/ui-ux-review-260331-2149-flowering-app.md` §2.3
- 3 widgets with continuous animations, none check `disableAnimations`

## Overview
- **Priority:** CRITICAL
- **Status:** Pending
- **Description:** Respect system reduced-motion setting in all continuous animations

## Key Insights
- Flutter exposes `MediaQuery.of(context).disableAnimations` (iOS) and `AccessibilityFeatures.reduceMotion`
- Best approach: check in `didChangeDependencies` and stop/start controller accordingly
- Alternative: simply don't repeat animation — show static state instead

## Related Code Files
- **Modify:** `lib/shared/widgets/loading_widget.dart` (108 lines)
- **Modify:** `lib/features/chat/widgets/ai_typing_bubble.dart` (87 lines)
- **Modify:** `lib/features/chat/widgets/chat_waveform_bars.dart` (79 lines)

## Implementation Steps

### 1. `loading_widget.dart` — Static fallback when motion reduced
Add `didChangeDependencies` to check and conditionally animate:

```dart
bool _reduceMotion = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final reduce = MediaQuery.of(context).disableAnimations;
  if (reduce != _reduceMotion) {
    _reduceMotion = reduce;
    if (_reduceMotion) {
      _controller.stop();
      _controller.value = 0; // Static position
    } else {
      _controller.repeat();
    }
  }
}
```
In `initState`, don't auto-repeat — move `..repeat()` to `didChangeDependencies`:
```dart
// initState:
_controller = AnimationController(
  duration: const Duration(milliseconds: 1500),
  vsync: this,
);
// repeat() called in didChangeDependencies
```

### 2. `ai_typing_bubble.dart` — Same pattern
Add `_reduceMotion` check. When reduced, show 3 static dots at scale 1.0:

```dart
bool _reduceMotion = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final reduce = MediaQuery.of(context).disableAnimations;
  if (reduce != _reduceMotion) {
    _reduceMotion = reduce;
    if (_reduceMotion) {
      _ctrl.stop();
    } else {
      _ctrl.repeat();
    }
  }
}
```
In the builder, when `_reduceMotion`, set `scale = 1.0` for all dots.

### 3. `chat_waveform_bars.dart` — Same pattern
When motion reduced, show bars at mid-height (static visualization):

```dart
bool _reduceMotion = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final reduce = MediaQuery.of(context).disableAnimations;
  if (reduce != _reduceMotion) {
    _reduceMotion = reduce;
    if (_reduceMotion) {
      _ctrl.stop();
    } else {
      _ctrl.repeat();
    }
  }
}
```
In builder: when `_reduceMotion`, `wave = 0.5` (static mid-height).

## Todo
- [ ] Add `didChangeDependencies` + `_reduceMotion` to `LoadingWidget`
- [ ] Move `..repeat()` from `initState` to `didChangeDependencies`
- [ ] Add `_reduceMotion` check to `AiTypingBubble`
- [ ] Add `_reduceMotion` check to `ChatWaveformBars`
- [ ] Run `flutter analyze`
- [ ] Test: enable "Reduce motion" in iOS Settings > Accessibility > Motion

## Success Criteria
- With reduced motion ON: all 3 widgets show static (non-animated) state
- With reduced motion OFF: animations run as before
- No visual flicker when toggling setting
- `flutter analyze` passes

## Risk Assessment
- **Low risk:** Only adds a conditional check around existing animation
- `didChangeDependencies` is called after `initState` — controller is ready
- Must handle case where context isn't available in `initState`
