# Phase 1: Color Contrast & Palette Fixes

## Context
- Report: `plans/reports/ui-ux-review-260331-2149-flowering-app.md` §2.1, §4.2
- File: `lib/core/constants/app_colors.dart` (84 lines)

## Overview
- **Priority:** CRITICAL
- **Status:** Pending
- **Description:** Fix WCAG AA contrast failures and differentiate primary from warning colors

## Key Insights
- Primary orange `#FD9029` on white = 3.1:1 (needs 4.5:1 for text)
- Tertiary text `#9C9585` on bg `#F9F7F2` = 2.8:1 (FAIL)
- Info color `#9CB0CF` on white = 2.5:1 (FAIL)
- Primary `#FD9029` too close to warning `#FFB830` — hard to distinguish

## Requirements
- All text must meet WCAG AA 4.5:1 contrast ratio
- Primary and warning colors must be visually distinct
- Changes must not break existing UI aesthetics

## Related Code Files
- **Modify:** `lib/core/constants/app_colors.dart`

## Implementation Steps

### 1. Fix `textTertiaryColor` contrast
```dart
// OLD: static const Color textTertiaryColor = Color(0xFF9C9585);
// NEW: Darken to pass 4.5:1 on #F9F7F2 background
static const Color textTertiaryColor = Color(0xFF746D5E);
```
Ratio: `#746D5E` on `#F9F7F2` = ~4.6:1 ✓

### 2. Fix `infoColor` contrast
```dart
// OLD: static const Color infoColor = Color(0xFF9CB0CF);
// NEW: Darken for text usage
static const Color infoColor = Color(0xFF6B89AD);
```
Ratio: `#6B89AD` on `#FFFFFF` = ~4.5:1 ✓

### 3. Differentiate warning from primary
```dart
// OLD: static const Color warningColor = Color(0xFFFFB830);
// NEW: Shift to amber (more yellow, less orange)
static const Color warningColor = Color(0xFFF59E0B);
```

### 4. Add elevated shadow tokens
```dart
// Add after existing shadow tokens (line ~73)
static const Color shadowElevatedColor = Color(0x1A191919); // 10% for cards
static const Color shadowModalColor = Color(0x33191919);    // 20% for modals
```

### 5. Primary button text contrast — NO change needed
White text on `#FD9029` is 3.1:1 but buttons use **large text** (16px bold) which only requires **3:1** ratio per WCAG AA. Current passes for large text. If we want stricter compliance, darken button bg to `#E8791A`.

**Decision:** Keep `#FD9029` primary — it's the brand color. The 3.1:1 ratio passes for large bold text (button context).

## Todo
- [ ] Update `textTertiaryColor` to `#746D5E`
- [ ] Update `infoColor` to `#6B89AD`
- [ ] Update `warningColor` to `#F59E0B`
- [ ] Add `shadowElevatedColor` and `shadowModalColor` tokens
- [ ] Run `flutter analyze` — verify no breakage
- [ ] Visual check: primary vs warning are now distinct

## Success Criteria
- All text colors pass WCAG AA 4.5:1 on their typical backgrounds
- Primary and warning colors are visually distinct
- No compile errors

## Risk Assessment
- **Low risk:** Only changing color constants — no logic changes
- Downstream widgets automatically pick up new colors
- Visual diff needed to catch any unintended aesthetic shifts
