# Phase 1: Dependencies + Permissions + Models

## Context Links

- [Brainstorm](../reports/brainstorm-260406-tts-stt-audio-architecture.md)
- [plan.md](./plan.md)

## Overview

- **Priority:** P1 (blocking all other phases)
- **Status:** Complete
- **Effort:** 1h
- **Description:** Add packages, configure platform permissions, create data models

## Key Insights

- iOS needs both `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription`
- Android needs `RECORD_AUDIO` permission and `RecognitionService` query intent
- Models are small, event-driven classes used across all providers/services

## Requirements

### Functional

- Add `flutter_tts: ^4.2.5` and `speech_to_text: ^7.3.0` to pubspec
- Configure iOS/Android permissions for mic + speech recognition
- Create 3 models: `TtsEvent`, `SttResult`, `VoiceInputResult`

### Non-functional

- Models must be immutable (final fields, const constructors where possible)
- Follow existing naming conventions (kebab-case files, PascalCase classes)

## Related Code Files

### Files to Modify

| File | Action |
|------|--------|
| `pubspec.yaml` | Add flutter_tts, speech_to_text deps |
| `ios/Runner/Info.plist` | Add NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription |
| `android/app/src/main/AndroidManifest.xml` | Add RECORD_AUDIO permission, RecognitionService query |
| `lib/core/constants/api_endpoints.dart` | Add `transcribeAudio` endpoint constant |

### Files to Create

| File | Purpose |
|------|---------|
| `lib/core/services/audio/models/tts-event.dart` | TTS lifecycle events |
| `lib/core/services/audio/models/stt-result.dart` | STT result with text, isFinal, confidence |
| `lib/core/services/audio/models/voice-input-result.dart` | Combined voice input result |

## Implementation Steps

1. Add to `pubspec.yaml` under dependencies:
   ```yaml
   flutter_tts: ^4.2.5
   speech_to_text: ^7.3.0
   ```
2. Run `flutter pub get`

3. Add to `ios/Runner/Info.plist` inside `<dict>`:
   ```xml
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>Flowering uses speech recognition to transcribe your voice messages</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Flowering needs microphone access to record voice messages</string>
   ```

4. Add to `android/app/src/main/AndroidManifest.xml`:
   - Permission: `<uses-permission android:name="android.permission.RECORD_AUDIO"/>`
   - Query intent inside `<queries>`:
     ```xml
     <intent>
       <action android:name="android.speech.RecognitionService" />
     </intent>
     ```

5. Create `lib/core/services/audio/models/tts-event.dart`:
   ```dart
   enum TtsEventType { start, complete, error, progress, pause, resume, cancel }
   
   class TtsEvent {
     final TtsEventType type;
     final String? text;        // text being spoken
     final int? startOffset;    // progress tracking
     final int? endOffset;
     final String? errorMessage;
     const TtsEvent({required this.type, this.text, this.startOffset, this.endOffset, this.errorMessage});
   }
   ```

6. Create `lib/core/services/audio/models/stt-result.dart`:
   ```dart
   class SttResult {
     final String text;
     final bool isFinal;
     final double confidence;  // 0.0 - 1.0
     const SttResult({required this.text, required this.isFinal, this.confidence = 0.0});
   }
   ```

7. Create `lib/core/services/audio/models/voice-input-result.dart`:
   ```dart
   class VoiceInputResult {
     final String transcribedText;
     final String? audioFilePath;  // null on Android (mic conflict)
     final bool isPartial;
     const VoiceInputResult({required this.transcribedText, this.audioFilePath, this.isPartial = false});
   }
   ```

8. Add to `api_endpoints.dart`:
   ```dart
   static const String transcribeAudio = '/ai/transcribe';
   ```

9. Run `flutter analyze` to verify no errors

## Todo List

- [ ] Add flutter_tts and speech_to_text to pubspec.yaml
- [ ] Run flutter pub get
- [ ] Add iOS permissions to Info.plist
- [ ] Add Android permissions to AndroidManifest.xml
- [ ] Create tts-event.dart model
- [ ] Create stt-result.dart model
- [ ] Create voice-input-result.dart model
- [ ] Add transcribeAudio endpoint constant
- [ ] Run flutter analyze — zero errors

## Success Criteria

- `flutter pub get` resolves without conflicts
- `flutter analyze` passes with no new errors
- All 3 model files compile and follow project conventions
- iOS/Android permission strings present

## Risk Assessment

- **Version conflict:** flutter_tts/speech_to_text may conflict with existing deps → resolve by checking compatibility first
- **Android minSdk:** speech_to_text requires minSdk 21 → verify in build.gradle

## Next Steps

- Phase 2: Abstract contracts (depends on models being ready)
