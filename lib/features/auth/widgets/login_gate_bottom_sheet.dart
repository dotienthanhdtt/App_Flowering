import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'social_auth_button.dart';

/// Screen 09 — Login Gate shown as a bottom sheet over the Scenario Gift screen.
/// Social auth buttons are UI-only stubs; email routes to Signup/Login screens.
class LoginGateBottomSheet extends StatelessWidget {
  const LoginGateBottomSheet({super.key});

  void _onSocialTap() {
    Get.snackbar(
      'Coming Soon',
      'Social login will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(AppSizes.paddingL),
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
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
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
            ),
          ),
          const SizedBox(height: AppSizes.spacingXXL),
          Text(
            'Save Your Progress',
            style: GoogleFonts.outfit(
              fontSize: AppSizes.font4XL,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSM),
          Text(
            'Create an account to keep your personalised plan',
            style: GoogleFonts.outfit(
              fontSize: AppSizes.fontM,
              color: AppColors.textSecondary,
              height: AppSizes.lineHeightNormal,
            ),
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
              const Expanded(child: Divider(color: AppColors.borderLight)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM),
                child: Text(
                  'or',
                  style: GoogleFonts.outfit(
                    fontSize: AppSizes.fontSM,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderLight)),
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
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              alignment: Alignment.center,
              child: Text(
                'Sign up with Email',
                style: GoogleFonts.outfit(
                  fontSize: AppSizes.fontL,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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
                style: GoogleFonts.outfit(
                  fontSize: AppSizes.fontM,
                  color: AppColors.textSecondary,
                ),
                children: const [
                  TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Log in',
                    style: TextStyle(
                      color: AppColors.primary,
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
