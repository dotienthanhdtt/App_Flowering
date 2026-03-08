import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_text_field.dart';

/// Screen 14 — Set new password after OTP verification.
class NewPasswordScreen extends StatelessWidget {
  const NewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ForgotPasswordController>();

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
                  key: ctrl.newPasswordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppText(
                        'new_password_title'.tr,
                        variant: AppTextVariant.h2,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: AppSizes.spacingSM),
                      AppText(
                        'new_password_subtitle'.tr,
                        variant: AppTextVariant.bodyMedium,
                        color: AppColors.textSecondary,
                        height: AppSizes.lineHeightNormal,
                      ),
                      const SizedBox(height: AppSizes.spacing4XL),
                      Obx(() => AuthTextField(
                            label: 'new_password_label'.tr,
                            hint: 'password_min_hint'.tr,
                            controller: ctrl.newPasswordController,
                            validator: ctrl.validateNewPassword,
                            obscureText: ctrl.obscureNewPassword.value,
                            onToggleObscure: ctrl.obscureNewPassword.toggle,
                          )),
                      const SizedBox(height: AppSizes.spacingL),
                      Obx(() => AuthTextField(
                            label: 'confirm_password'.tr,
                            hint: 'confirm_new_password_hint'.tr,
                            controller: ctrl.confirmNewPasswordController,
                            validator: ctrl.validateConfirmNewPassword,
                            obscureText: ctrl.obscureConfirmNewPassword.value,
                            onToggleObscure:
                                ctrl.obscureConfirmNewPassword.toggle,
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
                      Obx(() => GestureDetector(
                            onTap: ctrl.isLoading.value
                                ? null
                                : ctrl.resetPassword,
                            child: Container(
                              height: AppSizes.buttonHeightM,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusPill),
                              ),
                              alignment: Alignment.center,
                              child: ctrl.isLoading.value
                                  ? const SizedBox(
                                      width: AppSizes.iconL,
                                      height: AppSizes.iconL,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : AppText(
                                      'new_password_cta'.tr,
                                      variant: AppTextVariant.button,
                                      fontSize: AppSizes.fontXL,
                                    ),
                            ),
                          )),
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
