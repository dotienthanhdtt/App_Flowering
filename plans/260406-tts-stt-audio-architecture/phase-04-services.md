# Phase 4: Services (TtsService + VoiceInputService)

## Context Links

- [Brainstorm](../reports/brainstorm-260406-tts-stt-audio-architecture.md)
- [Phase 3](./phase-03-concrete-providers.md)

## Overview

- **Priority:** P1
- **Status:** Complete
- **Effort:** 3h
- **Description:** Create GetxService wrappers that orchestrate providers, manage state, handle platform differences, and expose reactive observables for UI binding.

## Key Insights

- Services are GetxService (permanent, singleton) — providers are injected via Get.find()
- TtsService needs a queue: multiple AI messages may arrive before first finishes speaking
- VoiceInputService needs platform detection: `Platform.isIOS` vs `Platform.isAndroid`
- TTS must stop before STT starts (audio session conflict on both platforms)
- 55s safety timeout for iOS STT (Apple hard limit is 60s)

## Requirements

### Functional

#### TtsService
- Queue-based speaking (FIFO)
- Auto-play new messages (when settings enabled)
- Stop/pause/resume control
- Rate/pitch from Hive preferences
- Observable: `isSpeaking`, `currentText`
- `stopForVoiceInput()` — called by VoiceInputService before starting

#### VoiceInputService
- Platform-aware: iOS = STT + recording, Android = STT only
- Live partial text updates via observable
- 55s timeout with auto-stop
- Returns `VoiceInputResult` on completion
- Observable: `isListening`, `partialText`, `amplitude`
- Stops TTS before starting (call `TtsService.stopForVoiceInput()`)

### Non-functional

- Each service under 180 lines
- Proper `onClose()` cleanup
- Error events logged, not swallowed
- Settings stored in Hive `preferences` box via StorageService

## Related Code Files

### Files to Create

| File | Purpose |
|------|---------|
| `lib/core/services/audio/tts-service.dart` | TTS orchestration GetxService |
| `lib/core/services/audio/voice-input-service.dart` | Voice input orchestration GetxService |

### Dependencies

- Phase 2 contracts
- Phase 3 providers
- `lib/core/services/storage_service.dart` (Hive preferences)

## Implementation Steps

### 4.1 TtsService

1. Create `tts-service.dart` extending `GetxService`
2. Inject `TtsProviderContract` via `Get.find()`
3. `init()`:
   - Call provider `initialize()`
   - Load settings from Hive preferences: `tts_auto_play` (bool), `tts_rate` (double), `tts_pitch` (double)
   - Apply rate/pitch to provider
   - Listen to provider `eventStream`:
     - On `complete` → dequeue, speak next if any
     - On `error` → log, dequeue, continue
4. `speak(String text, {String? language, String? messageId})`:
   - Add to queue `_speakQueue`
   - If not currently speaking, start speaking first in queue
5. `stopForVoiceInput()`:
   - Stop current speech
   - Clear queue
   - Used by VoiceInputService
6. `stop()`, `pause()`, `resume()` — delegate to provider
7. Settings methods:
   - `setAutoPlay(bool)` — save to Hive
   - `setRate(double)` — save to Hive + apply to provider
   - `setPitch(double)` — save to Hive + apply to provider
   - `get autoPlayEnabled` — read from Hive
8. Observable state:
   ```dart
   final isSpeaking = false.obs;
   final currentText = ''.obs;
   ```
9. `onClose()`: provider.dispose(), clear queue

### 4.2 VoiceInputService

1. Create `voice-input-service.dart` extending `GetxService`
2. Inject: `SttProviderContract`, `AudioRecorderProviderContract`, `TtsService`
3. `init()`:
   - Call sttProvider `initialize()` — store `_sttAvailable` flag
   - Check recorder permission
4. `startVoiceInput({String? language})`:
   - Stop TTS: `_ttsService.stopForVoiceInput()`
   - Start STT: provider `startListening(language: language)`
   - Listen to `resultStream` → update `partialText.value`
   - If iOS: also start recorder → listen to `amplitudeStream` → update `amplitude.value`
   - Start 55s timeout timer
5. `stopVoiceInput()`:
   - Cancel timeout timer
   - Stop STT → capture final text
   - If iOS: stop recorder → capture audio file path
   - Return `VoiceInputResult(transcribedText, audioFilePath, isPartial: false)`
6. `cancelVoiceInput()`:
   - Cancel timeout, stop STT, cancel recorder
   - Reset state
7. Timeout handler:
   - At 55s → auto-call `stopVoiceInput()`
   - Emit warning event (UI can show "time limit reached")
8. Observable state:
   ```dart
   final isListening = false.obs;
   final partialText = ''.obs;
   final amplitude = 0.0.obs;
   final sttAvailable = false.obs;
   ```
9. `onClose()`: dispose providers, cancel timers

### Platform Detection

```dart
import 'dart:io' show Platform;

bool get _canRecordDuringSTT => Platform.isIOS;
```

## Todo List

- [ ] Create tts-service.dart with queue, settings, observables
- [ ] Create voice-input-service.dart with platform logic, timeout, observables
- [ ] Verify both services compile with flutter analyze
- [ ] Ensure TTS stops before STT starts
- [ ] Verify 55s timeout works correctly

## Success Criteria

- TtsService queues and plays messages sequentially
- VoiceInputService detects platform and runs appropriate flow
- TTS stops when voice input starts
- 55s timeout auto-stops STT
- Observable state updates correctly for UI binding
- Each file under 180 lines
- Proper onClose() cleanup

## Risk Assessment

- **Race condition:** TTS stop + STT start must be sequential, not concurrent. Use `await` on stop before start
- **Queue memory:** Clear queue on dispose. Queue max 10 items to prevent memory buildup
- **Settings read/write:** Use StorageService for Hive access, not raw Hive

## Next Steps

- Phase 5: Wire into DI, remove old AudioService
