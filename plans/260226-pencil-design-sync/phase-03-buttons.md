# Phase 3: Buttons

## Context Links
- Depends on: Phase 1 (color names), Phase 2 (text styles)
- Current file: `lib/shared/widgets/app_button.dart` (134 lines)

## Overview
- **Priority:** P1
- **Status:** Complete
- **Description:** Restyle AppButton to match Pencil component specs. Changes to height, radius, padding, colors, shadows, and font size.

## Key Insights
- Height: 56px -> 48px
- Radius: 28 -> pill (100)
- Secondary variant: green background -> primarySoft bg with primary text
- Outline variant: primary border -> borderStrong border with textSecondary text
- Font: 18px -> 15px (button text style updated in Phase 2 if needed, or override here)
- Primary gets a subtle orange shadow
- Horizontal padding: 32px -> 24px

## Requirements

### Functional
- Primary: bg=`primary`, fg=`textOnPrimary`, shadow `#FF7A2730` blur:8 y:2
- Secondary: bg=`primarySoft`, fg=`primary` (was green bg + white text)
- Outline: bg=`surface`, fg=`textSecondary`, border=`borderStrong` 1.5px
- Text: fg=`primary`, no background
- All variants: height 48px, pill radius (100), horizontal padding 24px

### Non-Functional
- Keep existing `AppButtonVariant` enum
- Keep `isLoading`, `isFullWidth`, `icon` support
- File stays under 200 lines

## Related Code Files
- **Modify:** `lib/shared/widgets/app_button.dart`

## Implementation Steps

1. Change default height from 56.0 to 48.0
2. Change default padding from `horizontal: 32` to `horizontal: 24`
3. Change all `BorderRadius.circular(28)` to `BorderRadius.circular(AppColors.radiusPill)` (or 100)

4. Update **primary** variant:
   - `backgroundColor: AppColors.primary` (no change)
   - `foregroundColor: Colors.white` (no change, but semantically = textOnPrimary)
   - Add shadow: `BoxShadow(color: Color(0x30FF7A27), blurRadius: 8, offset: Offset(0, 2))`
   - Use Container wrapper or `ElevatedButton.styleFrom` elevation trick

5. Update **secondary** variant:
   - `backgroundColor: AppColors.primarySoft` (was `AppColors.secondary`)
   - `foregroundColor: AppColors.primary` (was `Colors.white`)

6. Update **outline** variant:
   - `foregroundColor: AppColors.textSecondary` (was `AppColors.primary`)
   - `side: BorderSide(color: AppColors.borderStrong, width: 1.5)` (was `AppColors.primary`)
   - Add `backgroundColor: AppColors.surface`

7. Update **text** variant:
   - `foregroundColor: AppColors.primary` (no change)

8. Update `_textStyle` getter:
   - Primary/Secondary: `AppTextStyles.button` (font size will be 15px after Phase 2 or override here)
   - Outline: `AppTextStyles.button.copyWith(color: AppColors.textSecondary)`
   - Text: `AppTextStyles.button.copyWith(color: AppColors.primary)`

9. Update button text style font size to 15px w600 (may need to override `AppTextStyles.button` or apply `.copyWith(fontSize: 15)`)

## Todo List
- [x] Update default height to 48px
- [x] Update default padding to 24px horizontal
- [x] Update border radius to pill (100)
- [x] Update primary variant with shadow
- [x] Update secondary variant (primarySoft bg, primary text)
- [x] Update outline variant (surface bg, borderStrong border, textSecondary text)
- [x] Update text style to 15px w600
- [x] Verify compilation

## Success Criteria
- No reference to `AppColors.secondary` in this file
- Button height is 48px
- Border radius is pill (100)
- Primary has orange shadow
- Secondary uses primarySoft background
- Outline uses borderStrong border
