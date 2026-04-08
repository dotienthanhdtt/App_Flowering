class SttResult {
  final String text;
  final bool isFinal;
  final double confidence;

  const SttResult({
    required this.text,
    required this.isFinal,
    this.confidence = 0.0,
  });
}
