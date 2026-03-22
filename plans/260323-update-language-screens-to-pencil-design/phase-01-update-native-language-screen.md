# Phase 01 — Update Screen 06: Native Language

## Overview
- **Priority:** High
- **Status:** Pending
- **Description:** Align `native_language_screen.dart` with Pencil design `06_onboarding_native_language`

## Key Design Specs (from Pencil)

### Layout Structure
```
Column (vertical, fill)
├── Safe Area Spacer (30px)
├── Top Bar (h48, padding h16) — EMPTY (no back button)
├── Title Wrapper (padding h16)
│   └── "What language do you speak?" — Inter 28px bold #1A1A1A
├── Gap (24px)
└── Bottom Section (fill, padding [0,16,34,16])
    ├── Search Input
    │   └── Field: cornerRadius 16, border #9CB0CF, shadow, h52
    │       └── "Search language..." placeholder #9CB0CF, Inter 14
    ├── Gap 16
    └── Cards Container (fill, gap 8, clip, scrollable)
        └── Language Card × N
```

### Language Card (list variant)
```
Row (padding 12, gap 16, cornerRadius 12, bg white, border #E5E5E5)
├── Flag (36px circle, network image)
├── Text Section (column, gap 4)
│   ├── Language Name — Inter 16 semibold #1A1A1A
│   └── Native Name — Inter 14 normal #545F71
└── Chevron Right icon (20px, #545F71)
```

## Related Code Files
- **Modify:** `lib/features/onboarding/views/native_language_screen.dart`
- **Modify:** `lib/features/onboarding/widgets/language_card.dart` (LanguageListCard)
- **Modify:** `lib/l10n/english-translations-en-us.dart` (add search placeholder key)
- **Modify:** `lib/l10n/vietnamese-translations-vi-vn.dart`

## Implementation Steps

### 1. Update `native_language_screen.dart`
1. Remove the back button section entirely
2. Remove subtitle text
3. Update title padding: horizontal 16 (not 24)
4. Add search text field between title and language list:
   - Use `AppTextField` or build a simple search field
   - Placeholder: "Search language..."
   - Corner radius 16, border color `#9CB0CF`, height 52
   - Shadow: blur 8, color `#0000000D`, offset (0,2)
   - Wire up filtering in controller (add `searchQuery` observable + filtered list)
5. Update list padding: horizontal 16, bottom safe area 34
6. Update separator height: 8px (currently 12)

### 2. Update `LanguageListCard` in `language_card.dart`
1. Change flag size from `avatarM` (40) to 36px
2. Remove fixed height (currently 64), let content size naturally
3. Change card padding: all 12 (currently horizontal 16)
4. Change internal gap to 16 (between flag, text, chevron)
5. Add `chevron-right` icon (20px, color `#545F71`) at end of row
6. Update text styles:
   - Name: Inter 16 semibold (currently bodyLarge w600 — check fontSize)
   - Subtitle: Inter 14 normal color #545F71
7. Remove selected check icon (keep selected border highlight)
8. Keep coming soon badge

### 3. Add search/filter to controller
1. Add `nativeSearchQuery` observable string
2. Add `filteredNativeLanguages` computed getter that filters by query
3. Use filtered list in the view

### 4. Update translations
- Add `'search_language'` key: EN "Search language...", VI "Tim ngon ngu..."

## Todo List
- [ ] Remove back button from native language screen
- [ ] Remove subtitle, update title padding to h16
- [ ] Add search input field
- [ ] Wire search filtering in controller
- [ ] Update LanguageListCard: flag 36px, padding 12, gap 16, add chevron
- [ ] Update list separator to 8px gap
- [ ] Update horizontal padding to 16
- [ ] Add translation keys
- [ ] Verify compilation

## Success Criteria
- Screen matches Pencil design `06_onboarding_native_language`
- Search filters language list by name/subtitle
- No compilation errors
