import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/subscription-controller.dart';
import '../models/subscription-model.dart';

/// Displays the current subscription plan badge.
/// Tapping navigates to the paywall screen.
class SubscriptionStatusWidget extends StatelessWidget {
  const SubscriptionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();

    return Obx(() {
      final plan = controller.currentPlan;
      final isPremium = controller.isPremium;

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.paywall),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isPremium ? AppColors.primarySoft : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppColors.radiusM),
            border: Border.all(
              color: isPremium ? AppColors.primaryLight : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPremium
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_outline_rounded,
                size: 18,
                color: isPremium ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                isPremium ? _planLabel(plan) : 'subscription_free_plan'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isPremium ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              if (!isPremium) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.textTertiary,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  String _planLabel(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.monthly:
        return 'subscription_monthly'.tr;
      case SubscriptionPlan.yearly:
        return 'subscription_yearly'.tr;
      case SubscriptionPlan.lifetime:
        return 'subscription_lifetime'.tr;
      case SubscriptionPlan.free:
        return 'subscription_free_plan'.tr;
    }
  }
}
