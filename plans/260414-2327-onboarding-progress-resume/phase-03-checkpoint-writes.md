# Phase 03 — Checkpoint Writes & Controller Hydration

## Context Links
- Depends on: Phase 01, 02
- Files: `onboarding_controller.dart`, `ai_chat_controller.dart`

## Overview
- **Priority:** High
- **Status:** completed (2026-04-15)
- Wire progress writes at every checkpoint. Hydrate controller state from progress on init so resume screens show prior selections. Migrate legacy `onboarding_conversation_id` preference into the unified progress map.

## Key Insights
- Writes must happen BEFORE navigation so a kill-switch mid-transition still persists.
- Existing standalone `onboarding_conversation_id` preference (used in `ai_chat_controller.dart:79, 155`) is replaced by progress map. Add one-shot migration on service init.
- Scenario-gift resume: controller detects missing `onboardingProfile`, re-calls `complete()` with stored `conversationId`. Accepts the duplicate LLM cost as trade-off for simplicity.

## Requirements
**Functional**
- Write `native_lang` on language select (before nav).
- Write `learning_lang` on language select (before nav).
- Write `chat.conversation_id` immediately after session creation.
- Write `profile_complete = true` on successful `/onboarding/complete`.
- On `OnboardingController.onInit()`: hydrate `selectedNativeLanguage` + `selectedLearningLanguage` from progress.
- On `AiChatController.onInit()`: if progress has conversationId, use it; backend 404 → clear chat checkpoint, start fresh.
- Migrate legacy preference key (run once).

**Non-functional**
- Writes await completion so crashes don't lose data.

## Architecture

```
Write points:
  NativeLanguageScreen.onTap      → OnboardingController.selectNativeLanguage
                                    → progressSvc.setNativeLang  → nav
  LearningLanguageScreen.onTap    → OnboardingController.selectLearningLanguage
                                    → progressSvc.setLearningLang → nav
  AiChatController._startSession  → progressSvc.setChatConversationId
  AiChatController._onComplete    → progressSvc.setProfileComplete
  AiChatController (invalid id)   → progressSvc.clearChat + start new
```

## Related Code Files
**Modify:**
- `lib/features/onboarding/controllers/onboarding_controller.dart`
- `lib/features/chat/controllers/ai_chat_controller.dart`
- `lib/features/onboarding/bindings/onboarding_binding.dart`

**Read for context:**
- `lib/features/onboarding/views/native_language_screen.dart`
- `lib/features/onboarding/views/learning_language_screen.dart`
- `lib/features/onboarding/views/scenario_gift_screen.dart`

## Implementation Steps

1. **OnboardingController** — hydrate on init:
   ```dart
   @override
   void onInit() {
     super.onInit();
     _hydrateFromProgress();
     loadLanguages();
   }

   void _hydrateFromProgress() {
     final p = Get.find<OnboardingProgressService>().read();
     if (p.nativeLang != null) {
       selectedNativeLanguage.value = p.nativeLang!.code;
       selectedNativeLanguageId = p.nativeLang!.id;
     }
     if (p.learningLang != null) {
       selectedLearningLanguage.value = p.learningLang!.code;
       selectedLearningLanguageId = p.learningLang!.id;
     }
     if (p.chat != null) conversationId = p.chat!.conversationId;
   }
   ```

2. **OnboardingController.selectNativeLanguage** — write before nav:
   ```dart
   void selectNativeLanguage(String code, {String? id}) async {
     selectedNativeLanguage.value = code;
     selectedNativeLanguageId = id;
     await Get.find<OnboardingProgressService>().setNativeLang(code, id: id);
     _navigationTimer?.cancel();
     _navigationTimer = Timer(const Duration(milliseconds: 50), () {
       Get.toNamed(AppRoutes.onboardingLearningLanguage);
     });
   }
   ```
   Same pattern for `selectLearningLanguage`.

3. **AiChatController** — replace standalone preference with progress service:
   - At line 79: `progressSvc.setChatConversationId(_conversationId!)` (replaces `setPreference('onboarding_conversation_id', ...)`)
   - At line 155: `progressSvc.clearChat()` (replaces null-write)
   - On mount, if `_conversationId` null, read from progress map (not legacy key after migration).
   - On first chat call, if backend 404 → call `progressSvc.clearChat()` + restart session.
   - On `/onboarding/complete` success → `progressSvc.setProfileComplete()` AND cache scenarios in `onboardingCtrl.onboardingProfile` (existing field).

4. **Scenario Gift resume** — `ScenarioGiftScreen` / controller:
   - On mount, if `onboardingCtrl.onboardingProfile == null` but progress shows `profileComplete`:
     - Call `AiChatController.refetchProfile()` → re-POSTs `/onboarding/complete` with stored `conversationId` → stores result in `onboardingProfile`.
   - UI shows `LoadingWidget` during refetch.

5. **Migration** — one-shot in `OnboardingProgressService.init()`:
   ```dart
   Future<OnboardingProgressService> init() async {
     final legacy = _storage.getPreference<String>('onboarding_conversation_id');
     if (legacy != null && legacy.isNotEmpty) {
       final current = read();
       if (current.chat == null) {
         await setChatConversationId(legacy);
       }
       await _storage.removePreference('onboarding_conversation_id');
     }
     return this;
   }
   ```
   Register with `Get.putAsync(() => OnboardingProgressService().init(), permanent: true)`.

6. **Compile check:** `flutter analyze lib/features/onboarding lib/features/chat/controllers/ai_chat_controller.dart`

## Todo List
- [x] Add `_hydrateFromProgress()` in `OnboardingController.onInit()`
- [x] Write `native_lang` in `selectNativeLanguage`
- [x] Write `learning_lang` in `selectLearningLanguage`
- [x] Replace standalone `onboarding_conversation_id` preference with progress in `AiChatController`
- [x] Write `profile_complete` on `/onboarding/complete` success
- [x] Handle 404 on chat → `clearChat()` + restart (existing `_clearSession` now calls `progressSvc.clearChat()`)
- [x] Add scenario-gift refetch path (`refetchProfileIfNeeded` + Obx loading in screen)
- [x] Add legacy-key migration in service `init()`
- [x] Register service (`Get.put` + awaited `init()` in `initializeServices`)
- [x] Run `flutter analyze`

## Success Criteria
- Kill app after native-lang select → reopen → learning-lang screen (with native already set).
- Kill app after learning-lang select → reopen → chat screen.
- Kill app after scenario-gift reached → reopen → scenario-gift with scenarios re-displayed.
- Legacy `onboarding_conversation_id` preference cleared after migration.
- Invalid conversationId on resume → fresh chat session starts without user intervention.

## Risk Assessment
- **Risk:** Double `/onboarding/complete` calls burn LLM tokens. **Mitigation:** Accepted; flag in README. Rate-limiting via existing `OnboardingThrottlerGuard` on backend.
- **Risk:** Scenario UUIDs differ between original and refetch → breaks navigation if scenario_id is used in URL. **Mitigation:** Audit scenario-gift nav; if UUID-dependent, add post-MVP backend cache.
- **Risk:** Writing progress before nav causes perceptible delay. **Mitigation:** Hive writes are fast (<10ms); await is fine on UI thread.

## Security Considerations
- No additional exposure — same data already persisted under legacy key.

## Next Steps
- Phase 04 adds local chat message cache for true "continue chat with visible history."
