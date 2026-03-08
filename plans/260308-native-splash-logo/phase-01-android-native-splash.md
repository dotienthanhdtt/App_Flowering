# Phase 1: Android Native Splash — Add Logo

## Overview
- **Priority:** High
- **Status:** Complete
- **Description:** Add centered logo to Android launch_background.xml across all density buckets

## Architecture

Android native splash uses `launch_background.xml` (a `layer-list` drawable) referenced by `LaunchTheme` in `styles.xml`. Currently shows solid orange. We add a second `<item>` with a centered bitmap of the logo.

## Required Logo Sizes

Flutter shows logo at 180x180dp. Android density multipliers:

| Density | Multiplier | Logo Size (px) |
|---------|-----------|-----------------|
| mdpi | 1x | 180x180 |
| hdpi | 1.5x | 270x270 |
| xhdpi | 2x | 360x360 |
| xxhdpi | 3x | 540x540 |
| xxxhdpi | 4x | 720x720 |

## Related Code Files

### Files to Modify
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`

### Files to Create
- `android/app/src/main/res/drawable-mdpi/splash_logo.png` (180x180)
- `android/app/src/main/res/drawable-hdpi/splash_logo.png` (270x270)
- `android/app/src/main/res/drawable-xhdpi/splash_logo.png` (360x360)
- `android/app/src/main/res/drawable-xxhdpi/splash_logo.png` (540x540)
- `android/app/src/main/res/drawable-xxxhdpi/splash_logo.png` (720x720)

## Implementation Steps

1. **Resize logo.png** to each density size using `sips` (macOS built-in) or ImageMagick
   - Source: `assets/logos/logo.png`
   - Output: `splash_logo.png` at each density size
2. **Copy resized logos** to respective `drawable-{density}/` folders
3. **Update `launch_background.xml`** (both drawable/ and drawable-v21/) to add centered bitmap:
   ```xml
   <layer-list xmlns:android="http://schemas.android.com/apk/res/android">
       <item android:drawable="@color/primary" />
       <item>
           <bitmap
               android:gravity="center"
               android:src="@drawable/splash_logo" />
       </item>
   </layer-list>
   ```

## Success Criteria
- [x] Logo appears centered on orange background during Android cold start
- [x] Logo size matches Flutter splash (180dp)
- [x] No stretching/distortion across screen sizes
- [x] Works in both light and dark mode (both use same launch_background)
