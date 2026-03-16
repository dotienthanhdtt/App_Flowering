import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/paywall-controller.dart';

/// Sticky bottom bar with purchase CTA, restore, terms, and privacy links.
class PaywallBottomActions extends StatelessWidget {
  final PaywallController controller;
  const PaywallBottomActions({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.backgroundWarm,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusL),
                    ),
                  ),
                  child: controller.isPurchasing.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'subscription_purchase_button'.tr,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                )),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: controller.restorePurchases,
                child: Text(
                  'subscription_restore'.tr,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const Text('·', style: TextStyle(color: AppColors.textTertiary)),
              TextButton(
                onPressed: () {},
                child: Text(
                  'subscription_terms'.tr,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const Text('·', style: TextStyle(color: AppColors.textTertiary)),
              TextButton(
                onPressed: () {},
                child: Text(
                  'subscription_privacy'.tr,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
