/// Sentence translation response from POST /ai/translate (type: sentence)
class SentenceTranslationModel {
  final String messageId;
  final String original;
  final String translation;

  const SentenceTranslationModel({
    required this.messageId,
    required this.original,
    required this.translation,
  });

  factory SentenceTranslationModel.fromJson(Map<String, dynamic> json) {
    return SentenceTranslationModel(
      messageId: json['message_id'] as String? ??
          json['messageId'] as String? ??
          '',
      original: json['original'] as String? ?? '',
      translation: json['translated_content'] as String? ??
          json['translation'] as String? ??
          '',
    );
  }
}
