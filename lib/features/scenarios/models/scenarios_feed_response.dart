import 'scenarios_pagination.dart';

/// Generic wrapper for paginated scenario feeds.
/// Matches backend shape: `{ items: [...], pagination: { page, limit, total } }`.
class ScenariosFeedResponse<T> {
  final List<T> items;
  final ScenariosPagination pagination;

  const ScenariosFeedResponse({
    required this.items,
    required this.pagination,
  });

  factory ScenariosFeedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return ScenariosFeedResponse<T>(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(itemFromJson)
          .toList(growable: false),
      pagination: ScenariosPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
