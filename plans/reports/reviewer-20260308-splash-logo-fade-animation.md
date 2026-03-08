# Code Review: Native Splash Logo + Text Fade-In Animation

**Date:** 2026-03-08
**Scope:** Native splash screen logo setup (Android/iOS) + Flutter text fade-in animation
**LOC changed:** ~100 (excluding binary assets and Info.plist whitespace reformatting)

---

## Overall Assessment

Solid implementation. The approach -- logo visible on native splash, text fades in after Flutter takes over -- creates a smooth visual transition. Color consistency is verified across all three platforms. Two issues found, one high priority.

---

## High Priority

### 1. iOS LaunchImage constraints: full-bleed instead of centered

The storyboard pins `LaunchImage` to all four edges (leading, trailing, top, bottom). This stretches the logo to fill the entire screen rather than centering it. The original constraints used `centerX` and `centerY` which correctly centered the image.

**Impact:** Logo will appear distorted/stretched on iOS launch screen, defeating the purpose of matching the Flutter splash.

**Fix:** Replace the four-edge constraints on `YRO-k0-Ey4` with center constraints:

```xml
<constraint firstItem="YRO-k0-Ey4" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="1a2-6s-vTC"/>
<constraint firstItem="YRO-k0-Ey4" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="4X2-HB-R7a"/>
```

And keep the LaunchImage's `contentMode="center"` (which is already set). The LaunchBackground imageView can remain pinned to all edges since it serves as the background fill.

---

## Medium Priority

### 2. iOS LaunchBackground missing 2x/3x assets

`LaunchBackground.imageset/Contents.json` declares 2x and 3x scale slots but only provides a 1x `background.png` (69 bytes -- likely a 1x1 pixel). While this works functionally (the background color is set on the view anyway), the missing assets will generate Xcode warnings during build.

**Fix:** Either provide the same `background.png` for all three scales, or simplify by removing the 2x/3x entries from `Contents.json` since a solid-color 1x1 pixel scales fine.

### 3. iOS LaunchImage resource dimensions mismatch

The storyboard declares `<image name="LaunchImage" width="1200" height="782"/>` but the actual logo assets are 180/360/540px. This metadata is cosmetic (Xcode uses it for Interface Builder preview only), but the 1200x782 dimensions suggest either a wrong asset was used for the resource catalog entry or the values were not updated.

**Impact:** Cosmetic only. No runtime effect.

---

## Low Priority

### 4. Info.plist indentation change

The entire `Info.plist` was reformatted from tab-indented to double-tab-indented. This is a no-op change but adds noise to the diff. Consider reverting the whitespace-only changes to keep the commit focused.

### 5. `UIStatusBarHidden` addition

A new `UIStatusBarHidden = false` entry was added to Info.plist. This is the default behavior, so it is redundant but harmless.

---

## Edge Cases Scouted

- **Color consistency:** Verified. Android `#FFFF7A27`, iOS storyboard `rgb(1, 0.478, 0.153)`, and Flutter `0xFFFF7A27` all resolve to the same orange (#FF7A27). No mismatch.
- **Animation on slow devices:** `TweenAnimationBuilder` with 600ms is lightweight. No performance concern.
- **Logo asset at `assets/logos/logo.png`:** The Flutter splash references this asset. The native splash uses separate `splash_logo.png` (Android) and `LaunchImage.png` (iOS). If these are different images, there will be a visual jump. Verify they are the same artwork.
- **Android drawable vs mipmap:** `splash_logo.png` is correctly placed in `drawable-*` folders (not mipmap), which is the right choice for splash bitmaps.
- **Dark mode:** Android `values-night/` exists but no night-mode `launch_background.xml` override. The splash will use the orange background in dark mode too. Acceptable if intentional.

---

## Positive Observations

- Good use of `TweenAnimationBuilder` -- it is a `StatelessWidget`-friendly approach, avoiding the need for `AnimationController` + `StatefulWidget`.
- The `child` parameter is correctly used to avoid rebuilding the text widgets on every animation frame.
- Density-specific assets at correct sizes for all Android buckets (mdpi through xxxhdpi).
- Clean separation: logo stays instant (matches native), text fades in (Flutter-only enhancement).

---

## Recommended Actions (Priority Order)

1. **[HIGH] Fix iOS storyboard constraints** -- Change LaunchImage from full-bleed to centered. This is a visual bug.
2. **[MEDIUM] Verify logo artwork consistency** -- Ensure `splash_logo.png`, `LaunchImage.png`, and `assets/logos/logo.png` are the same image at different densities.
3. **[LOW] Clean up Info.plist whitespace** -- Revert formatting-only changes to reduce diff noise.
