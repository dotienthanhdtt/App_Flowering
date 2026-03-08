# Phase 03 — Bubble Integration + Controller Wiring

## Context Links
- Bubble widget: `lib/features/chat/widgets/ai_message_bubble.dart`
- Controller: `lib/features/chat/controllers/ai_chat_controller.dart`
- `AppTappablePhrase`: `lib/shared/widgets/app_tappable_phrase.dart`
- Chat view: `lib/features/chat/views/ai_chat_screen.dart`

## Overview
- **Priority:** High
- **Status:** Pending
- **Description:** Replace plain `Text()` in AI bubble with `AppTappablePhrase`, wire word tap to show bottom sheet via controller, wire sentence translate to call API on first tap.

## Key Insights
- `AiMessageBubble` currently uses plain `Text()` for message content (line 62-68)
- Need to add `onWordTap` callback to bubble constructor
- Controller needs `translateWord()` and updated `toggleTranslation()` methods
- Sentence translate: first tap calls API + sets `translatedText` + `showTranslation=true`; subsequent taps toggle visibility only
- Onboarding IDs start with `ai_` — use this to detect non-backend messages and disable sentence translate

## Requirements

### Functional
- Tapping a word in AI bubble opens `WordTranslationSheet` with loading state, then populates
- Sentence "Translate" button calls API on first tap (when `translatedText` is null), toggles on subsequent
- Loading indicator on translate button while API call in progress
- Error handling: snackbar on translate failure

### Non-Functional
- No unnecessary rebuilds — word tap doesn't rebuild message list
- Smooth UX: bottom sheet appears immediately in loading state

## Architecture

```
User taps word → AiMessageBubble.onWordTap → AiChatController.onWordTap(word)
  → Show WordTranslationSheet(loading) → TranslationService.translateWord(word)
  → Update sheet with result or error

User taps "Translate" → AiChatController.toggleTranslation(messageId)
  → If translatedText == null: TranslationService.translateSentence(backendMessageId)
    → Set translatedText + showTranslation = true
  → Else: toggle showTranslation
```

## Related Code Files

### Edit
| File | Change |
|------|--------|
| `lib/features/chat/widgets/ai_message_bubble.dart` | Replace `Text()` with `AppTappablePhrase`, add `onWordTap` callback |
| `lib/features/chat/controllers/ai_chat_controller.dart` | Add `onWordTap()`, update `toggleTranslation()` to call API |
| `lib/features/chat/views/ai_chat_screen.dart` | Pass `onWordTap` when constructing bubble |

## Implementation Steps

### 1. Update AiMessageBubble

Add callback to constructor:
```dart
final void Function(String word)? onWordTap;
```

Replace the plain `Text()` widget (lines 62-68) with:
```dart
AppTappablePhrase(
  message.text ?? '',
  variant: AppTextVariant.bodyMedium,
  color: AppColors.textPrimary,
  onWordTap: onWordTap != null ? (word, _) => onWordTap!(word) : null,
)
```

Note: `AppTappablePhrase` uses `RichText` internally, so the text style params need to match. Pass the correct `variant` or override via `wordStyleBuilder`. The existing text style is:
```dart
fontSize: AppSizes.fontM, color: AppColors.textPrimary, height: AppSizes.lineHeightLoose
```
Verify `AppTextVariant.bodyMedium` maps to equivalent style. If not, use `wordStyleBuilder` to apply custom style.

### 2. Update AiChatController

Add `TranslationService` dependency:
```dart
final TranslationService _translationService = Get.find();
```

Add word tap handler:
```dart
void onWordTap(String word, BuildContext context) {
  // Strip punctuation from word
  final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '').trim();
  if (cleanWord.isEmpty) return;

  // Show bottom sheet immediately in loading state
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WordTranslationSheetLoader(word: cleanWord),
  );
}
```

Create a small StatefulWidget `_WordTranslationSheetLoader` (or use `FutureBuilder` pattern) that:
1. Starts loading on init
2. Calls `_translationService.translateWord(cleanWord)`
3. Renders `WordTranslationSheet` with loading/data/error state

Alternative (simpler): Use `StatefulBuilder` inside the bottom sheet:
```dart
showModalBottomSheet(
  ...
  builder: (_) => StatefulBuilder(
    builder: (context, setState) {
      // Use local state for loading/data/error
    },
  ),
);
```

Update `toggleTranslation`:
```dart
Future<void> toggleTranslation(String messageId) async {
  final index = messages.indexWhere((m) => m.id == messageId);
  if (index == -1) return;
  final msg = messages[index];

  // Already has translation — just toggle
  if (msg.translatedText != null) {
    msg.showTranslation = !msg.showTranslation;
    messages.refresh();
    return;
  }

  // No backend ID — cannot translate
  if (msg.backendMessageId == null) {
    Get.snackbar('', 'word_translation_error'.tr);
    return;
  }

  // First tap — call API
  try {
    final result = await _translationService.translateSentence(msg.backendMessageId!);
    msg.translatedText = result.translation;  // Need to make translatedText mutable
    msg.showTranslation = true;
    messages.refresh();
  } on ApiException catch (e) {
    Get.snackbar('', e.userMessage);
  }
}
```

Note: `ChatMessage.translatedText` is currently `final`. Change to non-final (mutable) or create a copy method. Simplest: make it non-final like `showTranslation` already is.

### 3. Update ChatMessage model
Make `translatedText` mutable:
```dart
String? translatedText;  // Remove 'final'
```

### 4. Update chat view
Where `AiMessageBubble` is constructed, pass the word tap callback:
```dart
AiMessageBubble(
  message: message,
  onTranslate: () => controller.toggleTranslation(message.id),
  onPlayAudio: () => controller.playAudio(message.id),
  onWordTap: (word) => controller.onWordTap(word, context),
)
```

### 5. Handle the bottom sheet loading pattern
Create a small helper widget or use inline `StatefulBuilder`. Recommended approach — create a private widget in a separate file under `lib/features/chat/widgets/`:

File: `lib/features/chat/widgets/word-translation-sheet-loader.dart`
```dart
class WordTranslationSheetLoader extends StatefulWidget {
  final String word;
  const WordTranslationSheetLoader({required this.word});
}

class _State extends State<WordTranslationSheetLoader> {
  WordTranslationModel? data;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await Get.find<TranslationService>().translateWord(widget.word);
      if (mounted) setState(() => data = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return WordTranslationSheet(
      word: widget.word,
      data: data,
      error: error,
      onRetry: () { setState(() { error = null; data = null; }); _load(); },
      onClose: () => Navigator.pop(context),
    );
  }
}
```

## Todo List
- [ ] Make `ChatMessage.translatedText` mutable (remove `final`)
- [ ] Add `onWordTap` callback to `AiMessageBubble` constructor
- [ ] Replace `Text()` with `AppTappablePhrase` in bubble
- [ ] Create `WordTranslationSheetLoader` stateful wrapper
- [ ] Add `onWordTap()` method to `AiChatController`
- [ ] Update `toggleTranslation()` to call API on first tap
- [ ] Pass `onWordTap` in chat view where bubble is constructed
- [ ] Add `TranslationService` import to controller
- [ ] Verify compilation with `flutter analyze`
- [ ] Manual test: tap word → sheet appears with loading → data populates
- [ ] Manual test: tap Translate → API call → translation shows → tap again → hides

## Success Criteria
- Tapping any word in AI bubble opens bottom sheet with correct translation
- Translate button calls API on first tap, toggles on subsequent taps
- Loading states shown during API calls
- Errors displayed gracefully (snackbar for sentence, retry in sheet for word)
- No regression in existing chat functionality
- `flutter analyze` passes

## Risk Assessment
| Risk | Mitigation |
|------|------------|
| `AppTappablePhrase` text style mismatch | Compare `AppTextVariant.bodyMedium` with existing inline style; use `wordStyleBuilder` if needed |
| Bottom sheet not scrollable on small screens | Wrap in `SingleChildScrollView` |
| `toggleTranslation` now async — callers need update | `onTranslate` callback in bubble is `VoidCallback?` — wrap async call in sync closure |
| Punctuation in tapped word | Strip via regex before API call |

## Security Considerations
- Translation API requires auth (JWT auto-injected by `AuthInterceptor`)
- No user data exposed in cache (word translations are non-sensitive)

## Next Steps
- Test end-to-end flow manually
- Future: TTS audio playback for word pronunciation
- Future: vocabulary review screen using saved `vocabularyId`
