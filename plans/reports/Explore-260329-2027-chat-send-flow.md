# Chat Feature: Send Message Flow Analysis

**Date:** 2026-03-29  
**Status:** Complete  
**Focus Areas:** Controllers, Views, Models, API calls, Bindings

---

## Summary

The chat feature uses an **onboarding chat flow** with a single `AiChatController` managing message sending. Messages are sent via `POST /onboarding/chat` endpoint with session token validation. The implementation is relatively clean but has some potential issues.

---

## 1. Send Message Flow

### Entry Points

1. **Chat input bar** (`chat_input_bar.dart`)
   - Text field `onSubmitted` callback → `controller.sendMessage(text)`
   - Send button tap → `controller.sendMessage(textEditingController.text)`

2. **Quick reply selection** (`ai_chat_screen.dart`)
   - Quick reply chip tap → `controller.sendMessage(selectedOption)`

### Implementation: `sendMessage(String text)` (lines 86-130)

```dart
Future<void> sendMessage(String text) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty || _sessionToken == null || isChatComplete.value) return;

  textEditingController.clear();
  messages.removeWhere((m) => m.type == ChatMessageType.quickReplies);
  errorMessage.value = '';

  final lastAiMessage = _getLastAiMessageText();
  final userMessageId = 'user_${DateTime.now().millisecondsSinceEpoch}';
  _addUserMessage(trimmed, messageId: userMessageId);
  isTyping.value = true;

  // Fire grammar check in parallel (non-blocking)
  _checkGrammar(userMessageId, trimmed, lastAiMessage);

  try {
    final response = await _apiClient.post<OnboardingSession>(
      ApiEndpoints.onboardingChat,
      data: {'session_id': _sessionToken, 'message': trimmed},
      fromJson: (data) => OnboardingSession.fromJson(data as Map<String, dynamic>),
    );
    if (response.isSuccess && response.data != null) {
      final session = response.data!;
      progress.value = (session.turnNumber / 10).clamp(0.0, 1.0);
      _addAiMessage(session.reply ?? '', messageId: session.messageId);
      if (session.quickReplies.isNotEmpty) {
        _addQuickReplies(session.quickReplies);
      }
      if (session.isLastTurn) {
        await _completeOnboarding();
      }
    } else {
      errorMessage.value = response.message;
    }
  } on ApiException catch (e) {
    errorMessage.value = e.userMessage;
  } catch (_) {
    errorMessage.value = 'unknown_error'.tr;
  } finally {
    isTyping.value = false;
  }
}
```

**Flow:**
1. Trim input text
2. Validate: not empty, session token exists, chat not complete
3. Clear input field and remove quick reply buttons
4. Add user message to UI immediately (optimistic)
5. Fire grammar check in background (fire-and-forget)
6. POST to `/onboarding/chat` with session ID and message
7. On success: add AI response, add quick replies if any, check if last turn
8. On last turn: call `_completeOnboarding()` which navigates away

---

## 2. API Endpoint & Request/Response

### Endpoint
- **URL:** `POST /onboarding/chat` (from `ApiEndpoints.onboardingChat`)
- **Base URL:** Configured in `EnvConfig.apiBaseUrl`

### Request Data
```json
{
  "session_id": "<token from onboarding start>",
  "message": "<trimmed user text>"
}
```

### Response Model: `OnboardingSession`
**File:** `/lib/features/onboarding/models/onboarding_session_model.dart`

Parsed fields:
- `session_id` / `sessionToken` (nullable)
- `message_id` / `messageId` (nullable)
- `turn_count` / `turnNumber` (defaults to 0)
- `max_turns` / `maxTurns` (defaults to 10)
- `is_last_turn` / `isLastTurn` (calculated: `turnCount >= maxTurns`)
- `response` / `reply` / `floraMessage` → AI message text
- `quick_replies` / `quickReplies` → array of reply chips
- `expires_at` → optional session expiration

---

## 3. Bindings & Dependency Injection

**File:** `/lib/features/chat/bindings/ai_chat_binding.dart`

```dart
class AiChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiChatController>(() => AiChatController());
  }
}
```

**Issues Found:**
1. ✓ Controller is lazy-loaded (good)
2. ✓ Dependencies are injected via GetX (ApiClient, OnboardingController, StorageService found in controller)
3. ⚠️ **NO EXPLICIT DEPENDENCY DECLARATION** — Controller dependencies (`ApiClient`, `OnboardingController`, `StorageService`) are resolved globally via `Get.find()`, not declared in binding

---

## 4. Views & UI

### Main Screen: `ai_chat_screen.dart`
- Displays chat messages, error banner, context card, input bar
- Uses `Obx()` for reactivity
- Message list handles: AI text, user text, quick replies, typing indicator

### Input Bar: `chat_input_bar.dart`
- Three states: normal input, recording, complete
- Send button only shows if `hasText && !isComplete`
- Mic button only shows if `!isComplete && !hasText`
- Passes text to `controller.sendMessage()`

### Text Input Field: `chat_text_input_field.dart`
- **Issue:** Does NOT trim input before passing to `onSubmitted`
- Trimming happens in controller's `sendMessage()` — this is OK but adds a step

---

## 5. State Management

### Observable States in Controller
- `messages` — list of `ChatMessage`
- `isTyping` — shows typing indicator when true
- `isChatComplete` — blocks input after last turn
- `progress` — visual progress bar (0-1)
- `errorMessage` — shown in error banner
- `chatTitle` — passed from route args
- `contextDescription` — passed from route args

### Message Model: `ChatMessage`
```dart
class ChatMessage {
  final String id;
  final ChatMessageType type;  // aiText, userText, quickReplies, aiTyping
  final String? text;
  String? translatedText;
  bool showTranslation;
  final List<String>? quickReplies;
  final DateTime timestamp;
  String? correctedText;
  bool showCorrection;
}
```

---

## 6. Issues Identified

### Critical Issues

**1. Race Condition in Grammar Check**
- **File:** `ai_chat_controller.dart`, lines 99-100, 245-276
- **Issue:** Grammar check runs in parallel with API call; may complete after the next message arrives
- **Impact:** Grammar corrections may show for wrong message if user sends multiple messages quickly
- **Example:** 
  1. User sends "I is happy" → grammar check starts
  2. User immediately sends "Good morning" → new API call
  3. Grammar correction for "I is happy" arrives while showing second message
  
**2. Missing Null Safety in Progress Calculation**
- **File:** `ai_chat_controller.dart`, line 110
- **Code:** `progress.value = (session.turnNumber / 10).clamp(0.0, 1.0);`
- **Issue:** If `session.turnNumber` is 0 (default), progress stays at 0 even after multiple turns
- **Impact:** Progress bar won't advance if API doesn't return turn count correctly

**3. Silent Failure in Grammar Check**
- **File:** `ai_chat_controller.dart`, lines 273-275
- **Code:** `catch (_) { // Silent fail — grammar check is non-critical }`
- **Issue:** No error logging; if API is down, user gets no feedback
- **Impact:** Users won't know why grammar corrections aren't appearing

**4. Weak Session Validation**
- **File:** `ai_chat_controller.dart`, line 88
- **Issue:** Only checks `_sessionToken == null`, not if session expired (`expiresAt`)
- **Code:** `if (trimmed.isEmpty || _sessionToken == null || isChatComplete.value) return;`
- **Impact:** Can send messages after session expires without user knowing

**5. Missing Error Recovery for Failed Messages**
- **File:** `ai_chat_controller.dart`, lines 120-122, 124-126
- **Issue:** On API error, user message is already added to UI, but no retry mechanism
- **Impact:** User sees their message but no AI response; manual retry isn't clearly offered

### Medium Issues

**6. Optimistic UI Update Risk**
- **File:** `ai_chat_controller.dart`, lines 90-96
- **Issue:** User message added to UI before API validation
- **Impact:** If API rejects message (e.g., forbidden content), user message already visible

**7. Quick Replies Removed Before Send**
- **File:** `ai_chat_controller.dart`, line 91
- **Code:** `messages.removeWhere((m) => m.type == ChatMessageType.quickReplies);`
- **Issue:** Happens BEFORE API call; if API fails, quick replies are gone
- **Impact:** User can't retry failed message with quick reply options

**8. Unclear Input Validation**
- **File:** `chat_text_input_field.dart` vs `ai_chat_controller.dart`
- **Issue:** Input trimming split between widget and controller; no max length check
- **Impact:** Very long inputs could fail silently or crash UI

### Minor Issues

**9. Hard-coded max turns value**
- **File:** `onboarding_session_model.dart`, line 31
- **Code:** `.maxTurns = 10` (default)
- **Issue:** If backend returns different max, UI calculation is wrong

**10. Empty reply handling**
- **File:** `ai_chat_controller.dart`, line 112
- **Code:** `_addAiMessage(session.reply ?? '', messageId: session.messageId);`
- **Issue:** Empty string shown if API returns null reply
- **Impact:** Typing bubble shows, then empty message appears

---

## 7. Data Flow Diagram

```
User Input (Text Field)
    ↓
ChatInputBar: onSubmitted / onSend
    ↓
controller.sendMessage(text)
    ├─ Trim text
    ├─ Validate (not empty, session exists, not complete)
    ├─ Clear input field
    ├─ Remove quick replies from UI
    ├─ Add user message to UI (optimistic)
    ├─ Fire grammar check (async, non-blocking)
    │   └─ POST /ai/chat/correct
    │       └─ Update message with correction (if found)
    │
    └─ POST /onboarding/chat
        ├─ Request: {session_id, message}
        ├─ Response: OnboardingSession
        │   ├─ reply (AI message)
        │   ├─ quick_replies (buttons)
        │   ├─ is_last_turn (completion flag)
        │   └─ turn_count (progress)
        │
        ├─ Add AI message to UI
        ├─ Add quick replies if any
        ├─ Update progress bar
        ├─ If last turn:
        │   └─ POST /onboarding/complete
        │       └─ Navigate to scenario gift
        │
        └─ Error handling:
            ├─ API error → show error message
            └─ Network error → show error message
```

---

## 8. API Interceptors & Auth Flow

**File:** `/lib/core/network/api_client.dart`

Interceptor stack (order matters):
1. `RetryInterceptor` (maxRetries: 3)
2. `AuthInterceptor` (adds bearer token)
3. `HttpLoggerInterceptor` (logs requests/responses)

**Session Token Management:**
- Obtained from `/onboarding/start` response
- Stored in `StorageService` with key `'onboarding_session_token'`
- Used in ALL subsequent `/onboarding/chat` calls
- **Issue:** Not validated for expiration before use

---

## 9. Obvious Bugs & Issues Summary

| # | Severity | Issue | File:Line | Fix |
|---|----------|-------|-----------|-----|
| 1 | Critical | Grammar check race condition | `ai_chat_controller.dart:245-276` | Cancel previous grammar check before starting new one |
| 2 | Critical | Session expiration not checked | `ai_chat_controller.dart:88` | Check `expiresAt` before sending |
| 3 | High | Progress bar stuck at 0 | `ai_chat_controller.dart:110` | Add fallback if `turnNumber` is 0 |
| 4 | High | Failed message unrecoverable | `ai_chat_controller.dart:120-126` | Keep user message editable or add explicit retry |
| 5 | High | Silent grammar check failure | `ai_chat_controller.dart:273` | Log or show subtle error indicator |
| 6 | Medium | Optimistic update can't be rolled back | `ai_chat_controller.dart:96` | Show "Sending..." state until API confirms |
| 7 | Medium | Quick replies removed before API confirms | `ai_chat_controller.dart:91` | Remove after successful API response |
| 8 | Medium | Empty reply shown as message | `ai_chat_controller.dart:112` | Show error or retry if reply is empty |
| 9 | Low | No max input length | `chat_text_input_field.dart` | Add maxLines and validation |
| 10 | Low | Hard-coded max turns | `onboarding_session_model.dart:31` | Use backend value if provided |

---

## 10. Code Quality Notes

**Positives:**
- ✓ Clean separation of concerns (controller, view, model)
- ✓ Good use of reactive state management (Obx)
- ✓ Error messages shown to user
- ✓ Fire-and-forget pattern for non-critical operations (grammar)
- ✓ Proper async/await usage
- ✓ Message ID generation with timestamps

**Negatives:**
- ✗ No typing system for API responses (uses `Map<String, dynamic>`)
- ✗ Multiple null checks scattered throughout
- ✗ No logging for debugging
- ✗ Hard-coded timeout values
- ✗ No request cancellation mechanism
- ✗ Limited error context (generic "unknown_error" message)

---

## 11. Testing Recommendations

1. **Message sending after session expiry** — should show error, not send
2. **Rapid message sending** — verify grammar corrections match correct messages
3. **Network failure during send** — user should be able to retry
4. **Very long input (>5000 chars)** — should handle gracefully
5. **Multiple grammar requests** — verify only latest is shown
6. **Missing AI reply** — should not show empty bubble

---

## 12. Questions Unresolved

1. What happens if `/onboarding/start` fails? Does session exist?
2. Does backend validate `session_id` format? Can token be spoofed?
3. What's the actual session TTL on backend?
4. Does grammar check endpoint have rate limits?
5. Can user send message while typing indicator is showing?
6. How are message IDs used by backend — just for logging?

