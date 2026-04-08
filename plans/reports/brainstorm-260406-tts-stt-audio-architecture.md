# Brainstorm: TTS + STT Audio Architecture for Flowering

**Date:** 2026-04-06
**Status:** Agreed — ready for implementation planning
**Packages:** `flutter_tts: ^4.2.5`, `speech_to_text: ^7.3.0`, `record: ^6.2.0` (existing)

---

## Problem Statement

Flowering needs two audio capabilities for AI chat:
1. **TTS** — Play AI message text aloud (language learning = hearing pronunciation)
2. **STT** — Transcribe user voice input to text (+ send audio to backend for accurate transcription)

Current state: `AudioService` exists with recording (`record`) and playback (`audioplayers`), but TTS and STT are TODO placeholders. No abstract service interfaces exist in the codebase.

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Service structure | Remove old AudioService → new **TtsService** + **VoiceInputService** | Single-responsibility; old service mixed concerns |
| Abstraction level | Abstract provider interfaces + concrete implementations | Swap local → cloud APIs without touching services |
| STT approach | **Hybrid**: live STT for instant text + backend transcription for accuracy | Best UX for language learning |
| Android mic conflict | STT-only on Android (no recording); full hybrid on iOS | `speech_to_text` + `record` can't share mic on Android |
| TTS trigger | Auto-play new AI messages + tap to replay | Language learning benefits from hearing every response |
| Future-proofing | Interfaces support both local and cloud providers | May switch to Google Cloud TTS / Whisper later |

---

## Architecture

### File Structure

```
lib/core/services/audio/
├── contracts/
│   ├── tts-provider-contract.dart              # Abstract TTS interface
│   ├── stt-provider-contract.dart              # Abstract STT interface
│   └── audio-recorder-provider-contract.dart   # Abstract recorder interface
├── providers/
│   ├── flutter-tts-provider.dart               # flutter_tts ^4.2.5 impl
│   ├── speech-to-text-provider.dart            # speech_to_text ^7.3.0 impl
│   └── record-audio-provider.dart              # record ^6.2.0 impl
├── models/
│   ├── tts-event.dart                          # TtsEvent enum/class
│   ├── stt-result.dart                         # SttResult (text, isFinal, confidence)
│   └── voice-input-result.dart                 # VoiceInputResult (text, audioPath?, isPartial)
├── tts-service.dart                            # GetxService: TTS orchestration + queue
└── voice-input-service.dart                    # GetxService: STT + recording orchestration
```

### Abstract Contracts

#### TtsProviderContract
```dart
abstract class TtsProviderContract {
  Future<void> initialize();
  Future<void> speak(String text, {String? language});
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> setLanguage(String language);
  Future<void> setRate(double rate);       // 0.0 - 1.0
  Future<void> setPitch(double pitch);     // 0.5 - 2.0
  bool get isSpeaking;
  Stream<TtsEvent> get eventStream;        // start, complete, error, progress
  void dispose();
}
```

#### SttProviderContract
```dart
abstract class SttProviderContract {
  Future<bool> initialize();
  Future<void> startListening({String? language, Function(SttResult)? onResult});
  Future<void> stopListening();
  Future<void> cancel();
  bool get isListening;
  Stream<SttResult> get resultStream;      // partial + final results
  Future<List<String>> getAvailableLanguages();
  void dispose();
}
```

#### AudioRecorderProviderContract
```dart
abstract class AudioRecorderProviderContract {
  Future<bool> hasPermission();
  Future<void> startRecording();
  Future<String?> stopRecording();         // returns file path
  Future<void> cancelRecording();
  bool get isRecording;
  Stream<double> get amplitudeStream;      // 0.0-1.0 for waveform UI
  void dispose();
}
```

### Service Layer

#### TtsService (GetxService)
- Wraps `TtsProviderContract` (injected via DI)
- **Auto-play queue**: new AI messages queued, played sequentially
- **Settings**: auto-play toggle, rate, pitch — stored in Hive `preferences` box
- **Stop on user action**: stop TTS when user starts voice input
- Observable state: `isSpeaking`, `currentMessageId`

#### VoiceInputService (GetxService)
- Wraps `SttProviderContract` + `AudioRecorderProviderContract`
- **Platform-aware orchestration**:
  - iOS: start STT + recording in parallel
  - Android: start STT only (no recording)
- **55s safety timeout** for Apple STT limit
- Returns `VoiceInputResult { transcribedText, audioFilePath?, isPartial }`
- Observable state: `isListening`, `partialText`, `amplitude`

### Platform-Specific Flows

#### iOS (Full Hybrid)
```
User holds mic
  ├─ Start speech_to_text (live partial results)
  └─ Start record (capture audio file)
User releases
  ├─ Stop STT → final text
  ├─ Stop recording → audio file path
  └─ Return VoiceInputResult(text, audioPath)
       │
Controller receives result:
  ├─ 1. Show STT text as user message (instant)
  ├─ 2. Send audio file to POST /ai/transcribe
  └─ 3. Replace message text with accurate transcription
```

#### Android (STT Only)
```
User holds mic
  └─ Start speech_to_text (live partial results)
User releases
  └─ Stop STT → final text
       └─ Return VoiceInputResult(text, null)
              │
Controller receives result:
  └─ Show STT text as user message (final)
     (No audio file → no backend transcription)
```

#### TTS Auto-Play
```
New AI message received
  ├─ Display in bubble
  ├─ Check settings: autoPlayTts == true?
  │   └─ Yes → TtsService.speak(text, language: targetLang)
  │             └─ Queue if already speaking another message
  └─ Speaker icon on bubble
        └─ Tap → TtsService.speak(text) (replay)
```

### Dependency Registration

```dart
// global-dependency-injection-bindings.dart
// Replace old AudioService with:
Get.lazyPut<TtsProviderContract>(() => FlutterTtsProvider(), fenix: true);
Get.lazyPut<SttProviderContract>(() => SpeechToTextProvider(), fenix: true);
Get.lazyPut<AudioRecorderProviderContract>(() => RecordAudioProvider(), fenix: true);
Get.lazyPut<TtsService>(() => TtsService(), fenix: true);
Get.lazyPut<VoiceInputService>(() => VoiceInputService(), fenix: true);
```

### Init Order Update
```
AuthStorage → StorageService → ConnectivityService → TtsService → VoiceInputService → ApiClient
```

---

## Backend Endpoint Required

```
POST /ai/transcribe
Content-Type: multipart/form-data
Body: { audio: File (AAC-LC), language: String }
Response: { code: 1, message: "Success", data: { text: "transcribed text", confidence: 0.95 } }
```

### API Endpoint Constant
```dart
// api_endpoints.dart
static const String transcribeAudio = '/ai/transcribe';
```

---

## Dependencies to Add

```yaml
# pubspec.yaml additions
flutter_tts: ^4.2.5
speech_to_text: ^7.3.0

# Keep existing
record: ^6.2.0
audioplayers: ^5.2.1   # May still be useful for audio file playback
```

### iOS Info.plist
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Flowering uses speech recognition to transcribe your voice messages</string>
<key>NSMicrophoneUsageDescription</key>
<string>Flowering needs microphone access to record voice messages</string>
```

### Android AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<!-- speech_to_text queries -->
<queries>
  <intent>
    <action android:name="android.speech.RecognitionService" />
  </intent>
</queries>
```

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Apple 60s STT limit | Medium | 55s safety timeout + auto-stop with UI warning |
| Android 5s silence auto-stop | Low | Document behavior; partial results still captured |
| Audio session conflicts (TTS + STT) | Medium | TtsService.stop() before VoiceInputService.start() |
| Memory leaks from streams | Medium | Proper dispose() in providers + onClose() in services |
| No STT available on device | Low | Check `initialize()` return; fallback to manual text input |
| Network required for backend transcription | Low | STT text is primary; backend is enhancement |

---

## Future Swap Examples

### Swap to Google Cloud TTS
```dart
class GoogleCloudTtsProvider implements TtsProviderContract {
  // HTTP calls to Google Cloud TTS API
  // Returns audio bytes → play with audioplayers
}

// In DI:
Get.lazyPut<TtsProviderContract>(() => GoogleCloudTtsProvider(apiKey: '...'));
```

### Swap to OpenAI Whisper STT
```dart
class WhisperSttProvider implements SttProviderContract {
  // Record audio → send to Whisper API → return text
  // No live partial results (batch only)
}
```

---

## Files to Modify

| File | Action |
|------|--------|
| `lib/core/services/audio_service.dart` | **DELETE** (replaced by new services) |
| `lib/app/global-dependency-injection-bindings.dart` | Update DI registrations |
| `lib/features/chat/controllers/ai_chat_controller.dart` | Wire TTS auto-play + voice input |
| `lib/features/chat/widgets/ai_message_bubble.dart` | Wire speaker icon to TtsService |
| `lib/features/chat/widgets/user_message_bubble.dart` | Show partial → final text transition |
| `lib/core/constants/api_endpoints.dart` | Add transcribe endpoint |
| `pubspec.yaml` | Add flutter_tts, speech_to_text |
| `ios/Runner/Info.plist` | Add speech recognition permission |
| `android/app/src/main/AndroidManifest.xml` | Add speech recognition queries |
| `lib/l10n/*.dart` | Add TTS/STT related translation keys |

## Files to Create

| File | Purpose |
|------|---------|
| `lib/core/services/audio/contracts/tts-provider-contract.dart` | Abstract TTS interface |
| `lib/core/services/audio/contracts/stt-provider-contract.dart` | Abstract STT interface |
| `lib/core/services/audio/contracts/audio-recorder-provider-contract.dart` | Abstract recorder interface |
| `lib/core/services/audio/providers/flutter-tts-provider.dart` | flutter_tts implementation |
| `lib/core/services/audio/providers/speech-to-text-provider.dart` | speech_to_text implementation |
| `lib/core/services/audio/providers/record-audio-provider.dart` | record package implementation |
| `lib/core/services/audio/models/tts-event.dart` | TTS event model |
| `lib/core/services/audio/models/stt-result.dart` | STT result model |
| `lib/core/services/audio/models/voice-input-result.dart` | Voice input result model |
| `lib/core/services/audio/tts-service.dart` | TTS GetxService |
| `lib/core/services/audio/voice-input-service.dart` | Voice input GetxService |

---

## Success Criteria

- [ ] AI messages auto-play TTS on receive (with settings toggle)
- [ ] User can tap speaker icon to replay any AI message
- [ ] User can hold mic → see live partial transcription → release → text sent as message
- [ ] iOS: audio file captured and sent to backend for accurate transcription
- [ ] Android: STT text used directly (no audio file)
- [ ] TTS stops when user starts voice input
- [ ] 55s timeout on STT prevents Apple hard limit
- [ ] All providers swappable via DI without touching services/controllers
- [ ] No memory leaks (streams properly disposed)
- [ ] Permissions handled gracefully with fallback to text input

---

## Next Steps

1. Create implementation plan with phased approach
2. Phase 1: Contracts + models + providers (no UI changes)
3. Phase 2: Services (TtsService, VoiceInputService)
4. Phase 3: Wire into chat UI (auto-play, voice input button)
5. Phase 4: Backend `/ai/transcribe` endpoint
6. Phase 5: Settings (auto-play toggle, rate, pitch)
7. Phase 6: Testing + edge cases
