# Phase 5: DI + Migration (Remove Old AudioService)

## Context Links

- [Phase 4](./phase-04-services.md)
- Current DI: `lib/app/global-dependency-injection-bindings.dart` (104 lines)
- Old service: `lib/core/services/audio_service.dart` (283 lines)

## Overview

- **Priority:** P1
- **Status:** Complete
- **Effort:** 1.5h
- **Description:** Register new providers + services in DI, update init order, remove old AudioService, fix all references.

## Key Insights

- Old AudioService used in: `AiChatController` (recording proxy methods), `global-dependency-injection-bindings.dart`
- New services need init before ApiClient (TTS/STT don't depend on network for local providers)
- Providers registered by contract type (enables future swap)

## Requirements

### Functional

- Remove old `AudioService` registration and init
- Register 3 providers + 2 services in DI
- Update init order
- Find and update ALL references to old AudioService
- Delete `audio_service.dart`

### Non-functional

- App must compile and run after migration
- No broken imports anywhere

## Related Code Files

### Files to Modify

| File | Action |
|------|--------|
| `lib/app/global-dependency-injection-bindings.dart` | Replace AudioService with new providers + services |
| `lib/features/chat/controllers/ai_chat_controller.dart` | Replace `_audioService` with `_ttsService` + `_voiceInputService` |

### Files to Delete

| File | Reason |
|------|--------|
| `lib/core/services/audio_service.dart` | Replaced by new architecture |

## Implementation Steps

1. **Update `global-dependency-injection-bindings.dart`**:

   In `dependencies()` — replace AudioService registration:
   ```dart
   // Remove:
   Get.lazyPut(() => AudioService(), fenix: true);
   
   // Add:
   Get.lazyPut<TtsProviderContract>(() => FlutterTtsProvider(), fenix: true);
   Get.lazyPut<SttProviderContract>(() => SpeechToTextProvider(), fenix: true);
   Get.lazyPut<AudioRecorderProviderContract>(() => RecordAudioProvider(), fenix: true);
   Get.lazyPut(() => TtsService(), fenix: true);
   Get.lazyPut(() => VoiceInputService(), fenix: true);
   ```

   In `initializeServices()` — replace AudioService init:
   ```dart
   // Remove:
   final audioService = Get.find<AudioService>();
   await audioService.init();
   
   // Add:
   final ttsService = Get.find<TtsService>();
   await ttsService.init();
   final voiceInputService = Get.find<VoiceInputService>();
   await voiceInputService.init();
   ```

   Init order: AuthStorage → StorageService → ConnectivityService → **TtsService → VoiceInputService** → ApiClient

2. **Update `ai_chat_controller.dart`**:

   Replace injected service:
   ```dart
   // Remove:
   final AudioService _audioService = Get.find();
   
   // Add:
   final TtsService _ttsService = Get.find();
   final VoiceInputService _voiceInputService = Get.find();
   ```

   Replace proxy getters:
   ```dart
   // Remove old proxies:
   bool get isRecording => _audioService.isRecording.value;
   double get recordingAmplitude => _audioService.amplitude.value;
   // etc.
   
   // Add new proxies:
   bool get isListening => _voiceInputService.isListening.value;
   String get partialText => _voiceInputService.partialText.value;
   double get amplitude => _voiceInputService.amplitude.value;
   bool get isSpeaking => _ttsService.isSpeaking.value;
   ```

3. **Grep for remaining AudioService references**:
   ```bash
   grep -r "AudioService" lib/ --include="*.dart"
   ```
   Fix any remaining imports/references.

4. **Delete `lib/core/services/audio_service.dart`**

5. Run `flutter analyze` — zero errors

## Todo List

- [ ] Update DI registrations in global-dependency-injection-bindings.dart
- [ ] Update initializeServices() order
- [ ] Replace AudioService in ai_chat_controller.dart
- [ ] Grep and fix all remaining AudioService references
- [ ] Delete audio_service.dart
- [ ] Run flutter analyze — zero errors

## Success Criteria

- `flutter analyze` passes with zero errors
- No remaining imports of `audio_service.dart`
- App compiles successfully
- DI init order preserved (new services before ApiClient)

## Risk Assessment

- **Missed references:** Grep thoroughly. May be in test files or other controllers
- **Init order dependency:** TtsService needs StorageService (for settings). Ensure StorageService inits first

## Next Steps

- Phase 6: Wire TTS/STT into chat UI
