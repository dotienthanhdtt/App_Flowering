import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

/// Screen 10 — Email signup with full name, email, password, confirm password.
class SignupEmailScreen extends StatelessWidget {
  const SignupEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button
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
                  key: ctrl.signupFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppText(
                        'signup_title'.tr,
                        variant: AppTextVariant.h2,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: AppSizes.spacingSM),
                      AppText(
                        'signup_subtitle'.tr,
                        variant: AppTextVariant.bodyMedium,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSizes.spacing3XL),
                      AuthTextField(
                        label: 'signup_full_name'.tr,
                        hint: 'signup_full_name_hint'.tr,
                        controller: ctrl.fullNameController,
                        validator: ctrl.validateFullName,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      AuthTextField(
                        label: 'email'.tr,
                        hint: 'email_hint'.tr,
                        controller: ctrl.emailController,
                        validator: ctrl.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      Obx(() => AuthTextField(
                            label: 'password'.tr,
                            hint: 'password_min_hint'.tr,
                            controller: ctrl.passwordController,
                            validator: ctrl.validatePassword,
                            obscureText: ctrl.obscurePassword.value,
                            onToggleObscure: ctrl.obscurePassword.toggle,
                          )),
                      const SizedBox(height: AppSizes.spacingL),
                      Obx(() => AuthTextField(
                            label: 'confirm_password'.tr,
                            hint: 'confirm_password_hint'.tr,
                            controller: ctrl.confirmPasswordController,
                            validator: (v) => ctrl.validateConfirmPassword(
                              v,
                              ctrl.passwordController.text,
                            ),
                            obscureText: ctrl.obscureConfirmPassword.value,
                            onToggleObscure: ctrl.obscureConfirmPassword.toggle,
                            textInputAction: TextInputAction.done,
                          )),
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
                            onTap: ctrl.isLoading.value ? null : ctrl.register,
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
                                      'signup_cta'.tr,
                                      variant: AppTextVariant.button,
                                      fontSize: AppSizes.fontXL,
                                    ),
                            ),
                          )),
                      const SizedBox(height: AppSizes.spacingXL),
                      // Login link
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.login),
                        child: Center(
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
