# Phase 3: Concrete Providers

## Context Links

- [Brainstorm](../reports/brainstorm-260406-tts-stt-audio-architecture.md)
- [Phase 2](./phase-02-abstract-contracts.md)
- [Researcher Report](../reports/researcher-flutter-audio-packages-api-surface.md)

## Overview

- **Priority:** P1
- **Status:** Complete
- **Effort:** 3h
- **Description:** Implement concrete providers wrapping flutter_tts, speech_to_text, and record packages behind the abstract contracts.

## Key Insights

- `flutter_tts` uses handler callbacks (setStartHandler, setCompletionHandler) → convert to StreamController
- `speech_to_text` uses `onResult` callback with `SpeechRecognitionResult` → map to `SttResult`
- `record` package already used in existing AudioService → extract and wrap in contract
- Each provider is a plain Dart class (NOT a GetxService) — services wrap them

## Requirements

### Functional

- `FlutterTtsProvider implements TtsProviderContract`
- `SpeechToTextProvider implements SttProviderContract`
- `RecordAudioProvider implements AudioRecorderProviderContract`

### Non-functional

- Each provider under 150 lines
- Proper `dispose()`: close StreamControllers, release native resources
- Error handling: wrap package exceptions, emit error events via streams
- No GetX dependency in providers (pure Dart)

## Related Code Files

### Files to Create

| File | Purpose |
|------|---------|
| `lib/core/services/audio/providers/flutter-tts-provider.dart` | flutter_tts wrapper |
| `lib/core/services/audio/providers/speech-to-text-provider.dart` | speech_to_text wrapper |
| `lib/core/services/audio/providers/record-audio-provider.dart` | record package wrapper |

### Reference Files

| File | Why |
|------|-----|
| `lib/core/services/audio_service.dart` | Extract recording logic from existing service |

## Implementation Steps

### 3.1 FlutterTtsProvider

1. Create `flutter-tts-provider.dart`
2. Initialize `FlutterTts` instance in `initialize()`
3. Map flutter_tts handlers to `StreamController<TtsEvent>`:
   - `setStartHandler` → `TtsEvent(type: start)`
   - `setCompletionHandler` → `TtsEvent(type: complete)`
   - `setErrorHandler` → `TtsEvent(type: error, errorMessage: ...)`
   - `setProgressHandler` → `TtsEvent(type: progress, startOffset, endOffset)`
   - `setPauseHandler` → `TtsEvent(type: pause)`
   - `setContinueHandler` → `TtsEvent(type: resume)`
   - `setCancelHandler` → `TtsEvent(type: cancel)`
4. `speak()`: call `flutterTts.speak(text)`, set language before if provided
5. `setRate()`: flutter_tts expects 0.0-1.0, map directly
6. `setPitch()`: flutter_tts expects 0.5-2.0, map directly
7. `dispose()`: `flutterTts.stop()`, close StreamController

### 3.2 SpeechToTextProvider

1. Create `speech-to-text-provider.dart`
2. `initialize()`: call `speechToText.initialize(onError: ..., onStatus: ...)`
   - Return false if not available
3. `startListening()`:
   ```dart
   speechToText.listen(
     onResult: (result) => _resultController.add(SttResult(
       text: result.recognizedWords,
       isFinal: result.finalResult,
       confidence: result.confidence,
     )),
     localeId: language,
     listenMode: ListenMode.dictation,
     cancelOnError: false,
     partialResults: true,
   );
   ```
4. `stopListening()`: `speechToText.stop()`
5. `cancel()`: `speechToText.cancel()`
6. `getAvailableLanguages()`: map `speechToText.locales()` to list of locale IDs
7. `dispose()`: stop listening, close StreamController

### 3.3 RecordAudioProvider

1. Create `record-audio-provider.dart`
2. Extract recording logic from existing `audio_service.dart`:
   - Permission check: `AudioRecorder().hasPermission()`
   - Start recording: configure AAC-LC, 128kbps, 44.1kHz, temp directory path
   - Amplitude polling: Timer.periodic(100ms), normalize dB to 0.0-1.0
   - Stop: return file path
   - Cancel: stop + delete temp file
3. `amplitudeStream`: StreamController fed by amplitude polling timer
4. `dispose()`: cancel timer, close recorder, close StreamController

## Todo List

- [ ] Create flutter-tts-provider.dart with TtsProviderContract implementation
- [ ] Create speech-to-text-provider.dart with SttProviderContract implementation
- [ ] Create record-audio-provider.dart with AudioRecorderProviderContract implementation
- [ ] Verify all 3 providers compile with flutter analyze
- [ ] Ensure dispose() properly cleans up all resources in each provider

## Success Criteria

- All 3 providers implement their respective contracts
- Each file under 150 lines
- No GetX imports in provider files
- StreamControllers properly closed in dispose()
- Amplitude normalization matches existing AudioService behavior (0.0-1.0 range)

## Risk Assessment

- **flutter_tts Android pause:** Only works on SDK 26+. `pause()` should be no-op on older versions
- **speech_to_text initialization failure:** Some devices lack speech recognition. `initialize()` returns false → service must handle gracefully
- **Recording temp files:** Ensure temp directory cleanup on cancel

## Security Considerations

- Audio files stored in temp directory only — auto-cleaned by OS
- No audio data persisted to Hive or permanent storage
- Permission requests show user-facing description strings

## Next Steps

- Phase 4: Services wrap these providers with GetX state management
