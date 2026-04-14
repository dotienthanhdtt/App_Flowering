import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/paywall-controller.dart';
import '../widgets/paywall-bottom-actions-widget.dart';
import '../widgets/plan-card-widget.dart';

/// Full-screen paywall accessible from settings or direct navigation.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaywallController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundWarmColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimaryColor),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: Text(
          'subscription_title'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryColor,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.offerings.isEmpty) {
          return const LoadingWidget();
        }
        if (controller.offerings.isEmpty) {
          return _EmptyOfferings(onRetry: controller.fetchOfferings);
        }
        return _PaywallBody(controller: controller);
      }),
    );
  }
}

class _PaywallBody extends StatelessWidget {
  final PaywallController controller;
  const _PaywallBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroSection(),
              const SizedBox(height: 24),
              Obx(() => Column(
                    children: List.generate(controller.offerings.length, (i) {
                      final offering = controller.offerings[i];
                      return PlanCardWidget(
                        offering: offering,
                        isSelected:
                            controller.selectedPackageIndex.value == i,
                        isRecommended: offering.isRecommended,
                        onTap: () => controller.selectedPackageIndex.value = i,
                      );
                    }),
                  )),
              Obx(() {
                if (controller.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: AppColors.errorColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                );
              }),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PaywallBottomActions(controller: controller),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          size: 48,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 12),
        Text(
          'subscription_title'.tr,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'subscription_hero_description'.tr,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondaryColor),
        ),
      ],
    );
  }
}

class _EmptyOfferings extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyOfferings({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textTertiaryColor),
            const SizedBox(height: 16),
            const Text(
              'Could not load subscription plans.',
              style: TextStyle(color: AppColors.textSecondaryColor, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
