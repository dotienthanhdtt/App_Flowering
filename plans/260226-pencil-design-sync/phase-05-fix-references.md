# Phase 5: Fix All Broken References

## Context Links
- Depends on: Phase 1, 2, 3, 4
- Scan results from `grep -rn "AppColors\.(secondary|textHint|divider)" lib/`

## Overview
- **Priority:** P1
- **Status:** Complete
- **Description:** After Phases 1-4, fix all remaining compile errors caused by removed/renamed colors. Update theme config and documentation.

## Key Insights

From codebase scan, these files reference old color names:

| File | Old Reference | New Reference |
|------|--------------|---------------|
| `flowering-app-widget-with-getx.dart:54` | `AppColors.secondary` | `AppColors.accentGreen` |
| `flowering-app-widget-with-getx.dart:90` | `AppColors.divider` | `AppColors.border` |
| `app_text_styles.dart:54` | `AppColors.textHint` | `AppColors.textTertiary` |
| `app_text_field.dart:93` | `AppColors.textHint` | `AppColors.textTertiary` |
| `app_text_field.dart:112,116` | `AppColors.divider` | `AppColors.border` |
| `app_button.dart:79` | `AppColors.secondary` | `AppColors.primarySoft` |

Note: `app_text_styles.dart`, `app_text_field.dart`, and `app_button.dart` are handled in Phases 2-4. Only `flowering-app-widget-with-getx.dart` needs fixing here.

Additionally, the app theme in `flowering-app-widget-with-getx.dart` needs updating:
- `ColorScheme.fromSeed` secondary -> use `accentGreen` or remove
- `dividerTheme` color -> `AppColors.border`
- Button radius -> pill (100) to match component
- Input decoration radius -> 12 to match component

## Requirements

### Functional
- Zero compile errors after all phases complete
- Theme colors aligned with new palette
- All old color name references eliminated from entire codebase

### Non-Functional
- No feature behavior changes
- App theme visually consistent with Pencil design

## Related Code Files
- **Modify:** `lib/app/flowering-app-widget-with-getx.dart`
- **Verify (already handled):** `app_text_styles.dart`, `app_button.dart`, `app_text_field.dart`
- **Verify (no changes needed):** `error_widget.dart`, `loading_widget.dart`, `app_icon.dart`

## Implementation Steps

1. **`flowering-app-widget-with-getx.dart`** -- Update theme:
   ```dart
   // Line 54: secondary color
   secondary: AppColors.secondary,  ->  secondary: AppColors.accentGreen,

   // Line 90: divider color
   color: AppColors.divider,  ->  color: AppColors.border,
   ```

2. **`flowering-app-widget-with-getx.dart`** -- Update theme radii:
   ```dart
   // Elevated button radius
   borderRadius: BorderRadius.circular(12),  ->  borderRadius: BorderRadius.circular(AppColors.radiusPill),

   // Input decoration radius
   borderRadius: BorderRadius.circular(12),  ->  borderRadius: BorderRadius.circular(AppColors.radiusM),

   // Card radius stays 16 (matches radiusL)
   ```

3. **Verify no remaining old references** -- Run:
   ```bash
   grep -rn "AppColors\.\(secondary\|secondaryLight\|secondaryDark\|peach\|mint\|skyBlue\|softPink\|textHint\|divider\)" lib/
   ```
   Expected: zero results.

4. **Update documentation** -- Update `docs/codebase-summary.md` color section to reflect new palette.

5. **Run `flutter analyze`** -- Verify zero errors/warnings.

## Todo List
- [x] Fix `flowering-app-widget-with-getx.dart` secondary -> accentGreen
- [x] Fix `flowering-app-widget-with-getx.dart` divider -> border
- [x] Update theme button radius to pill
- [x] Update theme input radius to 12
- [x] Run grep scan for any remaining old color references
- [x] Run `flutter analyze` -- zero errors
- [x] Update codebase-summary.md color documentation

## Success Criteria
- `flutter analyze` returns 0 errors
- `grep` for old color names returns 0 results
- App compiles and runs
- Theme colors match Pencil design system
