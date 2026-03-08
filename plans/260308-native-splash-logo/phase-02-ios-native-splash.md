# Phase 2: iOS Native Splash — Update LaunchImage

## Overview
- **Priority:** High
- **Status:** Complete
- **Description:** Replace iOS LaunchImage with the app logo (centered, proper scale) on orange background

## Architecture

iOS uses `LaunchScreen.storyboard` with two `UIImageView`s:
- `LaunchBackground` — full-screen background (currently 1x1 orange pixel)
- `LaunchImage` — centered image (currently 1200x782, contentMode="center")

The storyboard background color is already `RGB(1, 0.478, 0.153)` = `#FF7A27`.

We replace the `LaunchImage` assets with the logo at proper scales.

## Required Logo Sizes

iOS uses 1x/2x/3x scale factors. Flutter shows logo at 180x180 points:

| Scale | Logo Size (px) |
|-------|-----------------|
| 1x | 180x180 |
| 2x | 360x360 |
| 3x | 540x540 |

## Related Code Files

### Files to Replace
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` (180x180)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` (360x360)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` (540x540)

### No Changes Needed
- `LaunchScreen.storyboard` — already has centered LaunchImage with correct background color
- `Contents.json` — already references correct filenames
- `LaunchBackground` — keep as-is (orange pixel backup)

## Implementation Steps

1. **Resize logo.png** to 180x180, 360x360, 540x540
2. **Replace** existing LaunchImage files with resized logos
3. **Verify** storyboard contentMode is "center" (already is)

## Success Criteria
- [x] Logo appears centered on orange background during iOS cold start
- [x] Logo size matches Flutter splash (~180pt)
- [x] No stretching on different iPhone/iPad sizes
