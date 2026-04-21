import 'scenario_access_tier.dart';
import 'scenario_user_status.dart';

class ScenarioCategoryRef {
  final String id;
  final String name;

  const ScenarioCategoryRef({required this.id, required this.name});

  factory ScenarioCategoryRef.fromJson(Map<String, dynamic> json) =>
      ScenarioCategoryRef(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

/// Full scenario detail returned by GET /scenarios/:id
class ScenarioDetail {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String difficulty;
  final String languageId;
  final int orderIndex;
  final ScenarioCategoryRef category;
  final ScenarioAccessTier accessTier;
  final bool isLocked;
  final String? lockReason;
  final ScenarioUserStatus userStatus;

  const ScenarioDetail({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.difficulty,
    required this.languageId,
    required this.orderIndex,
    required this.category,
    required this.accessTier,
    required this.isLocked,
    this.lockReason,
    required this.userStatus,
  });

  factory ScenarioDetail.fromJson(Map<String, dynamic> json) => ScenarioDetail(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
        difficulty: json['difficulty'] as String? ?? '',
        languageId: json['language_id'] as String? ?? json['languageId'] as String? ?? '',
        orderIndex: (json['order_index'] as int?) ?? (json['orderIndex'] as int?) ?? 0,
        category: json['category'] != null
            ? ScenarioCategoryRef.fromJson(
                json['category'] as Map<String, dynamic>)
            : const ScenarioCategoryRef(id: '', name: ''),
        accessTier: ScenarioAccessTier.fromString(
          json['access_tier'] as String? ?? json['accessTier'] as String?,
        ),
        isLocked: json['is_locked'] as bool? ?? json['isLocked'] as bool? ?? false,
        lockReason: json['lock_reason'] as String? ?? json['lockReason'] as String?,
        userStatus: ScenarioUserStatus.fromString(
          json['user_status'] as String? ?? json['userStatus'] as String?,
        ),
      );
}
