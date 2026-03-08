# Phase 03 — AI Chat Real API (Screen 07)

## Overview
- **Priority:** P1
- **Status:** Completed
- **Effort:** 3h
- **Blocked by:** Phase 02

Replace the scripted mock AI chat with real `/onboarding/start`, `/onboarding/chat`, and `/onboarding/complete` API calls.

## Key Insights

- Current `AiChatController` has a 3-step scripted flow with no API calls
- Real flow: start session → 10 chat turns → complete → navigate to scenario gift
- `sessionToken` from `/onboarding/start` must persist for all subsequent calls
- Progress bar based on `turnNumber / 10`
- `isLastTurn=true` signals end of conversation
- Must handle errors gracefully: network retry, session expired → restart

## Requirements

### Functional
- Call `POST /onboarding/start` with selected language IDs on screen open
- Store returned `sessionToken` in controller + StorageService
- Send user messages via `POST /onboarding/chat`
- Display Flora's AI responses with typing animation
- Track progress via `turnNumber / 10`
- On `isLastTurn=true`: disable input, call `/onboarding/complete`, navigate to screen 08
- Quick replies from API displayed as tappable chips

### Non-functional
- Typing animation before showing AI response (existing `AiTypingBubble` reused)
- Message history maintained in controller state
- Graceful error handling with retry option

## Related Code Files

### Modify
- `lib/features/chat/controllers/ai_chat_controller.dart` — full rewrite: remove mock, add API calls
- `lib/features/chat/views/ai_chat_screen.dart` — update to use new controller state
- `lib/features/chat/widgets/chat_top_bar.dart` — dynamic progress from controller
- `lib/features/chat/widgets/chat_input_bar.dart` — disable on last turn, handle topic chips removal

### Delete
<!-- Updated: Validation Session 1 - remove TopicChipGrid entirely -->
- `lib/features/chat/widgets/topic_chip_grid.dart` — remove (real API uses quick replies)

### Keep As-Is
- `lib/features/chat/models/chat_message_model.dart` — reuse ChatMessage + ChatMessageType (remove OnboardingTopic/kOnboardingTopics)
- `lib/features/chat/widgets/ai_message_bubble.dart` — reuse (may need minor updates)
- `lib/features/chat/widgets/user_message_bubble.dart` — reuse

## Architecture

```
AiChatScreen
  → AiChatController
    → POST /onboarding/start (init)
      ← sessionToken, floraMessage, quickReplies
    → POST /onboarding/chat (per turn)
      ← floraMessage, quickReplies, turnNumber, isLastTurn
    → POST /onboarding/complete (on last turn)
      ← OnboardingProfile { scenarios[] }
    → OnboardingController (store sessionToken + profile)
    → StorageService (sessionToken backup)
```

## Implementation Steps

### 1. Rewrite AiChatController

Remove all scripted logic. New structure:

```dart
class AiChatController extends GetxController {
  final ApiClient _apiClient = Get.find();
  final OnboardingController _onboardingCtrl = Get.find();
  final StorageService _storageService = Get.find();

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isTyping = false.obs;
  final isChatComplete = false.obs;
  final progress = 0.0.obs;
  final currentQuickReplies = <String>[].obs;
  final errorMessage = ''.obs;

  String? _sessionToken;

  @override
  void onInit() {
    super.onInit();
    _startSession();
  }

  Future<void> _startSession() async {
    isLoading.value = true;
    try {
      final response = await _apiClient.post<OnboardingSession>(
        ApiEndpoints.onboardingStart,
        data: {
          'nativeLanguageId': _onboardingCtrl.selectedNativeLanguageId,
          'learningLanguageId': _onboardingCtrl.selectedLearningLanguageId,
        },
        fromJson: (data) => OnboardingSession.fromJson(data),
      );
      if (response.isSuccess && response.data != null) {
        final session = response.data!;
        _sessionToken = session.sessionToken;
        _storageService.setPreference('onboarding_session_token', _sessionToken);
        _onboardingCtrl.sessionToken = _sessionToken;

        // Add Flora's greeting
        messages.add(ChatMessage(
          text: session.floraMessage ?? '',
          type: ChatMessageType.ai,
        ));
        currentQuickReplies.value = session.quickReplies ?? [];
      }
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage(String text) async {
    if (_sessionToken == null || isChatComplete.value) return;

    // Add user message
    messages.add(ChatMessage(text: text, type: ChatMessageType.user));
    currentQuickReplies.clear();
    isTyping.value = true;

    try {
      final response = await _apiClient.post<OnboardingSession>(
        ApiEndpoints.onboardingChat,
        data: {
          'sessionToken': _sessionToken,
          'message': text,
        },
        fromJson: (data) => OnboardingSession.fromJson(data),
      );
      if (response.isSuccess && response.data != null) {
        final session = response.data!;
        progress.value = session.turnNumber / 10;

        // Add Flora's reply
        messages.add(ChatMessage(
          text: session.floraMessage ?? '',
          type: ChatMessageType.ai,
        ));
        currentQuickReplies.value = session.quickReplies ?? [];

        if (session.isLastTurn) {
          await _completeOnboarding();
        }
      }
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;
    } finally {
      isTyping.value = false;
    }
  }

  Future<void> _completeOnboarding() async {
    isChatComplete.value = true;
    try {
      final response = await _apiClient.post<OnboardingProfile>(
        ApiEndpoints.onboardingComplete,
        data: {'sessionToken': _sessionToken},
        fromJson: (data) => OnboardingProfile.fromJson(data),
      );
      if (response.isSuccess && response.data != null) {
        _onboardingCtrl.onboardingProfile = response.data;
        // Short delay for user to read last message
        await Future.delayed(const Duration(seconds: 2));
        Get.toNamed(AppRoutes.onboardingScenarioGift);
      }
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;
      isChatComplete.value = false; // Allow retry
    }
  }
}
```

### 2. Update AiChatScreen

- Wrap message list with `Obx` using `controller.messages`
- Show loading spinner during `_startSession`
- Show error banner with retry when `errorMessage` is non-empty
- Pass `controller.progress.value` to `ChatTopBar`

### 3. Update ChatTopBar

- Accept `progress` as reactive: `Obx(() => ...)` with controller reference
- Animate progress bar width based on `turnNumber / 10`

### 4. Update ChatInputBar

- Disable text field + send button when `isChatComplete.value`
- Show quick reply chips from `controller.currentQuickReplies`
- Remove topic chip grid (was part of mock flow)

### 5. Handle Edge Cases

- **Network error during chat:** Show retry button on last failed message
- **Session expired (401):** Clear session token, show "Session expired" dialog, navigate back to start
- **10 turns reached:** Automatically call `/onboarding/complete`
- **User presses back:** Confirm dialog "Leave conversation? Progress will be lost"

## Todo List

- [ ] Rewrite AiChatController with real API calls
- [ ] Update AiChatScreen for new controller state
- [ ] Update ChatTopBar with dynamic progress
- [ ] Update ChatInputBar — disable on complete, quick replies from API
- [ ] Handle network errors with retry
- [ ] Handle session expiry
- [ ] Handle back navigation confirmation
- [ ] Store sessionToken in OnboardingController + StorageService
- [ ] Navigate to Scenario Gift on completion
- [ ] Run `flutter analyze`

## Success Criteria

- Chat starts with real API call on screen open
- User messages sent to API, Flora replies displayed
- Progress bar advances with each turn
- Chat completes after `isLastTurn=true` → navigates to scenario gift
- Errors shown with retry option
- sessionToken persisted across controller + storage

## Risk Assessment

- **API response format mismatch** → use flexible fromJson, validate with backend
- **Slow API responses** → typing indicator provides visual feedback
- **Session token loss** → dual storage (controller + Hive) mitigates
- **10-turn limit edge cases** → UI must handle `isLastTurn` even if turnNumber < 10

## Security Considerations

- sessionToken never logged or exposed in UI
- User input sanitized before sending to API

## Next Steps

→ Phase 04: Scenario Gift Screen
