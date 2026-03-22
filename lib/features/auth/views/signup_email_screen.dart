import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

/// Screen 10 — Email signup with full name, email, password, confirm password.
class SignupEmailScreen extends BaseScreen<AuthController> {
  const SignupEmailScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimaryColor),
            onPressed: Get.back,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingXXL, AppSizes.paddingXS, AppSizes.paddingXXL, AppSizes.paddingXXL),
            child: Form(
              key: controller.signupFormKey,
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
                    color: AppColors.textSecondaryColor,
                  ),
                  const SizedBox(height: AppSizes.spacing3XL),
                  AuthTextField(
                    label: 'signup_full_name'.tr,
                    hint: 'signup_full_name_hint'.tr,
                    controller: controller.fullNameController,
                    validator: controller.validateFullName,
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  AuthTextField(
                    label: 'email'.tr,
                    hint: 'email_hint'.tr,
                    controller: controller.emailController,
                    validator: controller.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  Obx(() => AuthTextField(
                        label: 'password'.tr,
                        hint: 'password_min_hint'.tr,
                        controller: controller.passwordController,
                        validator: controller.validatePassword,
                        obscureText: controller.obscurePassword.value,
                        onToggleObscure: controller.obscurePassword.toggle,
                      )),
                  const SizedBox(height: AppSizes.spacingL),
                  Obx(() => AuthTextField(
                        label: 'confirm_password'.tr,
                        hint: 'confirm_password_hint'.tr,
                        controller: controller.confirmPasswordController,
                        validator: (v) => controller.validateConfirmPassword(
                          v,
                          controller.passwordController.text,
                        ),
                        obscureText: controller.obscureConfirmPassword.value,
                        onToggleObscure: controller.obscureConfirmPassword.toggle,
                        textInputAction: TextInputAction.done,
                      )),
                  // Error message
                  Obx(() {
                    if (controller.errorMessage.value.isEmpty) {
                      return const SizedBox(height: AppSizes.spacingL);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSizes.spacingM),
                      child: AppText(
                        controller.errorMessage.value,
                        variant: AppTextVariant.caption,
                        fontSize: AppSizes.fontSM,
                        color: AppColors.errorColor,
                      ),
                    );
                  }),
                  const SizedBox(height: AppSizes.spacingXXL),
                  // Submit button
                  Obx(() => GestureDetector(
                        onTap: controller.isLoading.value ? null : controller.register,
                        child: Container(
                          height: AppSizes.buttonHeightM,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                          ),
                          alignment: Alignment.center,
                          child: controller.isLoading.value
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
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
