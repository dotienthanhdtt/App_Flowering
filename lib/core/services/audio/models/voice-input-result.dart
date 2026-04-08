class VoiceInputResult {
  final String transcribedText;
  final String? audioFilePath;
  final bool isPartial;

  const VoiceInputResult({
    required this.transcribedText,
    this.audioFilePath,
    this.isPartial = false,
  });
}
