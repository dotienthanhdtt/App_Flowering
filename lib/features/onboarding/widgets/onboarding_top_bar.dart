import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          top: AppSizes.topBarHeight, left: AppSizes.padding3XL, right: AppSizes.padding3XL),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            child: Image.asset(
              'assets/logos/logo.png',
              width: AppSizes.avatarS,
              height: AppSizes.avatarS,
            ),
          ),
          const SizedBox(width: AppSizes.spacingS),
          AppText(
            'app_name'.tr,
            variant: AppTextVariant.bodyMedium,
            fontSize: AppSizes.font3XL,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryColor,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.login),
            child: AppText(
              'login_action'.tr,
              variant: AppTextVariant.bodyMedium,
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
