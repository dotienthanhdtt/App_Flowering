# Code Review: Chat Grammar Correction Feature

**Date:** 2026-03-10
**Reviewer:** code-reviewer
**Spec:** `plans/reports/brainstorm-260310-1936-chat-grammar-correction.md`

---

## Scope

- Files: 7 (model, endpoint, controller, 2 widgets, screen, 2 l10n files)
- LOC changed: ~80 net additions
- Focus: grammar correction feature for user chat messages

## Overall Assessment

Clean, well-structured implementation that follows the brainstorm spec closely. The parallel fire-and-forget pattern is correct, UI matches the design spec, and all project conventions (AppText, AppColors, AppSizes, .tr translations) are properly applied. A few edge cases and one file-size violation need attention.

---

## Critical Issues

None found. No security vulnerabilities, no data exposure, no breaking changes.

---

## High Priority

### 1. Controller exceeds 200-line limit (332 lines)

**File:** `lib/features/chat/controllers/ai_chat_controller.dart`
**Impact:** Violates project rule. File was likely already near the limit before this feature.
**Recommendation:** Extract voice recording methods (`startRecording`, `stopRecording`, `cancelRecording`) into a mixin or separate controller. The grammar-related methods (`_checkGrammar`, `_getLastAiMessageText`, `toggleCorrection`) could also be a mixin if the file continues growing.

### 2. Duplicate message text causes wrong correction attachment

**File:** `ai_chat_controller.dart`, line 249-251
```dart
final idx = messages.lastIndexWhere(
  (m) => m.type == ChatMessageType.userText && m.text == userText,
);
```
**Issue:** If a user sends the exact same text twice (common in language learning -- repeating a phrase), `lastIndexWhere` by text match could attach the correction to the wrong message. The `_addUserMessage` method uses `DateTime.now().millisecondsSinceEpoch` as ID, and the correction is fired before the message is added to the list, so this is mitigated by timing -- but it is fragile.
**Recommendation:** Capture the message ID at creation time and pass it to `_checkGrammar` instead of matching by text:
```dart
final msgId = 'user_${DateTime.now().millisecondsSinceEpoch}';
_addUserMessage(trimmed, id: msgId);
_checkGrammar(trimmed, lastAiMessage, msgId);
```
Then in `_checkGrammar`, find by ID: `messages.lastIndexWhere((m) => m.id == msgId)`.

### 3. NEW file created: `grammar_correction_section.dart`

**File:** `lib/features/chat/widgets/grammar_correction_section.dart`
**Issue:** The brainstorm spec explicitly states "No New Files Created -- All changes go into existing files per project rules." However, the CLAUDE.md also says "Extract every widget (even small/private ones) into its own file." These two rules conflict. Given the widget is 70 lines and self-contained, a separate file is the correct architectural choice per CLAUDE.md's "One Class Per File" rule.
**Recommendation:** This is acceptable. The brainstorm spec was overly restrictive; the code standard takes precedence.

---

## Medium Priority

### 4. No `const` on Icon widget in grammar_correction_section.dart

**File:** `grammar_correction_section.dart`, line 36
```dart
Icon(
  Icons.check_circle,
  size: AppSizes.iconXXS,
  color: AppColors.accentGreenDark,
),
```
**Recommendation:** All parameters are compile-time constants. Prefix with `const` for performance.

### 5. Grammar check skipped when no previous AI message

**File:** `ai_chat_controller.dart`, line 235
```dart
if (previousAiMessage == null) return;
```
**Impact:** On the very first user message (before AI has responded), grammar check silently skips. This is acceptable behavior per the spec, but worth documenting. The first user message is typically a quick-reply selection so this is low risk.

### 6. `catch (_)` silently swallows all exceptions

**File:** `ai_chat_controller.dart`, line 259
**Impact:** Per the spec, grammar check is non-critical, so silent failure is intentional. However, logging the error in debug mode would aid development.
**Recommendation:**
```dart
} catch (e) {
  debugPrint('Grammar check failed: $e');
}
```

---

## Low Priority

### 7. Translation key 'show' is generic

The key `'show'` could collide with other features that need a "Show" label with different context. Consider `'show_correction'` / `'hide_correction'` for specificity. Current usage is fine but may cause confusion as the app grows.

---

## Positive Observations

- Correctly uses `AppText` throughout, never raw `Text`
- All colors reference `AppColors` constants matching the design spec exactly
- All sizes reference `AppSizes` constants
- Translations added to both EN and VI files with `.tr` usage
- Fire-and-forget pattern is clean -- does not block chat flow
- `messages.refresh()` correctly triggers Obx rebuild
- Widget decomposition is clean: `UserMessageBubble` delegates to `GrammarCorrectionSection`
- The `onToggleCorrection` callback pattern properly keeps state in the controller (not the widget)
- Error handling in `_checkGrammar` is appropriately lenient for a non-critical feature

---

## Recommended Actions (Priority Order)

1. **[High]** Fix message matching to use ID instead of text content
2. **[High]** Split `ai_chat_controller.dart` to get under 200 lines (extract voice recording)
3. **[Medium]** Add `const` to the Icon widget
4. **[Medium]** Add `debugPrint` to the catch block
5. **[Low]** Consider renaming `show`/`hide` keys to `show_correction`/`hide_correction`

---

## Metrics

- File size compliance: 6/7 files under 200 lines (controller at 332 -- pre-existing issue worsened)
- Type safety: Good -- nullable `correctedText` correctly handled with null checks
- Translation coverage: 3/3 new keys in both language files
- Linting issues: 1 (missing `const` on Icon)
- Test coverage: Not assessed (no tests included in this diff)

---

## Unresolved Questions

1. Should grammar correction persist across app restarts (Hive cache), or is ephemeral (memory-only) acceptable? Current implementation is ephemeral.
2. The `targetLanguage` sent to the correction API -- is this the language being learned or the user's native language? Verify the backend contract expects the learning language here.
