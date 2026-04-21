import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_button.dart';
import '../models/scenario_detail.dart';
import '../models/scenario_user_status.dart';

/// Bottom CTA bar for the scenario detail screen.
/// Renders the correct button based on lock / learned state.
class ScenarioDetailCta extends StatelessWidget {
  final ScenarioDetail detail;
  final VoidCallback onStart;
  final VoidCallback onPracticeAgain;
  final VoidCallback onUpgrade;

  const ScenarioDetailCta({
    super.key,
    required this.detail,
    required this.onStart,
    required this.onPracticeAgain,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    if (detail.isLocked) {
      return AppButton(
        text: 'scenario_detail_cta_upgrade'.tr,
        onPressed: onUpgrade,
      );
    }
    if (detail.userStatus == ScenarioUserStatus.learned) {
      return AppButton(
        text: 'scenario_detail_cta_practice_again'.tr,
        onPressed: onPracticeAgain,
      );
    }
    return AppButton(
      text: 'scenario_detail_cta_start'.tr,
      onPressed: onStart,
    );
  }
}
