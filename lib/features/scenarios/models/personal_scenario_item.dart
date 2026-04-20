import 'personal_source.dart';
import 'scenario_access_tier.dart';
import 'scenario_type.dart';
import 'scenario_user_status.dart';

/// Item returned by `GET /scenarios/personal` (the For You tab feed).
/// Text-only by design — no `image_url`.
class PersonalScenarioItem {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String languageId;
  final DateTime? addedAt;
  final PersonalSource source;
  final ScenarioAccessTier accessTier;
  final ScenarioUserStatus status;
  final ScenarioType type;

  const PersonalScenarioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.languageId,
    required this.addedAt,
    required this.source,
    required this.accessTier,
    required this.status,
    required this.type,
  });

  factory PersonalScenarioItem.fromJson(Map<String, dynamic> json) {
    return PersonalScenarioItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'beginner',
      languageId:
          json['language_id'] as String? ?? json['languageId'] as String? ?? '',
      addedAt: _parseDate(json['added_at'] ?? json['addedAt']),
      source: PersonalSource.fromString(json['source'] as String?),
      accessTier: ScenarioAccessTier.fromString(
        json['access_tier'] as String? ?? json['accessTier'] as String?,
      ),
      status: ScenarioUserStatus.fromString(json['status'] as String?),
      type: ScenarioType.fromString(json['type'] as String?),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
