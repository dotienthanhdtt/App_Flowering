# Brainstorm: Chat Grammar Correction Feature

**Date:** 2026-03-10
**Status:** Approved (Option A)
**Design reference:** `design.pen` → screen `08b_chat_grammar_check` (node `kYRBv`)
**API reference:** `docs/api_docs/correct_api.md`

---

## Problem

When a user sends a message in the AI chat, there's no grammar feedback. Users don't know if they made mistakes unless the AI tutor explicitly mentions it.

## Solution

Call `POST /ai/chat/correct` **in parallel** with the chat response API every time the user sends a message. If errors are found, show a correction UI inside the user's message bubble. If correct, show nothing.

---

## Approach: Option A — Fire-and-Forget Parallel Call (Selected)

### Why This Option

- **Fastest UX** — correction appears almost instantly, doesn't block chat flow
- **API-aligned** — the correction endpoint docs say "designed to be called in parallel with chat response"
- **Non-blocking** — if correction API fails or is slow, chat works normally

### Rejected Alternatives

| Option | Why Rejected |
|--------|-------------|
| **B: Sequential** (call after chat response) | Slower UX, unnecessary wait |
| **C: Lazy on tap** (check grammar on user action) | Defeats automatic grammar feedback purpose |

---

## Design Spec (from Pencil screen 08b)

### User Message Bubble — With Grammar Correction

```
┌─────────────────────────────────────┐
│ I will going to the park with my    │  ← original text (bold/medium weight)
│ friends tommorow                    │
│─────────────────────────────────────│  ← thin orange divider (#FFB380)
│ ✓ Corrected                         │  ← green label (#4A8A58) + check icon
│ I will go to the park with my       │  ← corrected text (regular weight)
│ friends tomorrow                    │
│                                     │
│ Hide                                │  ← toggle button (#FFB380)
└─────────────────────────────────────┘
```

### Visual Tokens (from design)

- **Bubble:** `AppColors.primary` (#FF7A27), borderRadius `[16,16,0,16]`
- **Divider:** top border `#FFB380` (AppColors.primaryLight), 1px
- **"Corrected" label:** green `#4A8A58` (AppColors.accentGreenDark), fontSize 11, fontWeight 600, with `circle-check` icon (12px)
- **Corrected text:** white, fontSize 13, fontWeight normal, lineHeight 1.5
- **"Hide" button:** `#FFB380` (AppColors.primaryLight), fontSize 12, fontWeight 500
- **Collapsed state:** entire GrammarCorrection section hidden, only "Show" button visible

### Behavior

- If `correctedText == null` → show nothing (message is correct)
- If `correctedText != null` → show correction expanded by default
- User taps "Hide" → collapse correction section, button text changes to "Show"
- User taps "Show" → expand correction section again

---

## Architecture

### Data Flow

```
User taps Send
    │
    ├──► [Parallel] POST /onboarding/chat  →  AI reply + quick replies
    │
    └──► [Parallel] POST /ai/chat/correct  →  correctedText or null
              │
              ▼
         Update ChatMessage.correctedText
              │
              ▼
         Obx rebuilds UserMessageBubble with correction UI
```

### Files to Modify

| File | Change |
|------|--------|
| `models/chat_message_model.dart` | Add `correctedText` (String?) and `showCorrection` (bool) fields |
| `core/constants/api_endpoints.dart` | Add `chatCorrect = '/ai/chat/correct'` endpoint constant |
| `controllers/ai_chat_controller.dart` | Fire correction API in parallel in `sendMessage()`, track last AI message |
| `widgets/user_message_bubble.dart` | Add grammar correction UI section below user text |
| `views/ai_chat_screen.dart` | Pass `message` object + `onToggleCorrection` callback to `UserMessageBubble` |

### No New Files Created

All changes go into existing files per project rules.

---

## Implementation Details

### 1. ChatMessage Model Changes

```dart
// Add to ChatMessage class
String? correctedText;    // null = correct, non-null = has errors
bool showCorrection;      // toggle expanded/collapsed (default: true)
```

### 2. API Endpoint

```dart
// api_endpoints.dart
static const String chatCorrect = '/ai/chat/correct'; // POST
```

### 3. Controller Logic

```dart
// In sendMessage():
// 1. Get the last AI message text before sending
// 2. Fire both APIs in parallel
// 3. When correction returns, find the user message and update correctedText
// 4. Refresh messages list to trigger rebuild

final lastAiMessage = _getLastAiMessageText();

// Fire correction in parallel (non-blocking)
_checkGrammar(trimmed, lastAiMessage);

// ... existing chat API call ...
```

```dart
Future<void> _checkGrammar(String userText, String? previousAiMessage) async {
  if (previousAiMessage == null) return;
  try {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.chatCorrect,
      data: {
        'previousAiMessage': previousAiMessage,
        'userMessage': userText,
        'targetLanguage': _onboardingCtrl.selectedLearningLanguage.value,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    if (response.isSuccess && response.data != null) {
      final corrected = response.data!['correctedText'] as String?;
      if (corrected != null) {
        // Find the user message and attach correction
        final idx = messages.lastIndexWhere(
          (m) => m.type == ChatMessageType.userText && m.text == userText,
        );
        if (idx != -1) {
          messages[idx].correctedText = corrected;
          messages[idx].showCorrection = true;
          messages.refresh();
        }
      }
    }
  } catch (_) {
    // Silent fail — grammar check is non-critical
  }
}
```

### 4. UserMessageBubble UI Changes

- Accept `ChatMessage` instead of just `String text`
- Add `onToggleCorrection` callback
- Render correction section conditionally when `correctedText != null`
- Toggle between expanded (show corrected text) and collapsed (hide it)

### 5. AiChatScreen Changes

```dart
// In _buildMessageItem:
case ChatMessageType.userText:
  return UserMessageBubble(
    message: message,
    onToggleCorrection: () => controller.toggleCorrection(message.id),
  );
```

---

## Edge Cases

| Case | Handling |
|------|----------|
| Correction API timeout/failure | Silent fail, no correction shown |
| User sends while correction still loading | Each correction is independent per message |
| Correction returns after user scrolled away | Message updates reactively via Obx |
| User message is already correct | `correctedText = null`, no UI change |
| Quick reply selected (not typed) | Still check grammar (quick replies may have intentional errors for learning) |

---

## Success Criteria

- [ ] Correction API called in parallel with chat API on every user message
- [ ] If errors found: correction UI appears inside user bubble matching screen 08b design
- [ ] If no errors: no visual change to user bubble
- [ ] Hide/Show toggle works correctly
- [ ] Correction API failure doesn't break chat flow
- [ ] No compile errors, app runs normally