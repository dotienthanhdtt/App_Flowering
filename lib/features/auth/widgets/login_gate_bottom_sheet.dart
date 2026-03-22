import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import 'social_auth_button.dart';

/// Screen 09 — Login Gate shown as a bottom sheet over the Scenario Gift screen.
/// Social auth buttons are UI-only stubs; email routes to Signup/Login screens.
class LoginGateBottomSheet extends StatelessWidget {
  const LoginGateBottomSheet({super.key});

  void _onSocialTap() {
    Get.snackbar(
      'auth_social_coming_soon'.tr,
      'auth_social_coming_soon_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(AppSizes.paddingL),
      backgroundColor: AppColors.surfaceColor,
      colorText: AppColors.textPrimaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXXL)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.paddingXXL,
        AppSizes.paddingXL,
        AppSizes.paddingXXL,
        MediaQuery.of(context).viewInsets.bottom + AppSizes.padding3XL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: AppSizes.spacingXS,
            decoration: BoxDecoration(
              color: AppColors.borderStrongColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
            ),
          ),
          const SizedBox(height: AppSizes.spacingXXL),
          AppText(
            'auth_gate_title'.tr,
            variant: AppTextVariant.h3,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: AppSizes.spacingSM),
          AppText(
            'auth_gate_subtitle'.tr,
            variant: AppTextVariant.bodyMedium,
            color: AppColors.textSecondaryColor,
            height: AppSizes.lineHeightNormal,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacingXXL),
          SocialAuthButton(provider: SocialProvider.apple, onTap: _onSocialTap),
          const SizedBox(height: AppSizes.spacingM),
          SocialAuthButton(provider: SocialProvider.google, onTap: _onSocialTap),
          const SizedBox(height: AppSizes.spacingL),
          // "or" divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.borderLightColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM),
                child: AppText(
                  'login_or_divider'.tr,
                  variant: AppTextVariant.caption,
                  fontSize: AppSizes.fontSM,
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderLightColor)),
            ],
          ),
          const SizedBox(height: AppSizes.spacingL),
          // Email signup button
          GestureDetector(
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.signup);
            },
            child: Container(
              height: AppSizes.buttonHeightM,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              alignment: Alignment.center,
              child: AppText(
                'auth_continue_email'.tr,
                variant: AppTextVariant.button,
                fontSize: AppSizes.fontL,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          // Login link
          GestureDetector(
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.login);
            },
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: AppSizes.fontM,
                  color: AppColors.textSecondaryColor,
                ),
                children: [
                  TextSpan(text: '${'already_have_account'.tr} '),
                  TextSpan(
                    text: 'login_action'.tr,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
