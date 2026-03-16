# Phase 2: Replace Text with AppText Across Codebase

## Context Links
- Phase 1: `./phase-01-enhance-app-text-widget.md`
- AppText: `lib/shared/widgets/app_text.dart`
- AppTextStyles: `lib/core/constants/app_text_styles.dart`

## Overview
- **Priority:** High
- **Status:** completed
- **Description:** Replace ~100 raw `Text(` widgets with `AppText(` across all feature and shared widget files.

## Key Insights

### Variant Mapping Guide

| Pattern in code | Maps to AppTextVariant | Notes |
|---|---|---|
| `AppTextStyles.h1` or `font8XL, w700` | `h1` | |
| `AppTextStyles.h2` or `font6XL, w600` | `h2` | |
| `AppTextStyles.h3` or `font4XL, w600` | `h3` | |
| `AppTextStyles.bodyLarge` or `fontXL, w400` | `bodyLarge` | |
| `AppTextStyles.bodyMedium` or `fontM, w400` | `bodyMedium` | Default variant |
| `AppTextStyles.bodySmall` or `fontXS, w400, textSecondary` | `bodySmall` | |
| `AppTextStyles.button` or `font3XL, w600, white` | `button` | |
| `AppTextStyles.caption` or `fontXS, w400, textTertiary` | `caption` | |
| `AppTextStyles.label` or `fontM, w500, textSecondary` | `label` | |
| Custom `GoogleFonts.outfit(...)` not matching above | Use `style:` override | |

### What to skip (DO NOT replace)
- `Text` inside `RichText` children -- these are `TextSpan`, not `Text` widgets
- `Text` inside `SelectableText` -- same reason
- Emoji-only Text widgets (e.g., `Text(language.flag, style: TextStyle(fontSize: ...))`) -- no Outfit font needed
- `Text` inside `AppText.build()` itself
- `Text` inside `AppBar(title: Text(...))` -- these use Material theme, keep raw

## Related Code Files

All files below need `Text(` -> `AppText(` replacement. Grouped by area for batch processing.

### Shared Widgets (6 files)
- `lib/shared/widgets/app_button.dart` -- 1 Text (button style)
- `lib/shared/widgets/app_text_field.dart` -- 1 Text (label)
- `lib/shared/widgets/word-translation-sheet.dart` -- 10 Text (various custom styles)
- `lib/shared/widgets/loading_widget.dart` -- 1 Text
- `lib/shared/widgets/error_widget.dart` -- already uses AppText, skip

### Auth Feature (7 files)
- `lib/features/auth/widgets/social_auth_button.dart` -- 2 Text
- `lib/features/auth/widgets/auth_text_field.dart` -- 1 Text (label)
- `lib/features/auth/widgets/login_gate_bottom_sheet.dart` -- 4 Text (skip RichText child)
- `lib/features/auth/views/forgot_password_screen.dart` -- 4 Text
- `lib/features/auth/views/login_email_screen.dart` -- 5 Text (skip RichText child)
- `lib/features/auth/views/signup_email_screen.dart` -- 4 Text (skip RichText child)
- `lib/features/auth/views/new_password_screen.dart` -- 4 Text
- `lib/features/auth/views/otp_verification_screen.dart` -- 3 Text (skip RichText child)

### Chat Feature (8 files)
- `lib/features/chat/widgets/chat_top_bar.dart` -- 2 Text (skip emoji Text)
- `lib/features/chat/widgets/chat-conversation-tile.dart` -- 3 Text
- `lib/features/chat/widgets/quick_reply_row.dart` -- 1 Text
- `lib/features/chat/widgets/text_action_button.dart` -- 1 Text
- `lib/features/chat/widgets/user_message_bubble.dart` -- 1 Text
- `lib/features/chat/widgets/ai_message_bubble.dart` -- 3 Text
- `lib/features/chat/widgets/chat_recording_bar.dart` -- 1 Text
- `lib/features/chat/views/chat-home-screen.dart` -- 3 Text
- `lib/features/chat/views/ai_chat_screen.dart` -- 2 Text

### Onboarding Feature (6 files)
- `lib/features/onboarding/widgets/onboarding_top_bar.dart` -- 2 Text
- `lib/features/onboarding/widgets/language_card.dart` -- 4 Text (skip 3 emoji Text in _LanguageFlag)
- `lib/features/onboarding/widgets/scenario_card.dart` -- 3 Text
- `lib/features/onboarding/views/splash_screen.dart` -- 2 Text
- `lib/features/onboarding/views/welcome_problem_screen.dart` -- 4 Text
- `lib/features/onboarding/views/native_language_screen.dart` -- 4 Text
- `lib/features/onboarding/views/scenario_gift_screen.dart` -- 3 Text
- `lib/features/onboarding/views/learning_language_screen.dart` -- 4 Text

### Other Features (4 files)
- `lib/features/profile/views/profile-screen.dart` -- 7 Text
- `lib/features/vocabulary/views/vocabulary-screen.dart` -- 4 Text
- `lib/features/home/widgets/bottom-nav-bar.dart` -- 1 Text
- `lib/features/lessons/views/read-screen.dart` -- 2 Text

### Routes (skip)
- `lib/app/routes/app-page-definitions-with-transitions.dart` -- 3 Text in AppBar, keep raw

## Implementation Steps

Process each file batch:

1. **For each file:**
   a. Read the file
   b. Add import: `import 'package:flowering/shared/widgets/app_text.dart';` (use relative path per project convention)
   c. For each `Text(` widget:
      - If style matches a variant exactly -> `AppText(text, variant: AppTextVariant.xxx)`
      - If style is close to variant but needs color override -> `AppText(text, variant: ..., color: ...)`
      - If style needs weight/size override -> `AppText(text, variant: ..., fontWeight: ..., fontSize: ...)`
      - If style is fully custom -> `AppText(text, style: GoogleFonts.outfit(...))`
      - Preserve `.tr`, `maxLines`, `overflow`, `textAlign` params
   d. Remove unused `GoogleFonts` import if all direct usages replaced
   e. Remove unused `AppTextStyles` import if not needed elsewhere in file

2. **After each batch (area group):**
   - Run `flutter analyze` to verify no errors
   - Fix any issues before moving to next batch

3. **Processing order:**
   - Shared widgets first (most reused)
   - Then auth, chat, onboarding, other features

## Replacement Examples

### Direct variant match
```dart
// Before
Text('chat_home_title'.tr, style: AppTextStyles.h2)
// After
AppText('chat_home_title'.tr, variant: AppTextVariant.h2)
```

### Variant + color override
```dart
// Before
Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.primary))
// After
AppText(value, variant: AppTextVariant.h3, color: AppColors.primary)
```

### Custom style (no variant match)
```dart
// Before
Text(word, style: GoogleFonts.outfit(fontSize: AppSizes.font6XL, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
// After (this IS h1 -- font8XL w700... wait, font6XL != font8XL, so use h2 + fontWeight override)
AppText(word, variant: AppTextVariant.h2, fontWeight: FontWeight.w700)
```

### Custom style with no close variant
```dart
// Before
Text(ex, style: GoogleFonts.outfit(fontSize: AppSizes.fontSM, color: AppColors.textSecondary, fontStyle: FontStyle.italic, height: AppSizes.lineHeightLoose))
// After
AppText(ex, variant: AppTextVariant.bodySmall, fontSize: AppSizes.fontSM, fontStyle: FontStyle.italic, height: AppSizes.lineHeightLoose, color: AppColors.textSecondary)
```

## Todo List

- [x] Shared widgets batch (app_button, app_text_field, word-translation-sheet, loading_widget)
- [x] Run `flutter analyze`
- [x] Auth feature batch (7 files)
- [x] Run `flutter analyze`
- [x] Chat feature batch (9 files)
- [x] Run `flutter analyze`
- [x] Onboarding feature batch (7 files)
- [x] Run `flutter analyze`
- [x] Other features batch (profile, vocabulary, home, lessons)
- [x] Run `flutter analyze`

## Success Criteria

- Zero raw `Text(` outside of: AppText internals, RichText/SelectableText children, emoji Text, AppBar titles
- `flutter analyze` passes
- All `.tr` translations preserved
- No visual regressions (same font/size/weight/color)

## Risk Assessment

- **Medium risk**: High volume of changes across many files ✅ Mitigated by batch processing
- **Mitigation**: Process in batches with `flutter analyze` after each ✅ Completed
- **Visual regression**: Each replacement must map style params correctly. When in doubt, use `style:` full override rather than guessing a variant. ✅ All mappings verified
- **Import paths**: Use relative imports consistently per project convention ✅ All imports updated

## Completion Notes

Phase 2 successfully completed. Text→AppText replacement across entire codebase:
- 100 raw `Text(` replaced with `AppText(` across ~30 files
- Shared widgets: 4 files updated
- Auth feature: 8 files updated
- Chat feature: 9 files updated
- Onboarding feature: 8 files updated
- Other features: 4 files updated
- All `flutter analyze` checks passed (zero errors/warnings)
- All tests passing (5/5)
- Code review issues fixed:
  - Style merge logic corrected
  - Logout button color fixed
  - Semantic variant applied correctly
  - Unused GoogleFonts import removed
- No visual regressions detected
- All `.tr` translations preserved
- All color overrides correctly applied
