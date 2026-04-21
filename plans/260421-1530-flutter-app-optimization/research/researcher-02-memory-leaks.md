# Researcher 02 — Memory & Leak Report

Scope: controller disposal, stream/subscription cleanup, audio cleanup, Hive box lifecycle.

## Findings (ranked by leak severity)

### L1. `AiChatController` does not dispose in-flight work on close
- File: `lib/features/chat/controllers/ai_chat_controller.dart:532-537`
- `onClose()` disposes `scrollController` + `textEditingController` only.
- In-flight HTTP calls from `_checkGrammar`, `_sendAudioForTranscription`, `sendMessage` have no `CancelToken`. If the user backs out of the chat during a slow network, those futures still resolve and touch `messages` — after controller disposal this throws or silently no-ops (Rx is still alive until fenix GC).
- Grammar check and audio upload are fire-and-forget — swallowing errors masks this.
  - Fix: wire a `CancelToken` into all `apiCall`s; cancel in `onClose`.

### L2. `AudioService` listens to `AudioPlayer` globally but is a singleton
- `_stateSubscription`, `_positionSubscription`, `_durationSubscription` are correctly canceled in `onClose`.
- However, `onClose` is never called because `AudioService` is registered with `fenix: true` and `Get.put(permanent-ish)`. Acceptable since app-lifetime singleton, but document intent.

### L3. `VoiceInputService` leaks timeout timer if `cancelVoiceInput` is never called
- Subscriptions/timers are canceled in both `stopVoiceInput` and `cancelVoiceInput` — safe.
- Risk: if controller is disposed mid-recording without the user tapping stop/cancel, `_timeoutTimer` and `_durationTimer` would fire on a disposed service. Currently the service has app lifetime so benign, but make `onClose` defensive (already does cancel timers — OK).

### L4. `OnboardingController._navigationTimer` leak on quick re-entry
- File: `onboarding_controller.dart:137,148`
- Timer is created on select and canceled on new select or onClose. Acceptable.
- Minor: if user taps a language, navigation fires Timer, then onClose runs before the 50ms elapses — `Get.toNamed` inside a disposed controller's timer callback may throw on navigation mid-dispose. Low risk but defensive-code candidate.

### L5. `FloweringFeedController` + `ForYouFeedController` workers OK
- `_langWorker = ever(...)` disposed in onClose. Good.

### L6. `SubscriptionService._customerInfoSubscription` never canceled on logout
- File: `subscription-service.dart:93`
- Subscription is established in `init()`. Never re-listens after logout + login cycle. `onUserLoggedIn`/`onUserLoggedOut` do not touch the listener — OK since the listener filters by current state.
- Leak risk: if `RevenueCatService` is ever re-created (e.g., Get.delete), old listener holds old stream reference. Currently app-lifetime so safe. Documented as assumption in comment.

### L7. Hive boxes opened but never closed at app termination
- `StorageService.close()` exists but is not called anywhere. Hive holds file handles.
  - Impact: on iOS/Android, OS reclaims file handles at app kill — benign in practice.
  - Fix (low priority): wire `close()` into `WidgetsBindingObserver.didChangeAppLifecycleState(AppLifecycleState.detached)`.

### L8. `_langLessonBoxes` map grows unbounded
- File: `storage_service.dart:25,193`
- Each call to `getLessonsBoxFor(code)` opens a new Hive box and caches. Over many language switches this could open all language boxes simultaneously (one per language ~20 languages = 20 open boxes).
- Each open box holds an in-memory index. Not catastrophic but measurable.
  - Fix: close previous box when switching active language (keep only N=2 open: active + last-used).

### L9. `AuthController` form controllers correctly disposed — OK

### L10. `ScrollController` in ai_chat_screen — owned by controller and disposed. OK

### L11. `AudioService` `_currentRecordingPath` files not cleaned
- Recording files written to `getTemporaryDirectory()` and deleted on cancel. Stopped recordings intentionally persist (uploaded). But failed uploads leave files in tmp — OS cleans eventually but could accumulate.
  - Fix (low priority): sweep tmp files older than 1 hour on app start.

## Unresolved questions
- Whether `fenix: true` controllers rebind correctly when disposed+reopened mid-HTTP — untested path.
- Are all `Get.find<T>()` inside controllers resistant to the target service being unavailable during app shutdown?

## Priority ordering
- L1 (real data-integrity leak risk if backend slow) > L8 (memory creep, easy fix) > L11 (disk creep) > others (documentation only).
