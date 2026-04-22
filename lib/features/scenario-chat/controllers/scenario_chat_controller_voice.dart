part of 'scenario_chat_controller.dart';

// Voice input methods for ScenarioChatController.
// Declared as a library part so it has access to private helpers
// (_sendAudioForTranscription, etc.) in scenario_chat_controller.dart.

extension ScenarioChatControllerVoice on ScenarioChatController {
  Future<void> startRecording() async {
    if (completed.value) return;
    await _voiceInputService.startVoiceInput(language: _targetLanguage);
  }

  Future<void> stopRecording() async {
    final result = await _voiceInputService.stopVoiceInput();
    if (result.transcribedText.isNotEmpty) {
      await sendText(result.transcribedText);
      // iOS: fire-and-forget backend transcription for better accuracy
      if (result.audioFilePath != null) {
        _sendAudioForTranscription(result.audioFilePath!);
      }
    }
  }

  Future<void> cancelRecording() async {
    await _voiceInputService.cancelVoiceInput();
  }

  /// Uploads captured audio to /ai/transcribe and replaces the last user
  /// message text with the more-accurate backend transcription. Best-effort.
  Future<void> _sendAudioForTranscription(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath, filename: 'voice.m4a'),
        if (conversationId != null) 'conversation_id': conversationId,
      });
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.transcribeAudio,
        data: formData,
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        final accurate = response.data!['text'] as String?;
        if (accurate != null && accurate.isNotEmpty) {
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
      // Silent fail — STT text already sent; backend transcription is best-effort.
    }
  }
}
