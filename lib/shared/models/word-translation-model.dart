/// Word translation response from POST /ai/translate (type: word)
class WordTranslationModel {
  final String original;
  final String translation;
  final String? partOfSpeech;
  final String? pronunciation;
  final String? definition;
  final List<String> examples;
  final String? vocabularyId;

  const WordTranslationModel({
    required this.original,
    required this.translation,
    this.partOfSpeech,
    this.pronunciation,
    this.definition,
    this.examples = const [],
    this.vocabularyId,
  });

  factory WordTranslationModel.fromJson(Map<String, dynamic> json) {
    return WordTranslationModel(
      original: json['word'] as String? ?? json['original'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      partOfSpeech: json['part_of_speech'] as String? ??
          json['partOfSpeech'] as String?,
      pronunciation: json['pronunciation'] as String?,
      definition: json['definition'] as String?,
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vocabularyId: json['vocabulary_id'] as String? ??
          json['vocabularyId'] as String?,
    );
  }
}
