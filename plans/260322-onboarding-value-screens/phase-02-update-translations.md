# Phase 2: Update Translations (EN + VI)

## Status
**Complete**

## Overview
Replace old welcome_headline/body keys with new content matching the 3 design screens.

### Implementation Summary
- Added 10 new translation keys to English file (lib/l10n/english-translations-en-us.dart)
- Added 10 matching keys to Vietnamese file (lib/l10n/vietnamese-translations-vi-vn.dart)
- All keys present: onboarding_skip, onboarding_value_headline_1/2/3, onboarding_value_body_1/2/3, onboarding_next, onboarding_ready
- Removed old unused keys: welcome_headline_1/2/3, welcome_body_1/2/3, welcome_cta, welcome_tap_continue
- Both files verified for consistency

## New Translation Keys

### English
```dart
// Onboarding — Value Screens (Screens 03/04/05)
'onboarding_skip': 'Skip',
'onboarding_value_headline_1': 'A path shaped around you',
'onboarding_value_body_1': 'You lead. Flowering follows.\nEvery lesson adapts to where you are and where you\'re headed',
'onboarding_value_headline_2': 'Learn once. Remember forever.',
'onboarding_value_body_2': 'The secret? Timing. Flowering reviews words right when your brain needs it most — so nothing slips through.',
'onboarding_value_headline_3': 'Fluency isn\'t a test. It\'s a feeling.',
'onboarding_value_body_3': 'No more translating in your head. No more freezing up. Just you, saying exactly what you mean.',
'onboarding_next': 'Next',
'onboarding_ready': 'I\'m Ready',
```

### Vietnamese
```dart
'onboarding_skip': 'Bỏ qua',
'onboarding_value_headline_1': 'Con đường được tạo riêng cho bạn',
'onboarding_value_body_1': 'Bạn dẫn đường. Flowering theo sau.\nMỗi bài học thích ứng với nơi bạn đang đứng và nơi bạn muốn đến',
'onboarding_value_headline_2': 'Học một lần. Nhớ mãi mãi.',
'onboarding_value_body_2': 'Bí quyết? Thời điểm. Flowering ôn lại từ vựng đúng lúc não bạn cần nhất — không gì bị bỏ sót.',
'onboarding_value_headline_3': 'Lưu loát không phải bài kiểm tra. Đó là cảm giác.',
'onboarding_value_body_3': 'Không còn dịch trong đầu. Không còn đứng hình. Chỉ là bạn, nói chính xác điều bạn muốn.',
'onboarding_next': 'Tiếp',
'onboarding_ready': 'Tôi đã sẵn sàng',
```

## Files to Modify
- `lib/l10n/english-translations-en-us.dart` — replace lines 219-227
- `lib/l10n/vietnamese-translations-vi-vn.dart` — replace lines 219-227

## Notes
- Keep old keys `welcome_headline_1` etc. removed (no longer used)
- Keep `welcome_tap_continue` removed (no longer used)
- Keep `welcome_cta` removed (replaced by `onboarding_ready`)
