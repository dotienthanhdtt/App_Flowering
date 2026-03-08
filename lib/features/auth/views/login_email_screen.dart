import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_button.dart';

/// Screen 11 — Email login with social auth options and forgot password link.
class LoginEmailScreen extends StatelessWidget {
  const LoginEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary),
                onPressed: Get.back,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingXXL, AppSizes.paddingXS, AppSizes.paddingXXL, AppSizes.paddingXXL),
                child: Form(
                  key: ctrl.loginFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppText(
                        'login_title'.tr,
                        variant: AppTextVariant.h2,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: AppSizes.spacingSM),
                      AppText(
                        'login_subtitle'.tr,
                        variant: AppTextVariant.bodyMedium,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSizes.spacing3XL),
                      // Social auth
                      SocialAuthButton(
                        provider: SocialProvider.apple,
                        onTap: ctrl.signInWithApple,
                      ),
                      const SizedBox(height: AppSizes.spacingM),
                      SocialAuthButton(
                        provider: SocialProvider.google,
                        onTap: ctrl.signInWithGoogle,
                      ),
                      const SizedBox(height: AppSizes.spacingXL),
                      // "or" divider
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: AppColors.borderLight)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM),
                            child: AppText(
                              'login_or_divider'.tr,
                              variant: AppTextVariant.caption,
                              fontSize: AppSizes.fontSM,
                            ),
                          ),
                          const Expanded(
                              child: Divider(color: AppColors.borderLight)),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacingXL),
                      AuthTextField(
                        label: 'email'.tr,
                        hint: 'email_hint'.tr,
                        controller: ctrl.loginEmailController,
                        validator: ctrl.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      Obx(() => AuthTextField(
                            label: 'password'.tr,
                            hint: 'password_hint'.tr,
                            controller: ctrl.loginPasswordController,
                            validator: ctrl.validatePassword,
                            obscureText: ctrl.obscurePassword.value,
                            onToggleObscure: ctrl.obscurePassword.toggle,
                            textInputAction: TextInputAction.done,
                          )),
                      const SizedBox(height: AppSizes.spacingS),
                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.forgotPassword),
                          child: AppText(
                            'forgot_password'.tr,
                            variant: AppTextVariant.caption,
                            fontSize: AppSizes.fontSM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      // Error message
                      Obx(() {
                        if (ctrl.errorMessage.value.isEmpty) {
                          return const SizedBox(height: AppSizes.spacingL);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSizes.spacingM),
                          child: AppText(
                            ctrl.errorMessage.value,
                            variant: AppTextVariant.caption,
                            fontSize: AppSizes.fontSM,
                            color: AppColors.error,
                          ),
                        );
                      }),
                      const SizedBox(height: AppSizes.spacingXXL),
                      // Submit button
                      Obx(() => GestureDetector(
                            onTap: ctrl.isLoading.value ? null : ctrl.login,
                            child: Container(
                              height: AppSizes.buttonHeightM,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusPill),
                              ),
                              alignment: Alignment.center,
                              child: ctrl.isLoading.value
                                  ? const SizedBox(
                                      width: AppSizes.iconL,
                                      height: AppSizes.iconL,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : AppText(
                                      'login_cta'.tr,
                                      variant: AppTextVariant.button,
                                      fontSize: AppSizes.fontXL,
                                    ),
                            ),
                          )),
                      const SizedBox(height: AppSizes.spacingXL),
                      // Signup link
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.signup),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: AppSizes.fontM,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(text: '${'dont_have_account'.tr} '),
                                TextSpan(
                                  text: 'signup_action'.tr,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
