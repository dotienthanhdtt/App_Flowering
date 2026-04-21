import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/scenario_access_tier.dart';

/// Small "PRO" pill shown on premium scenario cards.
/// Returns a zero-size widget for `free` tier so it can be placed
/// unconditionally in stacks.
class AccessTierBadge extends StatelessWidget {
  final ScenarioAccessTier tier;

  const AccessTierBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    if (tier != ScenarioAccessTier.premium) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentGoldColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: AppText(
        'access_tier_pro_badge'.tr,
        variant: AppTextVariant.caption,
        color: AppColors.textOnPrimaryColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
