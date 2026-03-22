# Phase 01 — Top Bar, Grammar Correction, Input Widgets

## Context Links
- Design: Pencil screens 08A, 08B, 08C
- Current files: `lib/features/chat/widgets/chat_top_bar.dart`, `grammar_correction_section.dart`, `chat_text_input_field.dart`, `chat_action_button.dart`

## Overview
- **Priority**: High (top bar is visually dominant)
- **Status**: Complete
- Redesign ChatTopBar from onboarding-style (logo+progress+skip) to conversation-style (back arrow + title). Redesign grammar correction from green-checkmark-inside-bubble to red-bordered standalone card. Minor input field adjustments.

## Key Insights
- ChatTopBar currently serves onboarding flow. The new design is for general chat (post-onboarding). Need to make it flexible or create variant.
- Controller needs `chatTitle` property passed via route arguments.
- Grammar correction card is now a standalone widget (not embedded in user bubble).

## Requirements

### Functional
- Top bar: back arrow left, centered title, optional more icon right (08E only)
- Title supports emoji (e.g., "Coffee Chat (coffee emoji)")
- 1px divider below top bar (#9CB0CF = `infoColor`)
- Grammar correction: white bg, red border (1px `errorColor`), sparkles icon, "Try this instead:" header
- Input text field: placeholder in `infoColor`, text in `textPrimaryColor`

### Non-Functional
- Each file under 200 lines
- Use existing AppColors/AppSizes constants

## Related Code Files

### Files to Modify
1. `lib/features/chat/widgets/chat_top_bar.dart` — full rewrite
2. `lib/features/chat/widgets/grammar_correction_section.dart` — full redesign
3. `lib/features/chat/widgets/chat_text_input_field.dart` — font size tweak
4. `lib/features/chat/widgets/chat_action_button.dart` — size to 44x44 (already `buttonHeightMedium`)
5. `lib/features/chat/controllers/ai_chat_controller.dart` — add `chatTitle` and `contextDescription` properties

### Files to Create
- None

### Files to Delete
- None (ai_avatar.dart may become unused but keep for now)

## Implementation Steps

### Step 1: Update ChatTopBar (`chat_top_bar.dart`)

Replace entire widget. New design:

```
Container(height: 56, white bg, padding horizontal 16)
  Row:
    - GestureDetector(onTap: Get.back) → Icon(arrow_back, #545F71 neutralColor, 24px)
    - Expanded → Center → AppText(title, fontSize 20, w600, textPrimaryColor)
    - Optional: Icon(more_vert) for 08E context (pass `showMoreButton` + `onMore` callback)
  Bottom: Divider(1px, infoColor)
```

Constructor params:
```dart
ChatTopBar({
  required String title,
  VoidCallback? onBack,
  bool showMoreButton = false,
  VoidCallback? onMore,
})
```

Remove: `progress`, `flagEmoji`, `onSkip` params.
Remove: Logo image, "Flowering" text, flag, skip button, progress bar.

### Step 2: Update GrammarCorrectionSection (`grammar_correction_section.dart`)

Change from embedded-in-bubble to standalone card. New design:

```
Container(
  width: 240,
  padding: 8,
  decoration: BoxDecoration(
    color: surfaceColor (white),
    border: Border.all(color: errorColor, width: 1),
    borderRadius: radiusM (12) → actually design says 8, use radiusS? No — use buttonRadiusSmall (8)
  ),
  child: Row(
    crossAxisAlignment: start,
    children: [
      Icon(auto_awesome / sparkles, size: 16, color: errorColor),
      SizedBox(width: 8),
      Expanded(Column(
        "Try this instead:" — AppText(fontSize 12, w600, errorColor),
        SizedBox(height: 4),
        correctedText — AppText(fontSize 14, textPrimaryColor),
      )),
    ],
  ),
)
```

Remove: toggle show/hide, green checkmark, divider.
Remove: `isExpanded` and `onToggle` params. Correction is always visible when present.

### Step 3: Update ChatTextInputField (`chat_text_input_field.dart`)

- Placeholder color: `infoColor` (#9CB0CF) instead of current `textTertiaryColor`
- Input text size: 16px (`fontSizeMedium`) — design says Inter 16px
- Hint text size: 16px (`fontSizeMedium`)
- Background: `surfaceMutedColor` (beige) — already correct
- Height 44 (`buttonHeightMedium`) — already correct

### Step 4: Update AiChatController

Add properties:
```dart
final chatTitle = ''.obs;
final contextDescription = ''.obs;
```

In `onInit`, read from route arguments:
```dart
chatTitle.value = Get.arguments?['chatTitle'] ?? 'Chat';
contextDescription.value = Get.arguments?['contextDescription'] ?? '';
```

### Step 5: Add Translation Keys

Add to both language files:
```dart
'chat_try_instead': 'Try this instead:',
'chat_context_label': 'Context',
'chat_save_to_words': 'Save to My Words',
```

## Todo List

- [x] Rewrite `chat_top_bar.dart` — back arrow + centered title + optional more icon
- [x] Redesign `grammar_correction_section.dart` — red border card with sparkles
- [x] Update `chat_text_input_field.dart` — placeholder color and font sizes
- [x] Add `chatTitle` and `contextDescription` to controller
- [x] Add translation keys to both en-US and vi-VN files
- [x] Update `ai_chat_screen.dart` ChatTopBar call (pass title instead of progress)
- [x] Run `flutter analyze` to verify no errors

## Success Criteria

- Top bar shows back arrow + centered title with no progress bar
- Grammar correction renders as standalone red-bordered card
- Input field matches design placeholder style
- All files compile without errors

## Risk Assessment

- **Breaking onboarding flow**: ChatTopBar currently used in onboarding. The controller already has `skipOnboarding` method. Need to either: (a) pass `chatTitle` from onboarding route args, or (b) make title default to 'Chat' when no args provided. Option (b) is safer.
- **GrammarCorrectionSection API change**: UserMessageBubble currently passes `isExpanded`/`onToggle`. Need to update UserMessageBubble simultaneously to avoid compile errors.

## Next Steps
- After this phase, proceed to Phase 02 for message bubble redesign
