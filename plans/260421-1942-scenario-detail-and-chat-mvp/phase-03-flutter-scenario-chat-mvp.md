# Phase 3 — Flutter: Scenario Chat MVP (Text-Only)

## Context Links

- Brainstorm: [../reports/brainstorm-2026-04-21-scenario-detail.md](../reports/brainstorm-2026-04-21-scenario-detail.md)
- Phase 2: [phase-02-flutter-detail-screen.md](phase-02-flutter-detail-screen.md)
- Backend chat routes: `be_flowering/src/modules/scenario/scenario-chat.controller.ts`
  - `POST /scenario/chat` — send turn
  - `GET /scenario/conversations/:id` — load transcript
  - `GET /scenario/:scenarioId/conversations` — list user's past conversations (NOT used in MVP)
- Reusable widgets: `lib/features/chat/widgets/ai_message_bubble.dart`, `user_message_bubble.dart`, `chat_input_bar.dart`, `chat_top_bar.dart`, `ai_typing_bubble.dart`
- Reference controller pattern: `lib/features/chat/controllers/ai_chat_controller.dart`
- Chat message model to reuse: `lib/features/chat/models/chat_message_model.dart`

## Overview

**Priority:** P1
**Status:** complete
**Blocked by:** None
**Effort:** 5h

Build a minimal scenario chat screen: send text turns to `POST /scenario/chat`, render AI replies using existing chat bubbles, disable input when `completed: true`. Reuse widgets — do NOT fork.

## Key Insights

- `AiChatScreen` is complex: voice, grammar correction, translation sheet, context card, conversation history. MVP strips all of that.
- `POST /scenario/chat` accepts `{ scenarioId, message, forceNew?, conversationId? }` and returns `{ reply, conversationId, turn, maxTurns, completed }`. Initial turn is server-initialized — sending an empty-ish first message or using `forceNew: true` triggers the opener.
- Conversation state (turn, maxTurns, completed) is server-authoritative. FE just persists `conversationId` for the session.
- "Practice Again" → `forceNew: true` on the FIRST call. Backend marks old convos completed and starts fresh.
- No local persistence across app restarts — conversationId lives only in controller memory. Reload = fresh session.
- 403 → premium gate (already covered by backend). FE shows error + reroute to paywall.

## Requirements

### Functional
- Route: `/scenario-chat` with `arguments: {'scenarioId': '<uuid>', 'scenarioTitle': '<string>', 'forceNew': <bool>}`.
- Top bar: back button + scenario title + (optional) turn indicator `x / N`.
- Messages render in a scrolling list using `AiMessageBubble` / `UserMessageBubble`.
- Typing indicator (`AiTypingBubble`) visible while awaiting response.
- Input bar (`ChatInputBar`) at bottom; disabled when `completed == true`.
- First open: auto-send server-kickoff (empty string or dedicated init call) so the AI posts the opener.
- On `completed` → show system message "Conversation complete. Tap Practice Again to replay." + disable input. User must navigate back.
- Network error → toast + keep input enabled so user can retry.
- 403 → snackbar + back to detail + open paywall.
- Back arrow → `Get.back()`. Conversation persists on backend regardless.

### Non-functional
- Controller extends `BaseController`; screen extends `BaseScreen<ScenarioChatController>`.
- Reuse existing chat widgets verbatim. If a widget needs a small API extension, justify in PR — don't fork.
- All user-facing text via `.tr`.
- Files ≤ 200 lines; split sender logic into helper mixin/extension if needed.

## Architecture

```
ScenarioDetail CTA (start / practice again)
    │
    └─► Get.toNamed('/scenario-chat', arguments: { scenarioId, scenarioTitle, forceNew: bool })
           │
           ▼
ScenarioChatBinding → put(ScenarioChatController(args))
           │
           ▼
ScenarioChatScreen
    ├─ ChatTopBar(title: scenarioTitle)
    ├─ Obx(ListView of messages) — uses AiMessageBubble / UserMessageBubble
    ├─ Obx(ChatInputBar, enabled: !completed)
    └─ Obx(AiTypingBubble when pending)

Controller
    ├─ onInit → sendKickoff()
    ├─ sendText(text) → POST /scenario/chat
    └─ completed flips when server reports true
```

## Data Flow

```
sendText("hello")
    │
    ▼
apiCall(service.chat({
  scenarioId,
  message: "hello",
  forceNew: (first call && forceNewRequested),
  conversationId,  // omitted on first call
}))
    │
    ├─► messages.add(UserMessage("hello"))
    ├─► isSending.value = true
    │
    └─► onSuccess:
          isSending.value = false
          conversationId = resp.conversationId
          turn = resp.turn
          maxTurns = resp.maxTurns
          completed.value = resp.completed
          messages.add(AiMessage(resp.reply))
```

## Related Code Files

**Create (feature root: `lib/features/scenario-chat/`):**
- `models/scenario_chat_turn_request.dart`
- `models/scenario_chat_turn_response.dart`
- `services/scenario_chat_service.dart`
- `controllers/scenario_chat_controller.dart`
- `bindings/scenario_chat_binding.dart`
- `views/scenario_chat_screen.dart`

**Modify:**
- `lib/app/routes/app-route-constants.dart` — add `scenarioChat = '/scenario-chat'`.
- `lib/app/routes/app-page-definitions-with-transitions.dart` — register page + binding.
- `lib/core/constants/api_endpoints.dart` — add `scenarioChat = '/scenario/chat'`, `scenarioConversations = '/scenario/conversations'` as needed.
- `lib/features/scenarios/widgets/scenario_detail_cta.dart` (Phase 2) — replace TODO snackbar with `Get.toNamed(AppRoutes.scenarioChat, arguments: {...})`.
- `lib/l10n/english-translations-en-us.dart` + vietnamese — add keys listed below.

**Read for context (no changes):**
- `lib/features/chat/controllers/ai_chat_controller_messaging.dart` — message list patterns
- `lib/features/chat/models/chat_message_model.dart` — confirm reusability vs new model

## Implementation Steps

1. **Request / response DTOs.**
   ```dart
   class ScenarioChatTurnRequest {
     final String scenarioId;
     final String message;
     final bool? forceNew;
     final String? conversationId;
     Map<String, dynamic> toJson();
   }
   class ScenarioChatTurnResponse {
     final String reply;
     final String conversationId;
     final int turn;
     final int maxTurns;
     final bool completed;
     factory ScenarioChatTurnResponse.fromJson(Map<String, dynamic> json);
   }
   ```

2. **Service** (`scenario_chat_service.dart`) extends `GetxService`:
   ```dart
   Future<ApiResponse<ScenarioChatTurnResponse>> chat(ScenarioChatTurnRequest req) =>
     _apiClient.post(
       ApiEndpoints.scenarioChat,
       data: req.toJson(),
       fromJson: (d) => ScenarioChatTurnResponse.fromJson(d as Map<String, dynamic>),
     );
   ```
   Register in `global-dependency-injection-bindings.dart` (lazy or permanent — match existing scenarios service).

3. **Controller** (`scenario_chat_controller.dart`):
   - Fields: `messages = <ChatMessageModel>[].obs`, `isSending = false.obs`, `completed = false.obs`, `conversationId: String?`, `turn = 0.obs`, `maxTurns = 0.obs`, `scenarioTitle`, `scenarioId`, `_forceNewPending`.
   - `onInit`: if `_forceNewPending || conversationId == null` → `sendKickoff()`.
   - `sendKickoff()`: sends empty-ish turn with `forceNew: _forceNewPending` so the server posts the opener. Adjust based on actual BE contract — if empty messages rejected, use a sentinel like `"__start__"` that BE recognizes, or confirm the BE auto-posts opener when `conversationId` omitted.
     > **Open question for BE alignment** — confirm the exact first-turn semantics before coding. Read `scenario-chat.service.ts:66-144` once before implementing.
   - `sendText(String text)`: push user message, call service, handle success/error. On 403 → snackbar + pop + trigger paywall. On other network error → snackbar + re-enable input.
   - `onClose`: no-op (backend owns state).

4. **Binding**: `Get.put(ScenarioChatController(scenarioId, scenarioTitle, forceNew))` reading `Get.arguments`.

5. **Screen** (`scenario_chat_screen.dart`):
   - Column: `ChatTopBar(title: controller.scenarioTitle)`, `Expanded(Obx(ListView))`, `Obx(completed ? systemBar : ChatInputBar(...))`.
   - ListView builds with existing bubble widgets. Include `AiTypingBubble` when `isSending && lastMessageIsUser`.
   - Auto-scroll to bottom on new messages (same pattern as `ai_chat_screen.dart`).

6. **CTA wiring in Phase 2's `ScenarioDetailController`.** Replace the snackbar placeholder:
   ```dart
   void onStart() => Get.toNamed(AppRoutes.scenarioChat, arguments: {
     'scenarioId': detail.value!.id,
     'scenarioTitle': detail.value!.title,
     'forceNew': false,
   });
   void onPracticeAgain() => Get.toNamed(AppRoutes.scenarioChat, arguments: {
     'scenarioId': detail.value!.id,
     'scenarioTitle': detail.value!.title,
     'forceNew': true,
   });
   ```

7. **Routing.** Add `AppRoutes.scenarioChat = '/scenario-chat';` + `GetPage` with `ScenarioChatBinding` and a forward slide transition.

8. **Translations** (en + vi):
   - `scenario_chat_complete_banner`: "Conversation complete. Tap Practice Again to replay." / Vietnamese equivalent
   - `scenario_chat_error_send`: "Couldn't send. Try again." / "Không thể gửi. Vui lòng thử lại."
   - `scenario_chat_premium_required`: "Premium required for this scenario." / "Cần gói Premium cho kịch bản này."

9. **Compile + manual QA:**
   - `flutter analyze` clean.
   - Start → see opener → send text → see AI reply → reach maxTurns → input disables.
   - Practice Again → new conversationId, fresh state.
   - Locked premium (bypass detail) → 403 → toast + pop + paywall.

## Todo List

- [ ] Request / response DTOs
- [ ] `scenario_chat_service.dart` + DI registration
- [ ] `scenario_chat_controller.dart` with kickoff + send + 403 handling
- [ ] `scenario_chat_binding.dart`
- [ ] `scenario_chat_screen.dart` reusing existing chat widgets
- [ ] Replace Phase 2 TODO snackbar with real navigation
- [ ] Route + page definition
- [ ] 3 translation keys (en + vi)
- [ ] `flutter analyze` clean
- [ ] Manual QA: start, practice-again, completion, 403 gate

## Success Criteria

- [ ] Opener appears automatically on first open.
- [ ] Back-and-forth text works; turn counter tracks server values.
- [ ] On `completed: true` → input disabled + system banner visible.
- [ ] Practice Again starts a fresh conversation (new `conversationId`).
- [ ] Locked premium scenario cannot reach chat screen (gated at Phase 2 CTA); direct nav test returns 403 cleanly.
- [ ] No fork of existing chat widgets — only reuse.
- [ ] Files ≤ 200 lines.

## Risk Assessment

- **First-turn semantics drift** — if `POST /scenario/chat` rejects empty strings, kickoff strategy needs adjustment. Resolve by reading backend service method before coding.
- **Double-tap send** — debounce via `isSending.value` guard in `sendText`.
- **Message re-render cost** — for long convos (12 turns max), `Obx` on full list is fine. No virtualization needed.
- **Race on back-nav during send** — `apiCall` may resolve after controller disposed. Guard with `isClosed` check before mutating obs.
- **Reusable widget assumptions** — verify `ChatInputBar` accepts a disabled state or a null `onSend`. If not, extend its API in a backward-compatible way (flag with PR note).

## Security Considerations

- Chat endpoints already enforce premium + ownership. No FE check required beyond handling 403.
- Don't log message content at info level (covered by global interceptor).

## Next Steps

Phase 4: cross-cutting tests + translations coverage + `flutter analyze` + docs.
