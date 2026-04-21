class ScenariosPagination {
  final int page;
  final int limit;
  final int total;

  const ScenariosPagination({
    required this.page,
    required this.limit,
    required this.total,
  });

  factory ScenariosPagination.fromJson(Map<String, dynamic> json) {
    return ScenariosPagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
    );
  }
}
