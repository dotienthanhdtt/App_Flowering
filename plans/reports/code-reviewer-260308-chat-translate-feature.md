# Code Review: Chat Translate Feature

**Date:** 2026-03-08
**Reviewer:** code-reviewer
**Plan:** plans/260308-1823-chat-translate-feature/plan.md

## Scope

- **New files (5):** word-translation-model.dart, sentence-translation-model.dart, translation-service.dart, word-translation-sheet.dart, word-translation-sheet-loader.dart
- **Modified files (8):** api_endpoints.dart, chat_message_model.dart, global-dependency-injection-bindings.dart, english/vietnamese translations, ai_message_bubble.dart, ai_chat_controller.dart, ai_chat_screen.dart
- **Total LOC changed:** ~450 new, ~80 modified
- **Focus:** Pattern consistency, error handling, memory, security, edge cases

## Overall Assessment

Good implementation. Clean separation between models, service, and UI. Caching strategy is sound. The feature integrates well with existing patterns (ApiClient, GetX DI, i18n). A few issues need attention, ranging from a potential memory leak to file size violations and a missing `backendMessageId` assignment.

---

## Critical Issues

### 1. `backendMessageId` is never populated -- sentence translate will always fail for real messages

**File:** `lib/features/chat/controllers/ai_chat_controller.dart` lines 224-230

The `_addAiMessage` method creates `ChatMessage` instances without setting `backendMessageId`. The `toggleTranslation` method checks `msg.backendMessageId == null` (line 139) and shows an error snackbar if null. This means sentence translation will never work, even for messages that come from the backend.

The backend response (`OnboardingSession`) likely returns a message ID, but it is not being threaded through to `ChatMessage.backendMessageId`.

**Impact:** Sentence translate button is non-functional for all messages.

**Fix:** Extract the backend message ID from the API response and pass it to `_addAiMessage`:
```dart
void _addAiMessage(String text, {String? backendMessageId}) {
  messages.add(ChatMessage(
    id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
    type: ChatMessageType.aiText,
    text: text,
    timestamp: DateTime.now(),
    backendMessageId: backendMessageId,
  ));
  _scrollToBottom();
}
```

---

## High Priority

### 2. TapGestureRecognizer leak in AppTappablePhrase

**File:** `lib/shared/widgets/app_tappable_phrase.dart` line 63-64

`TapGestureRecognizer` instances are created inside the `build()` method but never disposed. Each rebuild allocates new recognizers without cleaning up old ones. Since `AppTappablePhrase` is a `StatelessWidget`, there is no `dispose` lifecycle to hook into.

**Impact:** Memory leak proportional to (number of words) x (number of rebuilds). In a scrolling chat list, this compounds.

**Fix:** Convert `AppTappablePhrase` to a `StatefulWidget` that manages recognizer lifecycle, or use a recognizer pool that disposes on rebuild. Example:
```dart
class _AppTappablePhraseState extends State<AppTappablePhrase> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) { r.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) { r.dispose(); }
    _recognizers.clear();
    // ... create new recognizers, add to _recognizers list
  }
}
```

### 3. File size violations (200-line rule)

| File | Lines | Limit |
|------|-------|-------|
| word-translation-sheet.dart | 328 | 200 |
| ai_message_bubble.dart | 341 | 200 |
| ai_chat_controller.dart | 273 | 200 |

Per project rules, files must stay under 200 lines.

**Fix suggestions:**
- `word-translation-sheet.dart`: Extract `_CircleButton`, `_buildExamples`, `_buildDefinition` into a separate file like `word-translation-sheet-sections.dart`
- `ai_message_bubble.dart`: Already had `QuickReplyRow`, `AiTypingBubble`, `_TextActionButton` -- these should be separate widget files
- `ai_chat_controller.dart`: Extract voice recording methods and message-building helpers into mixins or separate files

### 4. AiChatController does not extend BaseController

**File:** `lib/features/chat/controllers/ai_chat_controller.dart` line 19

Other controllers in the project (`profile-controller.dart`, `vocabulary-controller.dart`, `read-controller.dart`, `chat-home-controller.dart`) extend `BaseController` for standardized loading/error handling via `apiCall()`. `AiChatController` extends `GetxController` directly and reimplements loading/error patterns manually.

**Impact:** Inconsistent error handling, duplicated try/catch boilerplate, missing standardized snackbar behavior.

**Fix:** Refactor to extend `BaseController` and use `apiCall()` wrapper for API calls.

---

## Medium Priority

### 5. Unused import in ai_chat_controller.dart

**File:** `lib/features/chat/controllers/ai_chat_controller.dart` line 6

```dart
import '../../../core/constants/app_colors.dart';
```

This import is unused (confirmed by `flutter analyze`).

### 6. Cache grows unbounded

**File:** `lib/core/services/translation-service.dart` lines 13-14

The in-memory caches `_wordCache` and `_sentenceCache` have no size limit. In a long session with heavy translation use, memory consumption grows without bound.

**Impact:** Low risk for typical usage, but worth noting. The plan explicitly scopes this as "in-memory per session" and defers persistence, which is reasonable. But adding a max-size eviction (e.g., LRU with 500 entries) would be more defensive.

### 7. Hardcoded language strings

**Files:** `translation-service.dart` (defaults `sourceLang='en'`, `targetLang='vi'`), `ai_message_bubble.dart` line 95 (hardcoded `'Vietnamese'`)

The source/target languages are hardcoded rather than derived from the user's language settings. The string "Vietnamese" on line 95 of `ai_message_bubble.dart` should use i18n.

**Fix:** Read from user language preferences (available in `OnboardingController` or `StorageService`), and replace the hardcoded "Vietnamese" with a translation key.

### 8. Word cleaning regex is too aggressive

**File:** `lib/features/chat/controllers/ai_chat_controller.dart` line 161

```dart
final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '').trim();
```

The `\w` regex class matches `[a-zA-Z0-9_]`. This strips accented characters, apostrophes (e.g., "don't" becomes "dont"), and hyphens (e.g., "well-known" becomes "wellknown"). For an English-learning context, apostrophes and hyphens are linguistically significant.

**Fix:** Use a more targeted regex:
```dart
final cleanWord = word.replaceAll(RegExp(r"[^\w'\-]"), '').trim();
```

---

## Low Priority

### 9. File naming uses kebab-case (info-level lint)

New files use kebab-case (`word-translation-model.dart`) which is the project convention per `development-rules.md`. However, `flutter analyze` flags these as not matching Dart's `lower_case_with_underscores` convention. This is a known tension in the project -- the team has chosen kebab-case deliberately.

No action needed, but be aware CI may flag these.

### 10. `_CircleButton` GestureDetector has no semantics/tooltip

The audio and close buttons in `WordTranslationSheet` lack accessibility labels. Users relying on screen readers would not be able to identify them.

### 11. Snackbar empty title

**File:** `ai_chat_controller.dart` lines 140-141, 154

```dart
Get.snackbar('', 'word_translation_error'.tr, ...);
```

Empty string for snackbar title. While functional, it creates an awkward visual. Consider using `'error'.tr` or removing the snackbar in favor of inline error display.

---

## Edge Cases Found by Scout

1. **Rapid word taps:** If user taps words quickly, multiple bottom sheets could stack. The `showModalBottomSheet` call does not check if one is already visible.
2. **Empty text message:** If `message.text` is null or empty, `AppTappablePhrase` receives an empty string and renders nothing, which is handled correctly.
3. **Concurrent translations:** If `toggleTranslation` is called twice rapidly for the same message before the first API call completes, two API calls fire. The cache prevents duplicate storage, but the user may see a brief flicker. Consider adding a per-message loading state.
4. **Widget disposal during API call:** `WordTranslationSheetLoader` correctly checks `mounted` before `setState`. Good.
5. **ChatMessage mutability:** `translatedText` and `showTranslation` are mutable fields on `ChatMessage`. This works with `messages.refresh()` but is fragile -- any code that holds a reference to the list items can mutate state without triggering reactive updates.

---

## Positive Observations

1. **Clean model separation** -- `WordTranslationModel` and `SentenceTranslationModel` are minimal, immutable (except cache), and follow the `fromJson` factory pattern consistently
2. **Caching strategy** is well-designed -- word cache by normalized key, sentence cache by messageId, with cache-first reads
3. **StatefulWidget loader pattern** (`WordTranslationSheetLoader`) cleanly separates data fetching from presentation, with proper `mounted` checks
4. **i18n coverage** is complete -- all user-facing strings have both EN and VI translations
5. **Error handling** in `TranslationService` properly throws typed `ApiErrorException` matching the project's exception hierarchy
6. **DI registration** in `global-dependency-injection-bindings.dart` correctly places `TranslationService` after `ApiClient` initialization with `permanent: true`

---

## Recommended Actions (Priority Order)

1. **[CRITICAL]** Wire `backendMessageId` from API response into `_addAiMessage` so sentence translate actually works
2. **[HIGH]** Fix `TapGestureRecognizer` leak in `AppTappablePhrase` -- convert to StatefulWidget
3. **[HIGH]** Split oversized files to meet 200-line rule
4. **[HIGH]** Extend `BaseController` for consistent error handling
5. **[MEDIUM]** Remove unused import (`app_colors.dart` in controller)
6. **[MEDIUM]** Fix word cleaning regex to preserve apostrophes/hyphens
7. **[MEDIUM]** Replace hardcoded "Vietnamese" with i18n key; derive language params from user settings
8. **[LOW]** Add debounce or guard against multiple bottom sheet opens on rapid word taps
9. **[LOW]** Add accessibility labels to circle buttons

## Metrics

- **Type Coverage:** N/A (Dart with sound null safety -- all types are explicit)
- **Test Coverage:** No new tests included in this change
- **Linting Issues:** 1 warning (unused import), 6 info (file naming convention)
- **Compilation:** Passes `flutter analyze` with no errors

## Unresolved Questions

1. Does `OnboardingSession` actually return a message ID that can be used for sentence translation? If not, the backend API contract may need updating.
2. Should the translation cache persist across sessions (Hive)? Plan explicitly defers this, but worth confirming product intent.
3. Is there a rate limit on `POST /ai/translate`? Rapid word tapping could generate many requests.
