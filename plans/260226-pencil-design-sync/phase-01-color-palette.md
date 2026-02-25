# Phase 1: Color Palette

## Context Links
- Pencil MCP design variables (source of truth)
- Current file: `lib/core/constants/app_colors.dart` (40 lines)

## Overview
- **Priority:** P1 -- all other phases depend on this
- **Status:** Complete
- **Description:** Replace entire `AppColors` class with Pencil design variable palette. Remove deprecated colors, add new semantic/accent groups, add radius constants.

## Key Insights
- 7 color names are being removed: `secondary`, `secondaryLight`, `secondaryDark`, `peach`, `mint`, `skyBlue`, `softPink`
- 2 color names are being renamed: `textHint` -> `textTertiary`, `divider` -> `border`
- ~20 new colors added (accent groups, light variants, surface variants)
- Radius constants added to centralize border radius values
- Chat colors updated to match new palette

## Requirements

### Functional
- All color hex values match Pencil design variables exactly
- Old color names removed (will cause compile errors that Phase 5 fixes)
- New color groups: accent (blue, green, lavender, rose), semantic light variants, surface variants

### Non-Functional
- Maintain `AppColors._()` private constructor pattern
- All values remain `static const Color`
- File stays under 200 lines

## Related Code Files
- **Modify:** `lib/core/constants/app_colors.dart`

## Implementation Steps

1. Replace primary group:
   - `primary`: `0xFFFF9500` -> `0xFFFF7A27`
   - `primaryLight`: `0xFFFFD6A5` -> `0xFFFFB380`
   - `primaryDark`: `0xFFE68600` -> `0xFFD4621A`
   - Add `primarySoft`: `0xFFFFEADB`

2. Remove secondary group entirely:
   - Delete `secondary`, `secondaryLight`, `secondaryDark`

3. Replace neutrals:
   - `background`: `0xFFFFFDF7` -> `0xFFF8F4E3`
   - Add `backgroundWarm`: `0xFFFFF8F0`
   - `surface`: `0xFFFFFDF7` -> `0xFFFFFFFF`
   - Add `surfaceMuted`: `0xFFF2EED8`

4. Replace text colors:
   - `textPrimary`: `0xFF292F36` -> `0xFF191919`
   - `textSecondary`: `0xFF699A6B` -> `0xFF5C5646`
   - Rename `textHint` to `textTertiary`: `0xFFA3A9AA` -> `0xFF9C9585`
   - Add `textOnPrimary`: `0xFFFFFFFF`

5. Replace border colors:
   - Rename `divider` to `border`: `0xFFA3A9AA` -> `0xFFE5DFC9`
   - Add `borderLight`: `0xFFF0ECDA`
   - Add `borderStrong`: `0xFFD4CEAE`

6. Replace semantic colors:
   - `success`: `0xFFCAFFBF` -> `0xFF6BAF7A`, add `successLight`: `0xFFE2F3E5`
   - `warning`: `0xFFFFD6A5` -> `0xFFE8C460`, add `warningLight`: `0xFFFDF5DC`
   - `error`: `0xFFFF4444` -> `0xFFD97B7B`, add `errorLight`: `0xFFFBEAEA`
   - `info`: `0xFFA0C4FF` -> `0xFF7AACCC`, add `infoLight`: `0xFFE0F0FA`

7. Remove complementary group:
   - Delete `peach`, `mint`, `skyBlue`, `softPink`

8. Add accent groups:
   - Blue: `accentBlue` `0xFF7AACCC`, `accentBlueDark` `0xFF5A8DAD`, `accentBlueLight` `0xFFE0F0FA`
   - Green: `accentGreen` `0xFF6BAF7A`, `accentGreenDark` `0xFF4A8A58`, `accentGreenLight` `0xFFE2F3E5`
   - Lavender: `accentLavender` `0xFFB8A9D4`, `accentLavenderDark` `0xFF8E7DB8`, `accentLavenderLight` `0xFFEDE8F5`
   - Rose: `accentRose` `0xFFE8A0A0`, `accentRoseDark` `0xFFC47878`, `accentRoseLight` `0xFFFBE8E8`

9. Add shadow color:
   - `shadow`: `Color(0x10191919)` (10% opacity of textPrimary)

10. Update chat colors:
    - `userBubble`: `0xFFFF9500` -> `0xFFFF7A27`
    - `aiBubble`: `0xFFFFFDF7` -> `0xFFFFFFFF`

11. Add radius constants:
    ```dart
    static const double radiusS = 6;
    static const double radiusM = 12;
    static const double radiusL = 16;
    static const double radiusXL = 20;
    static const double radiusPill = 100;
    ```

## Todo List
- [x] Replace primary color group
- [x] Remove secondary color group
- [x] Replace neutral colors
- [x] Replace text colors and rename textHint -> textTertiary
- [x] Replace border colors and rename divider -> border
- [x] Replace semantic colors and add light variants
- [x] Remove complementary group
- [x] Add accent color groups
- [x] Add shadow and radius constants
- [x] Update chat colors
- [x] Verify file compiles (will have downstream errors in other files)

## Success Criteria
- `app_colors.dart` contains all Pencil design variable colors
- No old color names remain (secondary, peach, mint, skyBlue, softPink, textHint, divider)
- File is under 200 lines
- All hex values match spec exactly
