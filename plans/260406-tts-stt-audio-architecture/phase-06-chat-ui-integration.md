# Phase 6: Chat UI Integration

## Context Links

- [Brainstorm](../reports/brainstorm-260406-tts-stt-audio-architecture.md)
- [Phase 5](./phase-05-di-migration.md)
- Chat controller: `lib/features/chat/controllers/ai_chat_controller.dart`
- AI bubble: `lib/features/chat/widgets/ai_message_bubble.dart`

## Overview

- **Priority:** P1
- **Status:** Complete
- **Effort:** 2h
- **Description:** Wire TTS auto-play into AI message flow, implement voice input button with hold-to-record + live transcription, add speaker icon TTS replay.

## Key Insights

- `playAudio()` in controller is a TODO placeholder → implement with TtsService
- Speaker button already exists in `ai_message_bubble.dart` → just wire to TtsService
- Voice input UI needs: hold mic button, live partial text display, waveform/amplitude indicator
- Auto-play: trigger after AI message is added to messages list
- Translation keys needed for new UI states

## Requirements

### Functional

- **TTS Auto-Play:** When AI message received, auto-speak if settings enabled
- **TTS Replay:** Tap speaker icon on any AI bubble → speak that message
- **TTS Visual State:** Speaker icon shows playing state (animated/highlighted)
- **Voice Input:** Hold mic → live partial text → release → send message
- **Voice Input UI:** Show partial transcription above input bar while listening
- **Backend Transcription:** On iOS, send audio file to `/ai/transcribe` after voice input completes
- **Error States:** STT unavailable → show text input only, no mic button

### Non-functional

- No UI jank during TTS/STT transitions
- Mic button accessible and discoverable
- Add translation keys for all new user-facing strings

## Related Code Files

### Files to Modify

| File | Changes |
|------|---------|
| `lib/features/chat/controllers/ai_chat_controller.dart` | Implement playAudio(), add voice input methods, auto-play on message receive |
| `lib/features/chat/widgets/ai_message_bubble.dart` | Wire speaker to TtsService, show speaking state |
| `lib/features/chat/views/ai_chat_screen.dart` | Add voice input UI, partial text display |
| `lib/l10n/english-translations-en-us.dart` | Add TTS/STT keys |
| `lib/l10n/vietnamese-translations-vi-vn.dart` | Add TTS/STT keys |

### Possibly Modify

| File | If |
|------|-----|
| Chat input bar widget (find exact file) | If mic button lives there |
| `lib/features/chat/models/chat_message_model.dart` | If need `isSpeaking` state tracking |

## Implementation Steps

### 6.1 Controller: TTS Methods

1. Implement `playAudio(String messageId)`:
   ```dart
   void playAudio(String messageId) {
     final message = messages.firstWhere((m) => m.id == messageId);
     _ttsService.speak(message.text, language: _targetLanguage);
   }
   ```

2. Add auto-play in `_addAiMessage()` or wherever AI messages are added:
   ```dart
   if (_ttsService.autoPlayEnabled) {
     _ttsService.speak(message.text, language: _targetLanguage);
   }
   ```

3. Add `stopSpeaking()`:
   ```dart
   void stopSpeaking() => _ttsService.stop();
   ```

### 6.2 Controller: Voice Input Methods

1. Add `startVoiceInput()`:
   ```dart
   Future<void> startVoiceInput() async {
     await _voiceInputService.startVoiceInput(language: _targetLanguage);
   }
   ```

2. Add `stopVoiceInput()`:
   ```dart
   Future<void> stopVoiceInput() async {
     final result = await _voiceInputService.stopVoiceInput();
     if (result.transcribedText.isNotEmpty) {
       _sendMessage(result.transcribedText);
       // If audio file available (iOS), send to backend for accurate transcription
       if (result.audioFilePath != null) {
         _sendAudioForTranscription(result.audioFilePath!);
       }
     }
   }
   ```

3. Add `_sendAudioForTranscription(String filePath)`:
   - Fire-and-forget: upload audio to `/ai/transcribe`
   - On response: update last user message text with accurate transcription
   - On error: keep STT text (already sent)

4. Add `cancelVoiceInput()`:
   ```dart
   void cancelVoiceInput() => _voiceInputService.cancelVoiceInput();
   ```

### 6.3 AI Message Bubble: Speaking State

1. Pass `isSpeaking` state to `AiMessageBubble`:
   ```dart
   AiMessageBubble(
     // ... existing props
     isSpeaking: controller.ttsService.currentText.value == message.text,
     onPlayAudio: () => controller.playAudio(message.id),
   )
   ```

2. In bubble: highlight speaker icon when `isSpeaking` is true (change color/add animation)

### 6.4 Voice Input UI

1. In chat screen or input bar, add mic button:
   - `GestureDetector` with `onLongPressStart` → `startVoiceInput()`
   - `onLongPressEnd` → `stopVoiceInput()`
   - `onLongPressCancel` → `cancelVoiceInput()`

2. Show partial text overlay while listening:
   ```dart
   Obx(() => controller.voiceInputService.isListening.value
     ? _buildPartialTextOverlay(controller.voiceInputService.partialText.value)
     : const SizedBox.shrink()
   )
   ```

3. Show amplitude indicator (optional): waveform bars or pulsing circle based on `amplitude` observable

### 6.5 Translation Keys

Add to both l10n files:
```dart
'chat_listening': 'Listening...',
'chat_tap_to_speak': 'Hold to speak',
'chat_stt_unavailable': 'Voice input not available on this device',
'chat_stt_timeout': 'Recording time limit reached',
'chat_tts_auto_play': 'Auto-play messages',
'chat_transcribing': 'Transcribing...',
```

### 6.6 Error Handling

1. If `sttAvailable == false`:
   - Hide mic button
   - Show text-only input

2. If TTS `speak()` fails:
   - Log error
   - Don't crash — just skip that message

3. If backend transcription fails:
   - Keep STT text (already sent as message)
   - No user-facing error needed

## Todo List

- [ ] Implement playAudio() in AiChatController
- [ ] Add TTS auto-play on AI message receive
- [ ] Add voice input methods (start, stop, cancel) in controller
- [ ] Add backend audio transcription (fire-and-forget)
- [ ] Wire speaker icon speaking state in AiMessageBubble
- [ ] Add hold-to-speak mic button in chat input
- [ ] Add partial text overlay while listening
- [ ] Add translation keys (EN + VI)
- [ ] Handle STT unavailable state (hide mic)
- [ ] Run flutter analyze — zero errors

## Success Criteria

- AI messages auto-play on receive (when enabled)
- Speaker icon tap replays message
- Speaker icon shows visual feedback during playback
- Hold mic → see live partial text → release → message sent
- iOS: audio sent to backend, accurate text replaces STT text
- STT unavailable → mic button hidden, text input works normally
- All new strings translated (EN + VI)
- flutter analyze passes

## Risk Assessment

- **UI rebuild frequency:** `partialText` updates rapidly (~100ms). Use `Obx` carefully, isolate rebuilds
- **Long press vs tap conflict:** Ensure mic long press doesn't conflict with send button tap
- **Auto-play interruption:** If user starts typing while TTS is playing → stop TTS

## Security Considerations

- Audio files sent to backend via HTTPS only
- No audio stored permanently on device
- Mic permission request shows user-facing description

## Next Steps

- Run `flutter analyze` and `flutter test`
- Manual testing on iOS + Android devices
- Settings screen: add TTS auto-play toggle, rate, pitch sliders (future phase)
