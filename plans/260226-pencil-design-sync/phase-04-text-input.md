# Phase 4: Text Input

## Context Links
- Depends on: Phase 1 (color names), Phase 2 (text styles)
- Current file: `lib/shared/widgets/app_text_field.dart` (137 lines)

## Overview
- **Priority:** P1
- **Status:** Complete
- **Description:** Restyle AppTextField to match Pencil component specs. Changes to radius, border width, colors, padding, label styling, and error state.

## Key Insights
- Radius: 16px -> 12px
- Border width: 2px -> 1.5px
- Border color: `divider` -> `border`
- Fill: `surface` (value changes from cream to white in Phase 1)
- Label style: 14px w500 textSecondary -> 13px w600 textPrimary
- Hint style: uses `textHint` -> `textTertiary`
- Error state: gets `errorLight` fill
- Gap label-to-field: 8px -> 6px
- Content padding horizontal: 20px -> 16px
- Focus border: primary 1.5px (was 2px)

## Requirements

### Functional
- Corner radius: 12px on all border states
- Border width: 1.5px on all border states
- Default border color: `AppColors.border`
- Focus border color: `AppColors.primary`
- Error border color: `AppColors.error`
- Fill color: `AppColors.surface`
- Error fill color: `AppColors.errorLight`
- Label: 13px w600 `textPrimary`
- Hint text: `textTertiary`
- Content padding: horizontal 16px, vertical 16px
- Label-to-field gap: 6px

### Non-Functional
- Keep all existing props (controller, obscureText, validator, etc.)
- File stays under 200 lines

## Related Code Files
- **Modify:** `lib/shared/widgets/app_text_field.dart`

## Implementation Steps

1. Update label style:
   - Change `AppTextStyles.label` to custom: `TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)`
   - Or update `AppTextStyles.label` in Phase 2 -- but that would affect other label usages. Safer to inline here.

2. Update label-to-field gap:
   - `SizedBox(height: 8)` -> `SizedBox(height: 6)`

3. Update hint style:
   - `AppColors.textHint` -> `AppColors.textTertiary`
   - Font size: use `AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary)` (14px normal)

4. Update content padding:
   - `horizontal: 20` -> `horizontal: 16`

5. Update all border definitions:
   - `BorderRadius.circular(16)` -> `BorderRadius.circular(AppColors.radiusM)` (or 12)
   - Border width: `2` -> `1.5` (all 5 border states)

6. Update border colors:
   - `border` (default): `AppColors.divider` -> `AppColors.border`
   - `enabledBorder`: `AppColors.divider` -> `AppColors.border`
   - `focusedBorder`: `AppColors.primary` (no change, just width 2->1.5)
   - `errorBorder`: `AppColors.error` (no change, just width 2->1.5)
   - `focusedErrorBorder`: `AppColors.error` (no change, just width 2->1.5)

7. Update fill color for error state:
   - Need to handle error state dynamically. If `errorText != null`, set `fillColor: AppColors.errorLight`, else `AppColors.surface`

8. Update visibility toggle icon color:
   - `AppColors.textSecondary` stays (value changes in Phase 1 but name is same)

## Todo List
- [x] Update label style to 13px w600 textPrimary
- [x] Update label-to-field gap to 6px
- [x] Update hint color to textTertiary
- [x] Update content padding to horizontal 16px
- [x] Update border radius to 12px
- [x] Update border width to 1.5px (all states)
- [x] Update border colors (divider -> border)
- [x] Add errorLight fill for error state
- [x] Verify compilation

## Success Criteria
- No reference to `AppColors.textHint` or `AppColors.divider` in this file
- Border radius is 12px
- Border width is 1.5px
- Error state shows errorLight fill
- Label is 13px w600 textPrimary
- Content padding horizontal is 16px
