# Phase 01: Replace Legacy Tokens with Design Tokens

## Overview
- **Priority:** High
- **Status:** Pending
- **Total replacements:** ~500+ occurrences across ~55 files

## Rules
1. **Same value** → direct rename to new design token
2. **Different value** → select nearest design token value

---

## Replacement Mapping

### Spacing (spacingXXX → spaceN)

| Legacy Token | Value | → New Token | Value | Type |
|-------------|-------|-------------|-------|------|
| `spacingXXS` | 2 | `space1` | 4 | nearest (diff 2) |
| `spacingXS` | 4 | `space1` | 4 | exact |
| `spacingSM` | 6 | `space2` | 8 | nearest (diff 2) |
| `spacingS` | 8 | `space2` | 8 | exact |
| `spacingM` | 12 | `space3` | 12 | exact |
| `spacingL` | 16 | `space4` | 16 | exact |
| `spacingXL` | 20 | `space5` | 20 | exact |
| `spacingXXL` | 24 | `space6` | 24 | exact |
| `spacing3XL` | 28 | `space6` | 24 | nearest (diff 4) |
| `spacing4XL` | 32 | `space8` | 32 | exact |
| `spacing6XL` | 60 | `space16` | 64 | nearest (diff 4) |

**Usages: 152 total**

### Padding (paddingXXX → spaceN)

| Legacy Token | Value | → New Token | Value | Type |
|-------------|-------|-------------|-------|------|
| `paddingXS` | 8 | `space2` | 8 | exact |
| `paddingSM` | 12 | `space3` | 12 | exact |
| `paddingM` | 14 | `space4` | 16 | nearest (diff 2) |
| `paddingL` | 16 | `space4` | 16 | exact |
| `paddingXL` | 20 | `space5` | 20 | exact |
| `paddingXXL` | 24 | `space6` | 24 | exact |
| `padding3XL` | 32 | `space8` | 32 | exact (0 usages) |

**Usages: 105 total**

### Font Sizes (fontXXX → fontSizeXxx)

| Legacy Token | Value | → New Token | Value | Type |
|-------------|-------|-------------|-------|------|
| `fontXXS` | 11 | `fontSizeXSmall` | 12 | nearest (diff 1) |
| `fontXS` | 12 | `fontSizeXSmall` | 12 | exact |
| `fontSM` | 13 | `fontSizeSmall` | 14 | nearest (diff 1) |
| `fontM` | 14 | `fontSizeSmall` | 14 | exact |
| `fontL` | 15 | `fontSizeMedium` | 16 | nearest (diff 1) |
| `fontXL` | 16 | `fontSizeMedium` | 16 | exact |
| `fontXXL` | 17 | `fontSizeLarge` | 18 | nearest (diff 1) |
| `font3XL` | 18 | `fontSizeLarge` | 18 | exact |
| `font4XL` | 20 | `fontSizeXLarge` | 20 | exact |
| `font5XL` | 22 | `fontSize2XLarge` | 24 | nearest (diff 2) |
| `font6XL` | 24 | `fontSize2XLarge` | 24 | exact |
| `font7XL` | 30 | `fontSize3XLarge` | 28 | nearest (diff 2) |
| `font8XL` | 32 | `fontSize4XLarge` | 32 | exact |
| `font10XL` | 36 | `fontSize4XLarge` | 32 | nearest (diff 4) |

**Usages: 61 total**

### Line Heights (multiplier → absolute px)

| Legacy Token | Value (mult) | → New Token | Value (px) | Notes |
|-------------|-------------|-------------|-----------|-------|
| `lineHeightSnug` | 1.3 | Context-dependent | — | See conversion table below |
| `lineHeightNormal` | 1.4 | Context-dependent | — | See conversion table below |
| `lineHeightRelaxed` | 1.45 | Context-dependent | — | See conversion table below |
| `lineHeightLoose` | 1.5 | — | — | 0 usages, skip |

**Unit conversion:** Flutter `TextStyle.height` = lineHeightPx / fontSize

| Design pair | fontSize | lineHeight (px) | Flutter height ratio |
|------------|----------|-----------------|---------------------|
| x-small | 12 | 14 | 1.167 |
| small | 14 | 16 | 1.143 |
| base | 14 | 20 | 1.429 |
| medium | 16 | 20 | 1.250 |
| large | 18 | 24 | 1.333 |
| x-large | 20 | 24 | 1.200 |
| 2x-large | 24 | 28 | 1.167 |
| 3x-large | 28 | 32 | 1.143 |
| 4x-large | 32 | 36 | 1.125 |
| 5x-large | 48 | 40 | 0.833 |

**Strategy:** At each usage site, check which fontSize is used alongside the lineHeight, then replace with the matching design pair's ratio (lineHeightPx / fontSize).

**Usages: 12 total**

### Components

| Legacy Token | Value | → New Token | Value | Type |
|-------------|-------|-------------|-------|------|
| `buttonHeightM` | 52 | `buttonHeightLarge` | 52 | exact (0 usages) |
| `inputHeight` | 40 | `buttonHeightMedium` | 44 | nearest (diff 4) |
| `cardHeightCompact` | 68 | `space16` | 64 | nearest (diff 4) |

**Usages: 16 total (inputHeight=9, cardHeightCompact=7)**

---

## Implementation Phases (by file group)

### Phase 1A: Core constants (2 files)
Files:
- `lib/core/constants/app_text_styles.dart` — 14 font token replacements
- `lib/core/constants/app_colors.dart` — 4 radius references (out of scope, skip)

### Phase 1B: Shared widgets (7 files)
Files:
- `lib/shared/widgets/app_button.dart`
- `lib/shared/widgets/app_text_field.dart`
- `lib/shared/widgets/word-translation-sheet.dart`
- `lib/shared/widgets/error_widget.dart`
- `lib/shared/widgets/loading_widget.dart`
- `lib/shared/widgets/loading_overlay.dart`
- `lib/shared/widgets/app_icon.dart`

### Phase 1C: Auth feature (12 files)
Files:
- `lib/features/auth/widgets/login_gate_bottom_sheet.dart`
- `lib/features/auth/widgets/auth_text_field.dart`
- `lib/features/auth/widgets/social_auth_button.dart`
- `lib/features/auth/widgets/otp_input_field.dart`
- `lib/features/auth/views/login_email_screen.dart`
- `lib/features/auth/views/signup_email_screen.dart`
- `lib/features/auth/views/forgot_password_screen.dart`
- `lib/features/auth/views/new_password_screen.dart`
- `lib/features/auth/views/otp_verification_screen.dart`

### Phase 1D: Onboarding feature (10 files)
Files:
- `lib/features/onboarding/widgets/onboarding_top_bar.dart`
- `lib/features/onboarding/widgets/onboarding_value_layout.dart`
- `lib/features/onboarding/widgets/language_card.dart`
- `lib/features/onboarding/widgets/step_dots_indicator.dart`
- `lib/features/onboarding/widgets/scenario_card.dart`
- `lib/features/onboarding/views/splash_screen.dart`
- `lib/features/onboarding/views/native_language_screen.dart`
- `lib/features/onboarding/views/learning_language_screen.dart`
- `lib/features/onboarding/views/scenario_gift_screen.dart`

### Phase 1E: Chat feature (12 files)
Files:
- `lib/features/chat/widgets/ai_message_bubble.dart`
- `lib/features/chat/widgets/ai_typing_bubble.dart`
- `lib/features/chat/widgets/user_message_bubble.dart`
- `lib/features/chat/widgets/chat_top_bar.dart`
- `lib/features/chat/widgets/chat_input_bar.dart`
- `lib/features/chat/widgets/chat_text_input_field.dart`
- `lib/features/chat/widgets/chat_recording_bar.dart`
- `lib/features/chat/widgets/chat_action_button.dart`
- `lib/features/chat/widgets/chat-conversation-tile.dart`
- `lib/features/chat/widgets/grammar_correction_section.dart`
- `lib/features/chat/widgets/quick_reply_row.dart`
- `lib/features/chat/widgets/text_action_button.dart`
- `lib/features/chat/views/ai_chat_screen.dart`
- `lib/features/chat/views/chat-home-screen.dart`

### Phase 1F: Other features (5 files)
Files:
- `lib/features/profile/views/profile-screen.dart`
- `lib/features/vocabulary/views/vocabulary-screen.dart`
- `lib/features/lessons/views/read-screen.dart`
- `lib/features/home/widgets/bottom-nav-bar.dart`
- `lib/app/routes/app-page-definitions-with-transitions.dart`

### Phase 1G: Cleanup
- Remove all legacy tokens from `app_sizes.dart`
- Remove legacy line height multipliers
- Remove `padding3XL` (0 usages)
- Keep `cardHeightCompact` (no design equivalent)
- Keep `trackingSnug` (no design equivalent)
- Run `flutter analyze` to verify

---

## Todo

- [ ] Phase 1A: Replace tokens in core constants
- [ ] Phase 1B: Replace tokens in shared widgets
- [ ] Phase 1C: Replace tokens in auth feature
- [ ] Phase 1D: Replace tokens in onboarding feature
- [ ] Phase 1E: Replace tokens in chat feature
- [ ] Phase 1F: Replace tokens in other features
- [ ] Phase 1G: Cleanup — remove legacy tokens from app_sizes.dart
- [ ] Run `flutter analyze` — zero errors

## Risk Assessment
- **Value changes** (nearest mapping): ~15 tokens change value slightly (1-4px). May cause minor visual shifts in spacing/font sizes. Review on device after replacement.
- **Line height unit change**: Multiplier → px ratio requires per-site conversion. Most impactful change.
- **`inputHeight` context**: 40px used for buttons, not inputs. Each usage needs context review.

## Success Criteria
- All legacy spacing/padding/font tokens replaced with design tokens
- Zero compile errors
- Legacy section in app_sizes.dart cleaned up
- Visual review on device confirms acceptable appearance
