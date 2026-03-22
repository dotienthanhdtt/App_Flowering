# Phase 03 — Bottom Sheet, Context Card, Screen Integration

## Context Links
- Design: Pencil screens 08E (bottom sheet + context card), 08A (screen layout)
- Current files: `word-translation-sheet.dart`, `ai_chat_screen.dart`, `ai_chat_controller.dart`

## Overview
- **Priority**: Medium
- **Status**: Complete
- Update WordTranslationSheet to match 08E (add save button, layout refinements). Create ChatContextCard widget for scenario description. Integrate all Phase 01/02 changes into AiChatScreen. Wire grammar correction as standalone message item.

## Key Insights
- WordTranslationSheet is a shared widget in `lib/shared/widgets/` — changes affect any screen using it
- Grammar correction currently renders inside UserMessageBubble. New design renders it as separate item below user message, right-aligned
- Context card appears at top of chat area (08E), only when scenario context exists
- Bottom sheet needs "Save to My Words" button at bottom

## Requirements

### Functional
- WordTranslationSheet: 380px height, handle pill 36x4, word row with phonetic + audio + close, POS chip, translation section, example in beige card, save button (outlined, 52px height, bookmark icon)
- ChatContextCard: orange/warning bg, cornerRadius 12, padding 16, message-circle icon + scenario text
- AiChatScreen: pass title to TopBar, render correction cards separately, show context card
- Dim overlay when bottom sheet shown (#00000066) — default Flutter behavior

### Non-Functional
- Files under 200 lines
- Save button calls `onSave` callback (actual save logic deferred to controller)

## Related Code Files

### Files to Modify
1. `lib/shared/widgets/word-translation-sheet.dart` — add save button, update handle size, layout tweaks
2. `lib/features/chat/views/ai_chat_screen.dart` — integrate new TopBar params, correction rendering, context card
3. `lib/features/chat/controllers/ai_chat_controller.dart` — add `saveWord()` method stub

### Files to Create
1. `lib/features/chat/widgets/chat-context-card.dart` — scenario context card

### Files to Delete
- None

## Implementation Steps

### Step 1: Update WordTranslationSheet (`word-translation-sheet.dart`)

Current file is 305 lines — already over 200-line limit. After changes, extract `_CircleButton` to shared widget if needed, or keep as private since it's small.

Changes:

1. **Handle pill**: width 40→36, already 4px height — just update width
2. **Header row**: Add phonetic text between word and audio button
   ```dart
   Row(children: [
     Column(children: [
       AppText(word, fontSize: 28, w700, textPrimaryColor),
       if (data?.pronunciation != null)
         AppText(pronunciation, fontSize: 16, neutralColor),
     ]),
     Spacer(),
     _CircleButton(audio, 44px, warningLightColor bg, primaryColor icon),
     Positioned close button (28px circle, surfaceMutedColor, X icon),
   ])
   ```

3. **POS chip**: color change to `secondaryColor` text on `secondaryLightColor` bg — already matches current implementation

4. **Translation section**: Update label style
   - Remove globe icon, just label "Translation" (Inter 14px, 600, neutralColor) + value (Inter 20px, 600, textPrimaryColor)

5. **Example section**: Keep beige card — already correct

6. **Add save button at bottom**:
   ```dart
   SizedBox(height: space4),
   GestureDetector(
     onTap: onSave,
     child: Container(
       height: 52, // buttonHeightLarge
       decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(radiusM), // 12
         border: Border.all(color: primaryColor, width: 1.5),
       ),
       child: Row(mainAxisAlignment: center, children: [
         Icon(bookmark_border, color: primaryColor, size: 20),
         SizedBox(width: 8),
         AppText('chat_save_to_words'.tr, fontSize: 18, w600, primaryColor),
       ]),
     ),
   ),
   ```

7. Add `onSave` callback parameter

### Step 2: Create ChatContextCard (`chat-context-card.dart`)

New widget for scenario context shown at top of chat (08E):

```dart
class ChatContextCard extends StatelessWidget {
  final String description;
  const ChatContextCard({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space4), // 16
      decoration: BoxDecoration(
        color: AppColors.warningLightColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusM), // 12
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.primaryColor),
          SizedBox(width: AppSizes.space2), // 8
          Expanded(
            child: AppText(
              description,
              fontSize: AppSizes.fontSizeMedium, // 16
              color: AppColors.textPrimaryColor,
              height: AppSizes.lineHeightMedium,
            ),
          ),
        ],
      ),
    );
  }
}
```

~30 lines. Simple.

### Step 3: Update AiChatScreen (`ai_chat_screen.dart`)

Changes to `buildContent`:

1. Replace `ChatTopBar` instantiation:
   ```dart
   // Before:
   ChatTopBar(progress: controller.progress.value, onSkip: controller.skipOnboarding)

   // After:
   Obx(() => ChatTopBar(title: controller.chatTitle.value))
   ```

2. Add context card above chat list (when contextDescription is not empty):
   ```dart
   Obx(() {
     if (controller.contextDescription.value.isNotEmpty) {
       return Padding(
         padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
         child: ChatContextCard(description: controller.contextDescription.value),
       );
     }
     return SizedBox.shrink();
   }),
   ```

3. Update `_buildMessageItem` to render grammar correction as separate item:

   Current approach: correction is inside `UserMessageBubble`. New approach: `UserMessageBubble` just renders text. Correction renders as next item.

   **Option A** (simpler): Keep correction inside the user bubble builder but render it below the bubble as a separate widget in the same builder return.

   ```dart
   case ChatMessageType.userText:
     return Column(
       crossAxisAlignment: CrossAxisAlignment.end,
       children: [
         UserMessageBubble(message: message),
         if (message.correctedText != null) ...[
           SizedBox(height: 8),
           Align(
             alignment: Alignment.centerRight,
             child: GrammarCorrectionSection(correctedText: message.correctedText!),
           ),
         ],
       ],
     );
   ```

   This avoids model changes and keeps correction visually tied to its message.

4. Update chat list padding to match design: `EdgeInsets.fromLTRB(16, 10, 16, 8)` and separator gap to 8px.

### Step 4: Update Controller — saveWord method

Add stub in `ai_chat_controller.dart`:
```dart
void saveWord(String word) {
  // TODO: Implement save word to vocabulary list via API
}
```

Pass to `WordTranslationSheetLoader` → `WordTranslationSheet`:
```dart
builder: (_) => WordTranslationSheetLoader(
  word: cleanWord,
  sessionToken: _sessionToken,
  onSave: () => saveWord(cleanWord),
),
```

Update `WordTranslationSheetLoader` to accept and forward `onSave`.

### Step 5: Add Remaining Translation Keys

Both `english-translations-en-us.dart` and `vietnamese-translations-vi-vn.dart`:

```dart
// English
'chat_try_instead': 'Try this instead:',
'chat_save_to_words': 'Save to My Words',

// Vietnamese
'chat_try_instead': 'Thu lai cau nay:',
'chat_save_to_words': 'Luu vao tu vung',
```

## Todo List

- [x] Update `word-translation-sheet.dart` — save button, handle size, layout tweaks
- [x] Update `word-translation-sheet-loader.dart` — forward `onSave` callback
- [x] Create `chat-context-card.dart` — scenario context card widget
- [x] Update `ai_chat_screen.dart` — new TopBar params, context card, correction rendering
- [x] Add `saveWord()` stub to controller
- [x] Add `onSave` to `onWordTap` flow in controller
- [x] Add translation keys to both language files
- [x] Run `flutter analyze` to verify no errors
- [x] Manual visual QA against Pencil screenshots

## Success Criteria

- Bottom sheet shows save button matching 08E design
- Context card renders at top of chat when scenario description exists
- Grammar correction renders as standalone card below user message
- Chat list spacing matches design (10px top, 8px gaps)
- All files compile, `flutter analyze` clean

## Risk Assessment

- **WordTranslationSheet is shared**: Other screens may use it. Adding `onSave` as optional callback (nullable) is backward-compatible. No risk.
- **File size of word-translation-sheet.dart**: Currently 305 lines, already over limit. Adding save button increases it. May need to extract sections. Mitigation: extract `_buildContent` subsections to helper methods or split into parts file.

## Security Considerations
- `saveWord` will eventually call API — ensure sessionToken is passed
- No user data exposure in context card (scenario text comes from backend)

## Next Steps
- After all 3 phases: run `flutter analyze`, visual QA, commit
- Docs impact: minor — update `codebase-summary.md` to note chat UI redesign
