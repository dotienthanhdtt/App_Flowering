import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/auth_controller.dart';

/// Screen 09 — Login Gate shown as a bottom sheet over the Scenario Gift screen.
/// Social auth via Firebase; email routes to Signup/Login screens.
class LoginGateBottomSheet extends StatelessWidget {
  const LoginGateBottomSheet({super.key});

  AuthController _getAuthController() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
    return Get.find<AuthController>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXXL)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.space6,
        AppSizes.space5,
        AppSizes.space6,
        MediaQuery.of(context).viewInsets.bottom + AppSizes.space8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: AppSizes.space1,
            decoration: BoxDecoration(
              color: AppColors.borderStrongColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
            ),
          ),
          const SizedBox(height: AppSizes.space6),
          AppText(
            'auth_gate_title'.tr,
            variant: AppTextVariant.h3,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: AppSizes.space2),
          AppText(
            'auth_gate_subtitle'.tr,
            variant: AppTextVariant.bodyMedium,
            color: AppColors.textSecondaryColor,
            height: AppSizes.lineHeightBase,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.space6),
          // Error message
          Obx(() {
            final err = _getAuthController().errorMessage.value;
            if (err.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.space3),
              child: AppText(
                err,
                variant: AppTextVariant.caption,
                color: AppColors.errorColor,
                textAlign: TextAlign.center,
              ),
            );
          }),
          // Loading indicator
          Obx(() {
            if (!_getAuthController().isLoading.value) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.only(bottom: AppSizes.space3),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }),
          // Apple Sign-In (iOS only)
          if (Platform.isIOS)
            SignInWithAppleButton(
              onPressed: () => _getAuthController().signInWithApple(),
              style: SignInWithAppleButtonStyle.black,
              height: AppSizes.buttonHeightLarge,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
          if (Platform.isIOS)
            const SizedBox(height: AppSizes.space3),
          // Google Sign-In
          _GoogleSignInButton(
            onTap: () => _getAuthController().signInWithGoogle(),
          ),
          const SizedBox(height: AppSizes.space4),
          // "or" divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.borderLightColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.space3),
                child: AppText(
                  'login_or_divider'.tr,
                  variant: AppTextVariant.caption,
                  fontSize: AppSizes.fontSizeSmall,
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderLightColor)),
            ],
          ),
          const SizedBox(height: AppSizes.space4),
          // Email signup button
          GestureDetector(
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.signup);
            },
            child: Container(
              height: AppSizes.buttonHeightLarge,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              alignment: Alignment.center,
              child: AppText(
                'auth_continue_email'.tr,
                variant: AppTextVariant.button,
                fontSize: AppSizes.fontSizeMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space4),
          // Login link
          GestureDetector(
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.login);
            },
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: AppSizes.fontSizeSmall,
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

/// Google sign-in button matching Google branding guidelines.
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.buttonHeightLarge,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceColor,
          side: const BorderSide(color: AppColors.borderLightColor, width: AppSizes.borderMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
        ),
        icon: Image.asset('assets/logos/google_logo.png', height: 20, width: 20),
        label: AppText(
          'continue_with_google'.tr,
          variant: AppTextVariant.bodyLarge,
          fontSize: AppSizes.fontSizeMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryColor,
        ),
      ),
    );
  }
}
