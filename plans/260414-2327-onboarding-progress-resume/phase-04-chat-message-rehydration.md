# Phase 04 — Chat Message Rehydration (Backend-Backed)

## Context Links
- Depends on: Phase 03 (chat conversationId persisted) + backend ships endpoints from `backend-requirements.md`
- Backend contract: `./backend-requirements.md`
- BLOCKER: mobile side of this phase cannot merge until backend endpoints are live

## Overview
- **Priority:** Medium (UX polish)
- **Status:** completed 2026-04-15 — backend API live; client rehydrates on cold-resume, 404 fallback starts fresh session, retry banner handles transient failures
- Consume new `GET /onboarding/conversations/:id/messages` to rehydrate chat on resume. Consume idempotent `POST /onboarding/complete` to refetch scenarios cheaply.

## Key Insights
- No client-side message cache. Server is single source of truth.
- Fallback if backend endpoint missing / 404: restart chat session (existing behavior).
- Idempotent `complete()` means scenario UUIDs stay stable across resumes → scenario-gift screen safe to refetch.

## Requirements
**Functional**
- On `AiChatController.onInit()` with restored `conversationId`: GET messages, populate `messages` observable.
- 404 on GET → clear chat checkpoint, start fresh session.
- Scenario-gift resume: call `POST /onboarding/complete` with stored `conversationId` → backend returns cached profile (no extra LLM cost).

**Non-functional**
- GET messages must complete before first paint of chat screen (show `LoadingWidget` during fetch).
- Network failure during rehydrate → retry once, then show error with "Start Over" action.

## Architecture

```
Resume → SplashController routes to chat
                ↓
       AiChatController.onInit()
                ↓
       progress.chat.conversationId != null?
                ↓ yes
       GET /onboarding/conversations/:id/messages
          ├── 200 → parse messages → messages.assignAll(...)
          ├── 404 → progressSvc.clearChat() → start fresh session
          └── network error → show retry UI
```

## Related Code Files
**Modify:**
- `lib/features/chat/controllers/ai_chat_controller.dart`
- `lib/features/chat/models/chat_message.dart` (ensure `fromJson` handles server shape)
- `lib/core/constants/api_endpoints.dart` (add new endpoint)

**Read for context:**
- `lib/core/network/api_client.dart`
- `backend-requirements.md`

## Implementation Steps

1. **Add endpoint constant** in `api_endpoints.dart`:
   ```dart
   static String onboardingMessages(String id) =>
       '/onboarding/conversations/$id/messages';
   ```

2. **Add fetch method** in `AiChatController`:
   ```dart
   Future<void> _rehydrateFromBackend() async {
     if (_conversationId == null) return;
     isLoading.value = true;
     final response = await _apiClient.get(
       ApiEndpoints.onboardingMessages(_conversationId!),
     );
     if (response.isSuccess && response.data != null) {
       final data = response.data as Map<String, dynamic>;
       final rawMessages = (data['messages'] as List<dynamic>? ?? []);
       final parsed = rawMessages
           .map((m) => ChatMessage.fromServerJson(m as Map<String, dynamic>))
           .toList();
       messages.assignAll(parsed);
       _turnNumber = data['turnNumber'] as int? ?? 0;
       isChatComplete.value = data['isLastTurn'] as bool? ?? false;
     } else if (response.statusCode == 404) {
       await Get.find<OnboardingProgressService>().clearChat();
       _conversationId = null;
       await _startNewSession();
     } else {
       // Network error — show retry UI via existing errorMessage pattern
       errorMessage.value = 'resume_chat_failed'.tr;
     }
     isLoading.value = false;
   }
   ```

3. **Hook into `onInit`:**
   ```dart
   @override
   void onInit() {
     super.onInit();
     final progress = Get.find<OnboardingProgressService>().read();
     if (progress.chat != null) {
       _conversationId = progress.chat!.conversationId;
       _rehydrateFromBackend();
     } else {
       _startNewSession();
     }
   }
   ```

4. **Ensure `ChatMessage.fromServerJson`** maps server shape:
   ```dart
   factory ChatMessage.fromServerJson(Map<String, dynamic> json) {
     return ChatMessage(
       id: json['id'] as String,
       role: json['role'] as String, // 'user' | 'assistant'
       content: json['content'] as String,
       timestamp: DateTime.parse(json['createdAt'] as String),
     );
   }
   ```

5. **Scenario-gift refetch** — on screen mount, if `onboardingProfile == null` but progress says complete:
   ```dart
   Future<void> refetchProfile() async {
     final convId = progress.chat?.conversationId;
     if (convId == null) return;
     final resp = await _apiClient.post(
       ApiEndpoints.onboardingComplete,
       data: {'conversation_id': convId},
     );
     if (resp.isSuccess) {
       onboardingCtrl.onboardingProfile =
           OnboardingProfile.fromJson(resp.data as Map<String, dynamic>);
     }
   }
   ```
   Relies on backend idempotency (see `backend-requirements.md` §2).

6. **Add translation keys:** `resume_chat_failed`, `resume_chat_retry` in both l10n files.

7. **Compile check:** `flutter analyze lib/features/chat/controllers/ai_chat_controller.dart`

## Todo List
- [x] Confirm backend endpoints live
- [x] Add endpoint constant (`ApiEndpoints.onboardingConversationMessages`)
- [x] Implement `_rehydrateFromBackend()`
- [x] Wire into `onInit` via `_bootstrapSession()`
- [x] Add `ChatMessage.fromServerJson` with role → type mapping + safe fallbacks
- [x] Implement `refetchProfileIfNeeded()` for scenario-gift (in `OnboardingController`)
- [x] Smart `retrySession()` — picks rehydrate vs new session based on progress checkpoint so the existing error banner works for both flows
- [x] Add translation keys (`resume_chat_failed`, `resume_chat_retry`) in both l10n files
- [x] `flutter analyze` — no new issues
- [x] `flutter test test/features` — 30/30 green

## Success Criteria
- Kill app mid-chat (turn 3) → reopen → chat screen shows 6 previous messages, next user message advances to turn 4.
- Kill app after complete → reopen → scenario-gift shows same scenarios (UUID-stable) without visible LLM delay.
- Backend 404 on resume → chat restarts cleanly with fresh session.
- Airplane mode during rehydrate → retry UI visible, does not crash.

## Risk Assessment
- **Risk:** Backend ships Endpoint 1 but not idempotency (Endpoint 2) → scenario-gift refetch duplicates LLM work + scenario UUIDs change. **Mitigation:** Gate Phase 04 merge on both endpoints.
- **Risk:** `ChatMessage` model divergence between onboarding and main chat feature. **Mitigation:** Put `fromServerJson` on shared model; reuse for both.
- **Risk:** `_turnNumber` field doesn't exist in current controller. **Mitigation:** Inspect controller; if it uses a different counter, adapt accordingly.

## Security Considerations
- GET endpoint is `@Public()` but UUID-based — unguessable. No additional client-side auth needed.

## Next Steps
- Phase 05 covers tests — mock the new endpoint in widget/integration tests.
