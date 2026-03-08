# Phase 1: Enhance AppText Widget

## Context Links
- Widget: `lib/shared/widgets/app_text.dart`
- Styles: `lib/core/constants/app_text_styles.dart`

## Overview
- **Priority:** High (blocks Phase 2)
- **Status:** completed
- **Description:** Add `button` variant and flexible override params to `AppText` so it can handle edge cases found in the codebase.

## Key Insights

Many `Text` widgets in the codebase use custom `GoogleFonts.outfit()` styles that don't exactly match any `AppTextVariant`. Examples:
- `fontSize: fontSM, w400, textSecondary` -- close to `bodySmall` but different size (13 vs 12)
- `fontSize: fontXS, w600, accentBlue` -- caption-like but bold + custom color
- `fontSize: font3XL, w700, textPrimary` -- between h3 (font4XL) and bodyLarge (fontXL)
- `fontStyle: FontStyle.italic` -- no variant supports this

The `style` full-override param handles these without bloating the enum.

## Requirements

### Functional
1. Add `button` to `AppTextVariant` enum
2. Add optional `fontWeight` param -- overrides variant's weight
3. Add optional `fontSize` param -- overrides variant's size
4. Add optional `style` param (TextStyle) -- full override, ignores variant entirely
5. Add optional `decoration` param (TextDecoration)
6. Add optional `fontStyle` param (FontStyle) -- for italic text
7. Add optional `height` param (double) -- line height

### Non-functional
- Keep widget under 80 lines
- Maintain const constructor where possible

## Related Code Files

### Files to modify
- `lib/shared/widgets/app_text.dart`

### Files to NOT modify
- `lib/core/constants/app_text_styles.dart` (already has `button` style)

## Implementation Steps

1. Open `lib/shared/widgets/app_text.dart`
2. Add `button` to `AppTextVariant` enum
3. Add optional params to constructor: `fontWeight`, `fontSize`, `style`, `decoration`, `fontStyle`, `height`
4. Update `build()` method:
   - If `style` is provided, use it directly (apply `color` override on top if set)
   - Otherwise use variant style with `.copyWith()` applying all non-null overrides
5. Add `button` case to `_getStyle()` switch
6. Run `flutter analyze` to verify

## Todo List

- [x] Add `button` to enum
- [x] Add optional override params
- [x] Update build logic for `style` full override
- [x] Add `button` case to switch
- [x] Run `flutter analyze`

## Success Criteria

- `AppText('Go', variant: AppTextVariant.button)` works
- `AppText('Custom', style: GoogleFonts.outfit(...))` works
- `AppText('Bold body', variant: AppTextVariant.bodyMedium, fontWeight: FontWeight.w600)` works
- `flutter analyze` passes with no new issues

## Risk Assessment

- **Low risk**: Additive change only, no existing behavior modified ✅
- Existing `AppText` usages (2 places) continue working unchanged since all new params are optional ✅

## Completion Notes

Phase 1 successfully completed. AppText widget enhanced with:
- Added `button` variant to enum
- Added optional params: `fontWeight`, `fontSize`, `style`, `decoration`, `fontStyle`, `height`
- Updated build logic to merge overrides correctly
- All `flutter analyze` checks passed
- No new errors or warnings introduced
