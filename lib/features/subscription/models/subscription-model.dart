enum SubscriptionPlan { free, monthly, yearly, lifetime }

enum SubscriptionStatus { active, expired, cancelled, trial }

class SubscriptionModel {
  final String? id;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool isActive;
  final bool cancelAtPeriodEnd;

  const SubscriptionModel({
    this.id,
    required this.plan,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    required this.isActive,
    this.cancelAtPeriodEnd = false,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String?,
      plan: _parsePlan(json['plan'] as String?),
      status: _parseStatus(json['status'] as String?),
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.tryParse(json['current_period_start'] as String)
          : null,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.tryParse(json['current_period_end'] as String)
          : json['expiresAt'] != null
              ? DateTime.tryParse(json['expiresAt'] as String)
              : null,
      isActive: json['is_active'] as bool? ??
          json['isActive'] as bool? ??
          false,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ??
          json['cancelAtPeriodEnd'] as bool? ??
          false,
    );
  }

  factory SubscriptionModel.free() {
    return const SubscriptionModel(
      plan: SubscriptionPlan.free,
      status: SubscriptionStatus.active,
      isActive: true,
    );
  }

  bool get isPremium => plan != SubscriptionPlan.free && isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan': plan.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'current_period_start': currentPeriodStart?.toIso8601String(),
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'is_active': isActive,
      'cancel_at_period_end': cancelAtPeriodEnd,
    };
  }

  static SubscriptionPlan _parsePlan(String? value) {
    if (value == null) return SubscriptionPlan.free;
    return SubscriptionPlan.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SubscriptionPlan.free,
    );
  }

  static SubscriptionStatus _parseStatus(String? value) {
    if (value == null) return SubscriptionStatus.expired;
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SubscriptionStatus.expired,
    );
  }
}
