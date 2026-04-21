part of 'ai_chat_controller.dart';

// Session lifecycle: bootstrap, rehydrate, create, retry, error mapping, completion.
extension AiChatControllerSession on AiChatController {
  /// Cold-resume aware session bootstrap. If a prior conversation exists in the
  /// progress map, rehydrate transcript from backend; otherwise start fresh.
  void _bootstrapSession() {
    final chatCheckpoint = _progressSvc.read().chat;
    if (chatCheckpoint != null) {
      _conversationId = chatCheckpoint.conversationId;
      _onboardingCtrl.conversationId = _conversationId;
      _rehydrateFromBackend();
    } else {
      _createSession();
    }
  }

  /// Fetches message history from the backend and populates the chat UI.
  /// On 404 (conversation dead / not yet migrated), falls back to a fresh
  /// session. On other errors, surfaces a retry affordance via [errorMessage].
  Future<void> _rehydrateFromBackend() async {
    final id = _conversationId;
    if (id == null) {
      await _createSession();
      return;
    }

    isTyping.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.onboardingConversationMessages(id),
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        _applyRehydratedTranscript(response.data!);
      } else {
        errorMessage.value = 'resume_chat_failed'.tr;
      }
    } on NotFoundException {
      // Conversation dead — clear local checkpoint and start fresh.
      await _progressSvc.clearChat();
      _conversationId = null;
      _onboardingCtrl.conversationId = null;
      await _createSession();
      return;
    } on ApiException catch (e) {
      // 404 is covered above; treat all other API errors as retryable network
      // issues so the user can recover without blowing away their progress.
      if (e.statusCode == 404) {
        await _progressSvc.clearChat();
        _conversationId = null;
        _onboardingCtrl.conversationId = null;
        await _createSession();
        return;
      }
      errorMessage.value = e.userMessage;
    } catch (_) {
      errorMessage.value = 'resume_chat_failed'.tr;
    } finally {
      isTyping.value = false;
    }
  }

  /// Populates observables from the `GET messages` response payload.
  ///
  /// Accepts both snake_case (`turn_number`, `is_last_turn`) and camelCase
  /// (`turnNumber`, `isLastTurn`) keys so we stay resilient to any last-mile
  /// API shape tweaks before backend lands.
  void _applyRehydratedTranscript(Map<String, dynamic> data) {
    final rawMessages = (data['messages'] as List<dynamic>? ?? const []);
    final parsed = rawMessages
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromServerJson)
        .toList();
    messages.assignAll(parsed);

    final turnNumber =
        (data['turn_number'] ?? data['turnNumber'] ?? 0) as int? ?? 0;
    final maxTurns =
        (data['max_turns'] ?? data['maxTurns'] ?? 10) as int? ?? 10;
    final isLastTurn =
        (data['is_last_turn'] ?? data['isLastTurn'] ?? false) as bool? ?? false;

    progress.value =
        maxTurns == 0 ? 0.0 : (turnNumber / maxTurns).clamp(0.0, 1.0);
    isChatComplete.value = isLastTurn;
    _scrollToBottom();
  }

  /// Creates the onboarding session via unified /onboarding/chat endpoint
  /// (Mode A — no conversationId). Response includes greeting + conversationId
  /// in a single round-trip.
  Future<void> _createSession() async {
    if (_langCtx.activeCode.value == null || _langCtx.activeCode.value!.isEmpty) {
      errorMessage.value = 'err_language_required'.tr;
      Get.offNamed(AppRoutes.onboardingLearningLanguage);
      return;
    }
    isTyping.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.post<OnboardingSession>(
        ApiEndpoints.onboardingChat,
        data: {
          'native_language': _onboardingCtrl.selectedNativeLanguage.value,
          'target_language': _langCtx.activeCode.value,
        },
        fromJson: (data) => OnboardingSession.fromJson(data as Map<String, dynamic>),
      );
      if (response.isSuccess && response.data != null) {
        final session = response.data!;
        _conversationId = session.conversationId;
        await _progressSvc.setChatConversationId(_conversationId!);
        _onboardingCtrl.conversationId = _conversationId;
        await _handleChatResponse(session);
      } else {
        errorMessage.value = response.message;
      }
    } on ApiException catch (e) {
      errorMessage.value = _mapOnboardingError(e, isCreate: true);
    } catch (_) {
      errorMessage.value = 'unknown_error'.tr;
    } finally {
      isTyping.value = false;
    }
  }

  /// Retry entry point used by the error banner. Picks rehydrate vs fresh
  /// session based on whether a prior conversationId is still persisted, so
  /// users mid-rehydrate on a flaky network don't lose their transcript.
  Future<void> retrySession() async {
    final hasCheckpoint = _progressSvc.read().chat != null;
    if (hasCheckpoint) {
      await _rehydrateFromBackend();
    } else {
      await _createSession();
    }
  }

  /// Maps onboarding API errors to user-facing copy.
  /// 429 differentiates create (5/hr) vs chat (30/hr) rate limits.
  /// 404 → invalid conversationId; 400 → expired or max turns reached.
  String _mapOnboardingError(ApiException e, {required bool isCreate}) {
    switch (e.statusCode) {
      case 429:
        return isCreate
            ? 'chat_rate_limit_create'.tr
            : 'chat_rate_limit_chat'.tr;
      case 404:
        _clearSession();
        return 'chat_session_invalid'.tr;
      case 400:
        _clearSession();
        return 'chat_session_expired'.tr;
      default:
        return e.userMessage;
    }
  }

  /// Clears local session state so the user can restart onboarding cleanly.
  void _clearSession() {
    _conversationId = null;
    _progressSvc.clearChat();
    _onboardingCtrl.conversationId = null;
    isChatComplete.value = false;
  }

  /// Shared handler for chat API responses — updates progress, adds AI message, handles completion.
  Future<void> _handleChatResponse(OnboardingSession session) async {
    progress.value = (session.turnNumber / 10).clamp(0.0, 1.0);
    _addAiMessage(session.reply ?? '', messageId: session.messageId);
    if (session.quickReplies.isNotEmpty) {
      _addQuickReplies(session.quickReplies);
    }
    if (session.isLastTurn) {
      await _completeOnboarding();
    }
  }
  Future<void> _completeOnboarding() async {
    isChatComplete.value = true;
    try {
      final response = await _apiClient.post<OnboardingProfile>(
        ApiEndpoints.onboardingComplete,
        data: {'conversation_id': _conversationId},
        fromJson: (data) => OnboardingProfile.fromJson(data as Map<String, dynamic>),
      );
      if (response.isSuccess && response.data != null) {
        _onboardingCtrl.onboardingProfile = response.data;
        // Persist completion: cold-resume after this point lands on scenario-gift.
        await _progressSvc.setProfileComplete(true);
      }
    } on ApiException {
      // Non-fatal: navigate regardless so user is not stuck
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      Get.offNamed(AppRoutes.onboardingScenarioGift);
    }
  }
}
