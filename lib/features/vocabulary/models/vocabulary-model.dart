class VocabularyItem {
  final String id;
  final String word;
  final String translation;
  final int box;
  final List<String> examples;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VocabularyItem({
    required this.id,
    required this.word,
    required this.translation,
    required this.box,
    this.examples = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String? ?? '',
      word: json['word'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      box: json['box'] as int? ?? 1,
      examples: _parseExamples(json['examples']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static List<String> _parseExamples(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class VocabularyListResponse {
  final List<VocabularyItem> items;
  final int total;
  final int page;
  final int limit;

  const VocabularyListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory VocabularyListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return VocabularyListResponse(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(VocabularyItem.fromJson)
          .toList(growable: false),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}
