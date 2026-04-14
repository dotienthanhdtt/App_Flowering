// Models for GET /lessons API response.
// API returns scenarios grouped by category with status-driven UI state.

class LessonScenario {
  final String id;
  final String title;
  final String? imageUrl;

  /// 'beginner' | 'intermediate' | 'advanced'
  final String difficulty;

  /// 'available' | 'trial' | 'locked' | 'learned'
  final String status;

  const LessonScenario({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.difficulty,
    required this.status,
  });

  factory LessonScenario.fromJson(Map<String, dynamic> json) {
    return LessonScenario(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      status: json['status'] as String? ?? 'available',
    );
  }
}

class LessonCategory {
  final String id;
  final String name;

  /// Emoji or URL; may be null
  final String? icon;
  final List<LessonScenario> scenarios;

  const LessonCategory({
    required this.id,
    required this.name,
    this.icon,
    required this.scenarios,
  });

  factory LessonCategory.fromJson(Map<String, dynamic> json) {
    final rawScenarios = json['scenarios'] as List<dynamic>? ?? [];
    return LessonCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      scenarios: rawScenarios
          .map((s) => LessonScenario.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LessonPagination {
  final int page;
  final int limit;
  final int total;

  const LessonPagination({
    required this.page,
    required this.limit,
    required this.total,
  });

  factory LessonPagination.fromJson(Map<String, dynamic> json) {
    return LessonPagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
    );
  }
}

class GetLessonsResponse {
  final List<LessonCategory> categories;
  final LessonPagination pagination;

  const GetLessonsResponse({
    required this.categories,
    required this.pagination,
  });

  factory GetLessonsResponse.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'] as List<dynamic>? ?? [];
    return GetLessonsResponse(
      categories: rawCategories
          .map((c) => LessonCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
      pagination: LessonPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
