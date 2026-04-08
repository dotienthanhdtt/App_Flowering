enum TtsEventType { start, complete, error, progress, pause, resume, cancel }

class TtsEvent {
  final TtsEventType type;
  final String? text;
  final int? startOffset;
  final int? endOffset;
  final String? errorMessage;

  const TtsEvent({
    required this.type,
    this.text,
    this.startOffset,
    this.endOffset,
    this.errorMessage,
  });
}
