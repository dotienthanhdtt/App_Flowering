import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/paywall-controller.dart';
import 'plan-card-widget.dart';

/// Compact bottom sheet paywall triggered by feature gates.
class PaywallBottomSheet {
  /// Show compact paywall. Returns true if user successfully purchased.
  static Future<bool> show() async {
    // Register PaywallController only if not already in the DI container
    if (!Get.isRegistered<PaywallController>()) {
      Get.lazyPut<PaywallController>(() => PaywallController());
    }

    final result = await Get.bottomSheet<bool>(
      const _PaywallSheetContent(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    return result ?? false;
  }
}

class _PaywallSheetContent extends StatelessWidget {
  const _PaywallSheetContent();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaywallController>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWarmColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(AppColors.radiusPill),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.workspace_premium_rounded,
            size: 40,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 10),
          Text(
            'subscription_title'.tr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'subscription_gate_description'.tr,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Plan offerings
          Obx(() {
            if (controller.isLoading.value && controller.offerings.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }
            return Column(
              children: List.generate(controller.offerings.length, (i) {
                final offering = controller.offerings[i];
                return PlanCardWidget(
                  offering: offering,
                  isSelected: controller.selectedPackageIndex.value == i,
                  isRecommended: offering.isRecommended,
                  onTap: () => controller.selectedPackageIndex.value = i,
                );
              }),
            );
          }),
          const SizedBox(height: 16),
          // Purchase button
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
                  onPressed: controller.isPurchasing.value ||
                          controller.offerings.isEmpty
                      ? null
                      : () async {
                          final offering = controller.offerings[
                              controller.selectedPackageIndex.value];
                          final success = await controller.purchase(offering);
                          if (success) Get.back(result: true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor: AppColors.primaryLightColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusL),
                    ),
                  ),
                  child: controller.isPurchasing.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'subscription_purchase_button'.tr,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                )),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: controller.restorePurchases,
            child: Text(
              'subscription_restore'.tr,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
