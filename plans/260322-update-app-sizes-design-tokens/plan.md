# Update AppSizes Design Tokens

## Status: In Progress

## Phases
1. **Add design tokens to app_sizes.dart** — DONE
2. **[Replace legacy tokens across codebase](phase-01-replace-legacy-tokens.md)** — Pending (~500+ replacements, 55 files)

## Summary
Restructure `app_sizes.dart` to match design file token naming, split into **NEW** (from design) and **OLD** (used in codebase but not in design file).

## Scope
- Font sizes
- Spacing
- Components: Button, Input Field, Card only

---

## Phase 1: Update `app_sizes.dart` structure

### File: `lib/core/constants/app_sizes.dart`

**Split into two sections per category:**
1. `// ── [Category] (Design Tokens) ──` — tokens from design file
2. `// ── [Category] (Legacy) ──` — tokens used in codebase but NOT in design

---

## Design Token Mapping

### Spacing (Design File)

| Design Token | Value | Dart Name | Usage |
|-------------|-------|-----------|-------|
| space-0 | 0 | space0 | Reset |
| space-1 | 4 | space1 | Tight gaps (icon-to-text, chip padding) |
| space-2 | 8 | space2 | Inline spacing (between badges) |
| space-3 | 12 | space3 | Input/compact card padding |
| space-4 | 16 | space4 | Default content/card padding |
| space-5 | 20 | space5 | Between form fields |
| space-6 | 24 | space6 | Section gap inside screen |
| space-8 | 32 | space8 | Between major sections |
| space-10 | 40 | space10 | Screen top/bottom safe padding |
| space-12 | 48 | space12 | Large section dividers |
| space-16 | 64 | space16 | Hero/onboarding vertical spacing |

**Legacy spacing** (used in code, not in design):

| Current Name | Value | Keep? |
|-------------|-------|-------|
| spacingXXS = 2 | 2 | Yes (legacy) |
| spacingSM = 6 | 6 | Yes (legacy) |
| spacing3XL = 28 | 28 | Yes (legacy) |
| spacing6XL = 60 | 60 | Yes (legacy) |

**Mapped to design** (rename or alias):

| Old Name | Value | → Design Token |
|----------|-------|---------------|
| spacingXS = 4 | 4 | space1 |
| spacingS = 8 | 8 | space2 |
| spacingM = 12 | 12 | space3 |
| spacingL = 16 | 16 | space4 |
| spacingXL = 20 | 20 | space5 |
| spacingXXL = 24 | 24 | space6 |
| spacing4XL = 32 | 32 | space8 |

### Font Sizes (Design File — from Typography table)

| Design Token | Size | Weight | Line Height (px) | Dart Name | Usage |
|-------------|------|--------|-------------------|-----------|-------|
| font-size-5x-large | 48 | 700 (Bold) | 40 | fontSize5XLarge | Splash screens, onboarding hero |
| font-size-4x-large | 32 | 700 (Bold) | 36 | fontSize4XLarge | Screen titles |
| font-size-3x-large | 28 | 600 (SemiBold) | 32 | fontSize3XLarge | Section headers |
| font-size-2x-large | 24 | 600 (SemiBold) | 28 | fontSize2XLarge | Card titles, lesson names |
| font-size-x-large | 20 | 600 (SemiBold) | 24 | fontSizeXLarge | Sub-sections, modal titles |
| font-size-large | 18 | 400 (Regular) | 24 | fontSizeLarge | Primary reading text, lesson content |
| font-size-medium | 16 | 400 (Regular) | 20 | fontSizeMedium | Secondary text, descriptions |
| font-size-base | 14 | 500 (Medium) | 20 | fontSizeBase | Button text, input labels, tabs |
| font-size-small | 14 | 400 (Regular) | 16 | fontSizeSmall | Captions, timestamps, hints |
| font-size-x-small | 12 | 600 (SemiBold) | 14 | fontSizeXSmall | Category labels, streak counters |

> **Note:** `font-size-small` and `font-size-base` are both 14px but differ in weight (400 vs 500) and line height (16px vs 20px).

**Legacy font sizes** (used in code, not in design):

| Current Name | Value | Keep? |
|-------------|-------|-------|
| fontXXS = 11 | 11 | Yes (legacy) |
| fontSM = 13 | 13 | Yes (legacy) |
| fontL = 15 | 15 | Yes (legacy) |
| fontXXL = 17 | 17 | Yes (legacy) |
| font5XL = 22 | 22 | Yes (legacy) |
| font7XL = 30 | 30 | Yes (legacy) |
| font10XL = 36 | 36 | Yes (legacy) |

**Mapped to design** (rename or alias):

| Old Name | Value | → Design Token |
|----------|-------|---------------|
| fontXS = 12 | 12 | fontSizeXSmall |
| fontM = 14 | 14 | fontSizeSmall / fontSizeBase |
| fontXL = 16 | 16 | fontSizeMedium |
| font3XL = 18 | 18 | fontSizeLarge |
| font4XL = 20 | 20 | fontSizeXLarge |
| font6XL = 24 | 24 | fontSize2XLarge |
| font8XL = 32 | 32 | fontSize4XLarge |

### Line Heights (Design File — absolute px, NOT multipliers)

| Design Token | Value (px) | Dart Name | Paired With |
|-------------|-----------|-----------|-------------|
| line-height-x-small | 14 | lineHeightXSmall | font-size-x-small (12) |
| line-height-small | 16 | lineHeightSmall | font-size-small (14) |
| line-height-base | 20 | lineHeightBase | font-size-base (14) |
| line-height-medium | 20 | lineHeightMedium | font-size-medium (16) |
| line-height-large | 24 | lineHeightLarge | font-size-large (18) |
| line-height-x-large | 24 | lineHeightXLarge | font-size-x-large (20) |
| line-height-2x-large | 28 | lineHeight2XLarge | font-size-2x-large (24) |
| line-height-3x-large | 32 | lineHeight3XLarge | font-size-3x-large (28) |
| line-height-4x-large | 36 | lineHeight4XLarge | font-size-4x-large (32) |
| line-height-5x-large | 40 | lineHeight5XLarge | font-size-5x-large (48) |

> **BREAKING CHANGE:** Design uses absolute px line heights. Current code uses multipliers (1.3, 1.4, etc.). Move old multipliers to legacy. New line heights should be used as `height` property in `TextStyle` (converted to ratio: `lineHeight / fontSize`).

### Components — Button (Design File)

| Design Token | Value | Dart Name |
|-------------|-------|-----------|
| Button Large height | 52 | buttonHeightLarge |
| Button Medium height | 44 | buttonHeightMedium |
| Button Small height | 36 | buttonHeightSmall |
| Button Large radius | 12 | buttonRadiusLarge |
| Button Medium radius | 10 | buttonRadiusMedium |
| Button Small radius | 8 | buttonRadiusSmall |
| Button Large padding H | 24 | buttonPaddingLarge |
| Button Medium padding H | 20 | buttonPaddingMedium |
| Button Small padding H | 16 | buttonPaddingSmall |
| Button Large font | 18 | buttonFontLarge |
| Button Medium font | 14 | buttonFontMedium |
| Button Small font | 14 | buttonFontSmall |

**Legacy** (used in code, not in design): `buttonHeightM = 52` → maps to `buttonHeightLarge`

### Components — Input Field (Design File)

| Design Token | Value | Dart Name |
|-------------|-------|-----------|
| Input field height | 64 | inputFieldHeight |
| Input field radius | 16 | inputFieldRadius |
| Input field padding V | 12 | inputFieldPaddingV |
| Input field padding H | 16 | inputFieldPaddingH |
| Input field gap | 4 | inputFieldGap |
| Input label font | 12 | inputLabelFont |
| Input text font | 14 | inputTextFont |
| Input icon size | 20 | inputIconSize |
| Input border width | 1 | inputBorderWidth |

**Legacy**: `inputHeight = 40` → different from design (64), keep as legacy

### Components — Card (Design File — Language Card)

| Design Token | Value | Dart Name |
|-------------|-------|-----------|
| Card radius | 12 | cardRadius |
| Card padding | 16 | cardPadding |
| Card gap | 16 | cardGap |
| Card flag size | 48 | cardFlagSize |
| Card title font | 16 | cardTitleFont |
| Card subtitle font | 14 | cardSubtitleFont |
| Card chevron size | 20 | cardChevronSize |
| Card border width | 1 | cardBorderWidth |

**Legacy**: `cardHeightCompact = 68` → keep as legacy

---

## Phase 2: Update all usages across codebase

For each renamed variable, find-and-replace across all `.dart` files.

**Strategy:** Keep old names as `@Deprecated` aliases pointing to new names, OR do a full rename. User to decide.

---

## Todo

- [ ] Rewrite `app_sizes.dart` with new/old split structure
- [ ] Update button/input/card component widgets to use new tokens
- [ ] Run `flutter analyze` to verify no compile errors
- [ ] Verify no broken references

## Risk
- Many files reference old names — bulk rename needed
- Line height units change (multiplier → px) — may affect text rendering
