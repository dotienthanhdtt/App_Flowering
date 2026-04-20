part of 'ai_chat_controller.dart';

// Voice input methods for AiChatController.
// Declared as extension within the same library part — has access to all
// library-private (`_`) identifiers defined in ai_chat_controller.dart.

extension AiChatControllerVoice on AiChatController {
  // ─────────────────────────────────────────────────────────────────
  // Voice Input
  // ─────────────────────────────────────────────────────────────────

  Future<void> startRecording() async {
    if (isChatComplete.value) return;
    await _voiceInputService.startVoiceInput(language: _targetLanguage);
  }

  Future<void> stopRecording() async {
    final result = await _voiceInputService.stopVoiceInput();
    if (result.transcribedText.isNotEmpty) {
      sendMessage(result.transcribedText);
      // iOS: fire-and-forget backend transcription for better accuracy
      if (result.audioFilePath != null) {
        _sendAudioForTranscription(result.audioFilePath!);
      }
    }
  }

  Future<void> cancelRecording() async {
    await _voiceInputService.cancelVoiceInput();
  }

  /// Fire-and-forget: upload audio to /ai/transcribe, update last user message if successful
  Future<void> _sendAudioForTranscription(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath, filename: 'voice.m4a'),
        if (_conversationId != null) 'conversation_id': _conversationId,
      });
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.transcribeAudio,
        data: formData,
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        final accurate = response.data!['text'] as String?;
        if (accurate != null && accurate.isNotEmpty) {
          // Update the last user message with accurate transcription
          for (int i = messages.length - 1; i >= 0; i--) {
            if (messages[i].type == ChatMessageType.userText) {
              messages[i].text = accurate;
              messages.refresh();
              break;
            }
          }
        }
      }
    } catch (_) {
      // Silent fail — STT text already sent, backend transcription is best-effort
    }
  }
}
