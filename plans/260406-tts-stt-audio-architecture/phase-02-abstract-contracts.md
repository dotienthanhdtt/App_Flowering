# Phase 2: Abstract Contracts

## Context Links

- [Brainstorm](../reports/brainstorm-260406-tts-stt-audio-architecture.md)
- [Phase 1](./phase-01-dependencies-permissions-models.md)

## Overview

- **Priority:** P1
- **Status:** Complete
- **Effort:** 1.5h
- **Description:** Create abstract provider interfaces that define the contract for TTS, STT, and audio recording implementations. These enable swapping providers (local ↔ cloud) without touching services.

## Key Insights

- Contracts use `Stream` for events (not callbacks) — consistent with GetX reactive patterns
- Keep interfaces minimal — only methods that ALL implementations must support
- `dispose()` required for cleanup (critical for memory leak prevention)
- Return types must be generic enough for both local and cloud providers

## Requirements

### Functional

- `TtsProviderContract`: speak, stop, pause, resume, language/rate/pitch config, event stream
- `SttProviderContract`: initialize, listen, stop, cancel, result stream, available languages
- `AudioRecorderProviderContract`: permission check, start/stop/cancel recording, amplitude stream

### Non-functional

- Pure abstract classes — no implementation logic
- Import only model files (no package dependencies in contracts)
- Each contract under 50 lines

## Related Code Files

### Files to Create

| File | Purpose |
|------|---------|
| `lib/core/services/audio/contracts/tts-provider-contract.dart` | Abstract TTS interface |
| `lib/core/services/audio/contracts/stt-provider-contract.dart` | Abstract STT interface |
| `lib/core/services/audio/contracts/audio-recorder-provider-contract.dart` | Abstract recorder interface |

### Dependencies

- `lib/core/services/audio/models/tts-event.dart` (Phase 1)
- `lib/core/services/audio/models/stt-result.dart` (Phase 1)

## Implementation Steps

1. Create `lib/core/services/audio/contracts/tts-provider-contract.dart`:
   ```dart
   abstract class TtsProviderContract {
     Future<void> initialize();
     Future<void> speak(String text, {String? language});
     Future<void> stop();
     Future<void> pause();
     Future<void> resume();
     Future<void> setLanguage(String language);
     Future<void> setRate(double rate);
     Future<void> setPitch(double pitch);
     bool get isSpeaking;
     Stream<TtsEvent> get eventStream;
     void dispose();
   }
   ```

2. Create `lib/core/services/audio/contracts/stt-provider-contract.dart`:
   ```dart
   abstract class SttProviderContract {
     Future<bool> initialize();
     Future<void> startListening({String? language});
     Future<void> stopListening();
     Future<void> cancel();
     bool get isListening;
     bool get isAvailable;
     Stream<SttResult> get resultStream;
     Future<List<String>> getAvailableLanguages();
     void dispose();
   }
   ```

3. Create `lib/core/services/audio/contracts/audio-recorder-provider-contract.dart`:
   ```dart
   abstract class AudioRecorderProviderContract {
     Future<bool> hasPermission();
     Future<bool> requestPermission();
     Future<void> startRecording();
     Future<String?> stopRecording();  // returns file path
     Future<void> cancelRecording();
     bool get isRecording;
     Stream<double> get amplitudeStream;  // 0.0-1.0
     void dispose();
   }
   ```

4. Run `flutter analyze`

## Todo List

- [ ] Create tts-provider-contract.dart
- [ ] Create stt-provider-contract.dart
- [ ] Create audio-recorder-provider-contract.dart
- [ ] Run flutter analyze — zero errors

## Success Criteria

- All 3 contracts compile without errors
- No package imports in contract files (only model imports)
- Each file under 50 lines
- Contracts cover all methods needed by services in Phase 4

## Risk Assessment

- **Over-abstraction:** Keep interfaces lean. Don't add methods "just in case"
- **Missing methods:** If Phase 3 providers need extra methods, add to contract first

## Next Steps

- Phase 3: Concrete providers implement these contracts
