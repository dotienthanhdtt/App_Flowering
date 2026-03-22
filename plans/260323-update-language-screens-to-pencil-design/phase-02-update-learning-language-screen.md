# Phase 02 — Update Screen 07: Learning Language

## Overview
- **Priority:** High
- **Status:** Pending
- **Description:** Align `learning_language_screen.dart` with Pencil design `07_onboarding_target_language`

## Key Design Specs (from Pencil)

### Layout Structure
```
Column (vertical, fill)
├── Safe Area Spacer (30px)
├── Top Bar (h48, padding h16)
│   └── Arrow-left icon (24px, #545F71)
├── Title Wrapper (padding h16)
│   └── "What language do you want to learn?" — Inter 28px bold #1A1A1A
├── Gap (24px)
└── Bottom Section (fill, padding h16, gap 12)
    ├── Content Area (fill, gap 10, clip)
    │   ├── Language Grid (vertical, gap 10) — misleading name, actually a list
    │   │   └── Language Card × N
    │   └── Show All Button (h36, cornerRadius 8, gap 4, centered)
    │       ├── "Show all languages" — Inter 14 medium #545F71
    │       └── Chevron-down icon (14px, #545F71)
    └── Footer (padding bottom 34)
        └── Continue Button
            └── Frame: fill #FD9029, h52, cornerRadius 12, opacity 0.5
                └── "Continue" — Inter 18 semibold #FFFFFF
```

### Language Card (target variant)
```
Row (padding 16, gap 16, cornerRadius 12, bg white, border #E5E5E5)
├── Flag (48px circle, network image with cornerRadius 24)
├── Text Section (column, gap 4)
│   ├── Language Name — Inter 16 semibold #1A1A1A
│   └── Native Name — Inter 14 normal #545F71
└── Chevron Right icon (20px, #545F71)
```

## Related Code Files
- **Modify:** `lib/features/onboarding/views/learning_language_screen.dart`
- **Modify:** `lib/features/onboarding/widgets/language_card.dart` (replace LanguageGridCard with list variant)
- **Modify:** `lib/features/onboarding/controllers/onboarding_controller.dart`
- **Modify:** `lib/l10n/english-translations-en-us.dart`
- **Modify:** `lib/l10n/vietnamese-translations-vi-vn.dart`

## Implementation Steps

### 1. Update `learning_language_screen.dart`
1. Add back arrow icon at top (lucide arrow-left style → `Icons.arrow_back` or similar)
   - Simple icon, NOT in a styled container — just the icon in a top bar
   - Size 24px, color #545F71
2. Remove subtitle text
3. Update title padding: horizontal 16
4. **Replace GridView with ListView** using `LanguageListCard` (same widget as screen 06)
   - Card uses 48px flag (unlike 36px on screen 06), padding 16
   - Gap between cards: 10px
5. Add "Show all languages" button below list:
   - Row centered: text "Show all languages" + chevron-down icon
   - Inter 14 medium, color #545F71, h36, cornerRadius 8
   - Initially show limited languages (e.g., first 7), tap to show all
6. Add Continue button at bottom (outside scrollable area):
   - Background: #FD9029 (AppColors.primaryColor or custom orange)
   - Height 52, corner radius 12, full width
   - Text: "Continue", Inter 18 semibold, white
   - Opacity 0.5 when no language selected, 1.0 when selected
   - Bottom padding: 34px (safe area)

### 2. Update controller (`onboarding_controller.dart`)
1. Remove auto-navigation timer from `selectLearningLanguage()`
   - Currently navigates after 400ms delay — remove this
   - Instead, just update the selected language observable
2. Add `confirmLearningLanguage()` method that navigates to chat
3. Continue button calls `confirmLearningLanguage()`

### 3. Delete `LanguageGridCard` from `language_card.dart`
- No longer needed — screen 07 now uses list cards
- Update `LanguageListCard` to accept optional `flagSize` parameter (36 for screen 06, 48 for screen 07)
- Update `LanguageListCard` to accept optional `cardPadding` parameter (12 for screen 06, 16 for screen 07)

### 4. Update translations
- Add `'show_all_languages'`: EN "Show all languages", VI "Hien thi tat ca ngon ngu"
- Add `'continue_button'`: EN "Continue", VI "Tiep tuc"
- Update `'language_select_title'` if needed

## Todo List
- [ ] Add back arrow in top bar
- [ ] Remove subtitle, update title padding to h16
- [ ] Replace GridView with ListView using LanguageListCard
- [ ] Make LanguageListCard configurable (flagSize, cardPadding)
- [ ] Add "Show all languages" expandable button
- [ ] Add Continue button with opacity state
- [ ] Update controller: remove auto-nav, add confirmLearningLanguage()
- [ ] Delete LanguageGridCard (no longer used)
- [ ] Add translation keys
- [ ] Verify compilation

## Success Criteria
- Screen matches Pencil design `07_onboarding_target_language`
- Continue button disabled (opacity 0.5) until language selected
- Back arrow navigates to previous screen
- "Show all" expands the language list
- No compilation errors

## Risk Assessment
- **Breaking change:** Removing auto-navigation changes UX flow — users must now tap Continue
- **LanguageGridCard removal:** Ensure no other screen uses it before deleting
