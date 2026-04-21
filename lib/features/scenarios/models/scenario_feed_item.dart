import 'scenario_access_tier.dart';
import 'scenario_type.dart';
import 'scenario_user_status.dart';

/// Item returned by `GET /scenarios/default` (the Flowering tab feed).
class ScenarioFeedItem {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;

  /// 'beginner' | 'intermediate' | 'advanced' (kept as string — not enumerated).
  final String difficulty;
  final String languageId;
  final ScenarioAccessTier accessTier;
  final ScenarioUserStatus status;
  final ScenarioType type;
  final int orderIndex;

  const ScenarioFeedItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.difficulty,
    required this.languageId,
    required this.accessTier,
    required this.status,
    required this.type,
    required this.orderIndex,
  });

  factory ScenarioFeedItem.fromJson(Map<String, dynamic> json) {
    return ScenarioFeedItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      languageId:
          json['language_id'] as String? ?? json['languageId'] as String? ?? '',
      accessTier: ScenarioAccessTier.fromString(
        json['access_tier'] as String? ?? json['accessTier'] as String?,
      ),
      status: ScenarioUserStatus.fromString(json['status'] as String?),
      type: ScenarioType.fromString(json['type'] as String?),
      orderIndex: (json['order_index'] as int?) ??
          (json['orderIndex'] as int?) ??
          0,
    );
  }
}
