# Phase 2: Typography

## Context Links
- Depends on: Phase 1 (color names)
- Current file: `lib/core/constants/app_text_styles.dart` (62 lines)

## Overview
- **Priority:** P1
- **Status:** Complete
- **Description:** Change font family from Inter to Outfit. Update color references to match new AppColors names.

## Key Insights
- 9 text style getters all use `GoogleFonts.inter` -- change to `GoogleFonts.outfit`
- `bodySmall` uses `AppColors.textSecondary` -- value changes but name stays (OK)
- `caption` uses `AppColors.textHint` -- must change to `AppColors.textTertiary`
- `label` uses `AppColors.textSecondary` -- value changes but name stays (OK)
- No size/weight changes needed per spec (font change only)

## Requirements

### Functional
- All `GoogleFonts.inter` calls replaced with `GoogleFonts.outfit`
- `AppColors.textHint` reference updated to `AppColors.textTertiary`

### Non-Functional
- Maintain existing getter pattern
- File stays under 200 lines

## Related Code Files
- **Modify:** `lib/core/constants/app_text_styles.dart`

## Implementation Steps

1. Find-and-replace `GoogleFonts.inter` -> `GoogleFonts.outfit` (9 occurrences)
2. In `caption` getter: change `AppColors.textHint` -> `AppColors.textTertiary`
3. Verify file compiles

## Todo List
- [x] Replace all GoogleFonts.inter with GoogleFonts.outfit
- [x] Update caption color from textHint to textTertiary
- [x] Verify compilation

## Success Criteria
- Zero occurrences of `GoogleFonts.inter` in codebase
- Zero occurrences of `AppColors.textHint` in this file
- All text styles use Outfit font family
