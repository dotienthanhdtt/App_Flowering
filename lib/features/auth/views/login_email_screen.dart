import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

/// Screen 11 — Email login with social auth options and forgot password link.
class LoginEmailScreen extends BaseScreen<AuthController> {
  const LoginEmailScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                AppSizes.space6, AppSizes.space2, AppSizes.space6, AppSizes.space6),
            child: Form(
              key: controller.loginFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText(
                    'login_title'.tr,
                    variant: AppTextVariant.h2,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: AppSizes.space2),
                  AppText(
                    'login_subtitle'.tr,
                    variant: AppTextVariant.bodyMedium,
                    color: AppColors.textSecondaryColor,
                  ),
                  const SizedBox(height: AppSizes.space6),
                  // Apple Sign-In (iOS only)
                  if (Platform.isIOS)
                    SignInWithAppleButton(
                      onPressed: controller.signInWithApple,
                      style: SignInWithAppleButtonStyle.black,
                      height: AppSizes.buttonHeightLarge,
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  if (Platform.isIOS)
                    const SizedBox(height: AppSizes.space3),
                  // Google Sign-In
                  SizedBox(
                    height: AppSizes.buttonHeightLarge,
                    child: OutlinedButton.icon(
                      onPressed: controller.signInWithGoogle,
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
                  ),
                  const SizedBox(height: AppSizes.space5),
                  // "or" divider
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: AppColors.borderLightColor)),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSizes.space3),
                        child: AppText(
                          'login_or_divider'.tr,
                          variant: AppTextVariant.caption,
                          fontSize: AppSizes.fontSizeSmall,
                        ),
                      ),
                      const Expanded(
                          child: Divider(color: AppColors.borderLightColor)),
                    ],
                  ),
                  const SizedBox(height: AppSizes.space5),
                  AuthTextField(
                    label: 'email'.tr,
                    hint: 'email_hint'.tr,
                    controller: controller.loginEmailController,
                    validator: controller.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSizes.space4),
                  Obx(() => AuthTextField(
                        label: 'password'.tr,
                        hint: 'password_hint'.tr,
                        controller: controller.loginPasswordController,
                        validator: controller.validatePassword,
                        obscureText: controller.obscurePassword.value,
                        onToggleObscure: controller.obscurePassword.toggle,
                        textInputAction: TextInputAction.done,
                      )),
                  const SizedBox(height: AppSizes.space2),
                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.forgotPassword),
                      child: AppText(
                        'forgot_password'.tr,
                        variant: AppTextVariant.caption,
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  // Error message
                  Obx(() {
                    if (controller.errorMessage.value.isEmpty) {
                      return const SizedBox(height: AppSizes.space4);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSizes.space3),
                      child: AppText(
                        controller.errorMessage.value,
                        variant: AppTextVariant.caption,
                        fontSize: AppSizes.fontSizeSmall,
                        color: AppColors.errorColor,
                      ),
                    );
                  }),
                  const SizedBox(height: AppSizes.space6),
                  // Submit button
                  Obx(() => GestureDetector(
                        onTap: controller.isLoading.value ? null : controller.login,
                        child: Container(
                          height: AppSizes.buttonHeightLarge,
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
                                  'login_cta'.tr,
                                  variant: AppTextVariant.button,
                                  fontSize: AppSizes.fontSizeMedium,
                                ),
                        ),
                      )),
                  const SizedBox(height: AppSizes.space5),
                  // Signup link
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.signup),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.fontSizeSmall,
                            color: AppColors.textSecondaryColor,
                          ),
                          children: [
                            TextSpan(text: '${'dont_have_account'.tr} '),
                            TextSpan(
                              text: 'signup_action'.tr,
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
                  const SizedBox(height: AppSizes.space2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
