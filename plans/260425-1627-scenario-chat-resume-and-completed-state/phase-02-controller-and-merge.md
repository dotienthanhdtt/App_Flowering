# Phase 02 — Controller Refactor: Server-Authoritative Merge + Grammar Fallback

## Context Links
- Brainstorm: [`../reports/brainstorm-260425-1627-scenario-chat-resume-and-completed-state.md`](../reports/brainstorm-260425-1627-scenario-chat-resume-and-completed-state.md)
- Plan overview: [`plan.md`](plan.md)
- Depends on: [phase-01](phase-01-models-and-service.md) (new DTOs)

## Overview
- **Priority:** P1
- **Status:** done
- **Effort:** 2h
- Move from append-on-each-turn to server-authoritative merge. Add `_isFirstLoad` flag. Make grammar correction lookup resilient to ID rewrites.

## Key Insights
- Server replaces the entire message list every call. Local state (translation cache, grammar correction) is per-message and must survive replacement.
- Just-sent user message has temp ID `user_<ts>`; after server merge it has UUID — grammar callback must look up by content/role, not stored temp ID.
- TTS auto-play in `_addAiMessage` was fine for single-message append but would burst-play history on resume — gate with `_isFirstLoad`.
- Empty `content` messages must be skipped at merge time (no bubble).
- `kickoffFailed` semantics unchanged for now (open question deferred).

## Requirements

### Functional
- `sendKickoff()` and `sendText()` route through one helper `_applyServerState(ScenarioChatResponse)`.
- `_applyServerState`:
  - Updates `conversationId`, `turn`, `maxTurns`, `completed`.
  - Calls `_mergeWithServer(...)` to rebuild `messages` while preserving `translatedText`, `translationVisible`, `correctedText`.
  - Skips messages with `content.trim().isEmpty`.
  - Calls `_maybeAutoplayLatestAi()` only when `!_isFirstLoad`.
  - Sets `_isFirstLoad = false` after first call.
  - Scrolls to bottom.
- Grammar correction (`_checkGrammar`) updates the correct user message after server merge.

### Non-functional
- No new external deps.
- Maintain existing typing placeholder UX during in-flight requests.
- Preserve existing `_handleChatError` behavior.

## Architecture

```
sendKickoff() / sendText()
    ├── add typing placeholder (in-flight visual)
    ├── service.chat() → ScenarioChatResponse
    └── on success → _applyServerState(resp)
            ├── update scenario reactive vars
            ├── messages.value = _mergeWithServer(local, server)
            ├── _scrollToBottom()
            └── if !_isFirstLoad → _maybeAutoplayLatestAi()
```

`_mergeWithServer(local, server)`:
1. Build `Map<String, _LocalUiState> byId` from local messages.
2. For each server message:
   - Skip if `content.trim().isEmpty`.
   - Map role → `ChatMessageType.aiText` / `userText`.
   - Construct `ChatMessage(id: srv.id, type, text: content, timestamp: createdAt)`.
   - Restore UI state: try `byId[srv.id]`; else for user role, find latest local user message with `text == srv.content` not yet matched.
3. Return new immutable list.

## Related Code Files

### Modified
- `lib/features/scenario-chat/controllers/scenario_chat_controller.dart`
- `lib/features/scenario-chat/controllers/scenario_chat_controller_messaging.dart`
- `lib/features/scenario-chat/controllers/scenario_chat_controller_grammar.dart`

### Created
- (none — keep as part files of the same controller, per existing pattern)

### Deleted
- (none in this phase)

## Implementation Steps

### Step 1 — controller core
In `scenario_chat_controller.dart`:

- Add field after the reactive state block:

```dart
bool _isFirstLoad = true;
```

- Add helper at the end of the class:

```dart
void _maybeAutoplayLatestAi() {
  for (var i = messages.length - 1; i >= 0; i--) {
    final m = messages[i];
    if (m.type == ChatMessageType.aiText && (m.text ?? '').isNotEmpty) {
      if (_ttsService.autoPlayEnabled) {
        _ttsService.speak(m.text!, language: _targetLanguage);
      }
      return;
    }
  }
}
```

- Add `_mergeWithServer` (private helper). Place near `_addAiMessage`/`_addUserMessage`:

```dart
List<ChatMessage> _mergeWithServer(
  List<ChatMessage> local,
  List<ScenarioMessage> server,
) {
  final byId = <String, ChatMessage>{
    for (final m in local) m.id: m,
  };
  // Track which local user msgs were already matched by id, so the
  // (role,text) fallback only consumes one per server msg.
  final matchedIds = <String>{};
  final result = <ChatMessage>[];

  for (final srv in server) {
    final content = srv.content.trim();
    if (content.isEmpty) continue;

    final type = srv.isAssistant
        ? ChatMessageType.aiText
        : ChatMessageType.userText;

    final cached = byId[srv.id] ??
        (srv.isUser
            ? local.lastWhereOrNull((m) =>
                m.type == ChatMessageType.userText &&
                (m.text?.trim() ?? '') == content &&
                !matchedIds.contains(m.id))
            : null);

    if (cached != null) matchedIds.add(cached.id);

    result.add(ChatMessage(
      id: srv.id,
      type: type,
      text: srv.content,
      timestamp: srv.createdAt,
      translatedText: cached?.translatedText,
      isTranslationVisible: cached?.isTranslationVisible ?? false,
      correctedText: cached?.correctedText,
    ));
  }
  return result;
}
```

> NOTE: `lastWhereOrNull` from `package:collection`. If not imported, add `import 'package:collection/collection.dart';` at top of controller. Verify `ChatMessage` constructor accepts the named fields used (open the model file before coding to confirm — adapt `copyWith`-style approach if constructor differs).

### Step 2 — messaging part
In `scenario_chat_controller_messaging.dart`, add helper and replace inline mutations:

```dart
extension ScenarioChatControllerMessaging on ScenarioChatController {
  void _applyServerState(ScenarioChatResponse r) {
    final s = r.scenario;
    if (s.conversationId.isNotEmpty) conversationId = s.conversationId;
    turn.value = s.turn;
    maxTurns.value = s.maxTurns;
    completed.value = s.status == ScenarioStatus.done;

    messages.value = _mergeWithServer(messages, r.messages);
    _scrollToBottom();

    if (!_isFirstLoad) _maybeAutoplayLatestAi();
    _isFirstLoad = false;
  }

  Future<void> sendKickoff() async {
    kickoffFailed.value = false;
    _addTypingPlaceholder();
    await apiCall(
      () => _service.chat(ScenarioChatTurnRequest(
        scenarioId: scenarioId,
        message: '',
        forceNew: _forceNewPending ? true : null,
      )),
      showLoading: false,
      onSuccess: (resp) {
        _removeTypingPlaceholder();
        if (resp.isSuccess && resp.data != null) {
          _applyServerState(resp.data!);
        }
      },
      onError: (e) {
        _removeTypingPlaceholder();
        _handleChatError(e, isKickoff: true);
      },
    );
  }

  Future<void> retryKickoff() => sendKickoff();

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSending.value || completed.value) return;

    textEditingController.clear();
    final lastAiMessage = _getLastAiMessageText();
    final userMessageId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _addUserMessage(trimmed, messageId: userMessageId);
    isSending.value = true;
    _addTypingPlaceholder();

    _checkGrammar(userMessageId, trimmed, lastAiMessage);

    await apiCall(
      () => _service.chat(ScenarioChatTurnRequest(
        scenarioId: scenarioId,
        message: trimmed,
        conversationId: conversationId,
      )),
      showLoading: false,
      onSuccess: (resp) {
        _removeTypingPlaceholder();
        if (resp.isSuccess && resp.data != null) {
          _applyServerState(resp.data!);
        }
        isSending.value = false;
      },
      onError: (e) {
        _removeTypingPlaceholder();
        isSending.value = false;
        _handleChatError(e);
      },
    );
  }

  void _handleChatError(ApiException e, {bool isKickoff = false}) {
    if (e is ForbiddenException) {
      Get.snackbar(
        'error'.tr,
        'scenario_chat_premium_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
      return;
    }
    if (isKickoff) {
      kickoffFailed.value = true;
    } else {
      Get.snackbar(
        'error'.tr,
        'scenario_chat_error_send'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
```

### Step 3 — grammar resilience
In `scenario_chat_controller_grammar.dart`:

- When the grammar callback resolves, the original `userMessageId` may no longer exist (server merge gave it a UUID). Update the lookup:

```dart
// Old (illustrative):
// final idx = messages.indexWhere((m) => m.id == userMessageId);

// New: try id first, then fallback to (role=user, text=trimmed, latest)
int _findUserMessageIndex(String userMessageId, String trimmed) {
  final byId = messages.indexWhere((m) => m.id == userMessageId);
  if (byId != -1) return byId;
  for (var i = messages.length - 1; i >= 0; i--) {
    final m = messages[i];
    if (m.type == ChatMessageType.userText &&
        (m.text?.trim() ?? '') == trimmed) {
      return i;
    }
  }
  return -1;
}
```

Use this helper inside the existing grammar completion handler. Trigger reactive update via `messages.refresh()` after mutating the message.

> **Open the file before editing** to find exact callback signature; adapt the patch above to match. The contract is: replace any `messages.indexWhere((m) => m.id == userMessageId)` with `_findUserMessageIndex(userMessageId, trimmed)`.

### Step 4 — verify build
```bash
cd /Users/tienthanh/Dev/new_flowering/app_flowering/flowering
flutter analyze lib/features/scenario-chat/
```

Expect zero errors. Phase 3 will touch view + l10n.

## Todo List

- [x] Add `_isFirstLoad` field to controller
- [x] Add `_maybeAutoplayLatestAi()` helper
- [x] Add `_mergeWithServer(...)` helper (with collection import if needed)
- [x] Add `_applyServerState(...)` in messaging extension
- [x] Replace inline state mutation in `sendKickoff` and `sendText`
- [x] Update grammar callback to use `_findUserMessageIndex`
- [x] `flutter analyze` clean for `lib/features/scenario-chat/`
- [x] Smoke test: hot-reload current scenario screen, verify single-turn flow still works

## Success Criteria

- New user (case 1) flow renders identically to today.
- Resume case 2 sample payload (paste in `sendKickoff` mock) renders N bubbles, scrolled bottom, no TTS burst.
- Resume case 3 sample payload sets `completed.value = true`.
- Translation toggle on an AI message persists across a subsequent send.
- Grammar correction appears under the correct user bubble after send completes.

## Risk Assessment

- **Risk:** `ChatMessage` constructor field names differ from assumed (`isTranslationVisible`, `translatedText`, `correctedText`). **Mitigation:** open `chat_message_model.dart` first, adapt named args.
- **Risk:** Order of `removeWhere(typing)` vs `messages.value = ...` could cause typing bubble to flash twice. **Mitigation:** `_applyServerState` rebuilds list from server data; typing placeholder is filtered out automatically since it was a local-only entry. Keep the explicit `_removeTypingPlaceholder()` call before `_applyServerState` to be safe.
- **Risk:** `package:collection` not yet a direct dep. **Mitigation:** check `pubspec.yaml`; if missing, inline `lastWhereOrNull` as a 3-line helper instead of adding a dep.

## Security Considerations
- None — internal state shape only.

## Next Steps
- Phase 3: view swap + l10n + delete orphaned banner.
