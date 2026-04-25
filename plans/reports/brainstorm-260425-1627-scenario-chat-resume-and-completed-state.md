# Brainstorm — Scenario Chat: Resume + Completed State

**Date:** 2026-04-25
**Branch:** `feat/update-onboarding`
**Scope:** Adapt `POST /scenario/chat` client to new response shape; handle 3 entry states (new / resume mid / resume done).

---

## Problem

Backend changes `POST /scenario/chat` response from single-turn (`{reply, conversationId, turn, maxTurns, completed}`) to full conversation state (`{scenario:{...}, messages:[...]}`). Client must:

1. **Case 1 — New user:** status=`CHATTING`, 1 AI msg → existing kickoff UX.
2. **Case 2 — Resume mid-conv:** status=`CHATTING`, N msgs → render history, allow continue.
3. **Case 3 — Completed:** status=`DONE`, N msgs → render history, hide input, show "View Result" button (no-op).

Constraint: backend status string is `CHATTING` (corrected from prior typo `CHATING`).
Constraint: messages with empty `content` must not render a bubble.

---

## Decisions (from clarification)

| Q | A |
|---|---|
| Response shape applies to | **Every call** (kickoff + sends) |
| Send returns | **Full `messages[]` every time** — server-authoritative |
| View Result tap | **No-op** (button only) |
| Done UI | **Replace banner** with View Result button |
| Empty `content` | **Skip rendering** — no bubble |
| Old banner key `scenario_chat_complete_banner` | **Delete** |

---

## Final Design

### 1. New models — `models/scenario_chat_turn_response.dart`

Rewrite as single response container.

```dart
enum ScenarioStatus { chatting, done }

ScenarioStatus _statusFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'DONE': return ScenarioStatus.done;
    case 'CHATTING':
    default:     return ScenarioStatus.chatting; // defensive default
  }
}

class ScenarioState {
  final String conversationId;
  final int    maxTurns;
  final int    turn;
  final ScenarioStatus status;
  // fromJson: snake_case + camelCase tolerant
}

class ScenarioMessage {
  final String   id;
  final String   role;       // "assistant" | "user"
  final String   content;
  final DateTime createdAt;
}

class ScenarioChatResponse {
  final ScenarioState scenario;
  final List<ScenarioMessage> messages;
}
```

Drop `ScenarioChatTurnResponse` entirely.

### 2. Service — `services/scenario_chat_service.dart`

Update generic to `ScenarioChatResponse`. Endpoint unchanged.

### 3. Controller refactor

`scenario_chat_controller.dart` — add:

```dart
bool _isFirstLoad = true;          // suppress TTS auto-play on resume
```

`scenario_chat_controller_messaging.dart` — replace inline state mutation in `sendKickoff()` and `sendText()` with one helper:

```dart
void _applyServerState(ScenarioChatResponse r) {
  conversationId  = r.scenario.conversationId;
  turn.value      = r.scenario.turn;
  maxTurns.value  = r.scenario.maxTurns;
  completed.value = r.scenario.status == ScenarioStatus.done;

  messages.value = _mergeWithServer(messages, r.messages);
  _scrollToBottom();

  if (!_isFirstLoad) _maybeAutoplayLatestAi();
  _isFirstLoad = false;
}
```

`_mergeWithServer(local, server)`:
- Build cache of local per-message UI state by ID:
  `{id → (translatedText, translationVisible, correctedText)}`
- Map each server msg → `ChatMessage`:
  - role=assistant → `ChatMessageType.aiText`
  - role=user      → `ChatMessageType.userText`
  - **skip if `content.trim().isEmpty`** (per requirement)
- Restore cached fields by ID match; for the just-sent user msg whose ID changed from temp to server UUID, fallback match by `(role=user, text==trimmed, latest)`.
- Return new list (replaces `messages.value`).

### 4. Grammar correction — `scenario_chat_controller_grammar.dart`

After server merge, the temp user-message ID (`user_<ts>`) is gone. Change grammar callback to look up the user message by **(role=user, text=trimmed, most-recent)** instead of stored temp ID. Apply `correctedText` in place; trigger reactive update.

### 5. View — `scenario_chat_screen.dart`

Bottom area:

```dart
Obx(() {
  if (controller.completed.value) return const _ViewResultBar();
  if (controller.kickoffFailed.value) return _KickoffErrorBanner(onRetry: controller.retryKickoff);
  return const ScenarioChatInputBar();
}),
```

`_ViewResultBar`: thin container with `AppButton(text: 'scenario_chat_view_result'.tr, onPressed: () {})`.

**Delete** `_CompletedBanner` widget.

### 6. l10n

- **Add** key `scenario_chat_view_result`:
  - en: `"View Result"`
  - vi: `"Xem kết quả"`
- **Delete** key `scenario_chat_complete_banner` from both files.

### 7. Empty-content rule

Filter at message-construction step inside `_mergeWithServer`. Do NOT render placeholder bubbles for empty assistant/user messages — typing indicator (separate code path) is unaffected.

---

## Files Touched

| File | Change |
|---|---|
| `lib/features/scenario-chat/models/scenario_chat_turn_response.dart` | Rewrite: drop old class, add `ScenarioState`, `ScenarioMessage`, `ScenarioChatResponse`, `ScenarioStatus` enum |
| `lib/features/scenario-chat/services/scenario_chat_service.dart` | Update generic type |
| `lib/features/scenario-chat/controllers/scenario_chat_controller.dart` | Add `_isFirstLoad`, `_mergeWithServer`, `_maybeAutoplayLatestAi` |
| `lib/features/scenario-chat/controllers/scenario_chat_controller_messaging.dart` | Replace inline mutation with `_applyServerState(...)` |
| `lib/features/scenario-chat/controllers/scenario_chat_controller_grammar.dart` | Fallback user-msg lookup by content |
| `lib/features/scenario-chat/views/scenario_chat_screen.dart` | Replace `_CompletedBanner` with `_ViewResultBar`; delete unused widget |
| `lib/l10n/english-translations-en-us.dart` | + `scenario_chat_view_result`, − `scenario_chat_complete_banner` |
| `lib/l10n/vietnamese-translations-vi-vn.dart` | + `scenario_chat_view_result`, − `scenario_chat_complete_banner` |

No new files. Stays YAGNI.

---

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Translation cache wipe on every send | Merge by ID + fallback `(role,text)` match preserves it |
| Grammar correction race lost after merge | Lookup by content+role instead of temp ID |
| TTS autoplay re-fires on resume (annoying) | `_isFirstLoad` flag suppresses on first load |
| Backend status string drift (`CHATTING` typo recurrence) | `_statusFromString` defaults unknown → `chatting` |
| Empty AI/user messages pollute scroll | Skip in `_mergeWithServer` |
| Stale `conversationId` if backend returns empty | Only overwrite when non-empty (preserves current logic) |

---

## Success Criteria

- [ ] All 3 cases render correctly on screen open.
- [ ] Resuming case 2 shows N bubbles immediately, scrolled to bottom, input enabled, no TTS audio bursts.
- [ ] Status=DONE hides input, shows "View Result" button (tap = no-op).
- [ ] Empty `content` messages produce no bubble.
- [ ] Translation toggle + grammar correction still work post-send.
- [ ] `flutter analyze` clean; existing scenario chat behavior on first-time user unchanged.

---

## Out of Scope

- "View Result" navigation/screen (button is no-op stub).
- Backend contract changes (assumed coordinated separately).
- "Practice Again" / restart flow (existing `_forceNewPending` path retained).

---

## Open Questions

1. Does backend treat `message: ''` + existing `conversationId` as "load state" (resume) — i.e., does the kickoff call work for both new and resumed sessions? Confirm with backend before merging.
2. Should `kickoffFailed` retry semantics differ for resume vs new user (e.g., on resume failure, navigate back instead of inline retry)? Current design treats both identically; flag if UX should differ.
