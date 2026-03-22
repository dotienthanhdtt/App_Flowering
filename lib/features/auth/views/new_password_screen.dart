import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_text_field.dart';

/// Screen 14 — Set new password after OTP verification.
class NewPasswordScreen extends BaseScreen<ForgotPasswordController> {
  const NewPasswordScreen({super.key});

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
                AppSizes.paddingXXL, AppSizes.paddingXS, AppSizes.paddingXXL, AppSizes.paddingXXL),
            child: Form(
              key: controller.newPasswordFormKey,
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
                    color: AppColors.textSecondaryColor,
                    height: AppSizes.lineHeightNormal,
                  ),
                  const SizedBox(height: AppSizes.spacing4XL),
                  Obx(() => AuthTextField(
                        label: 'new_password_label'.tr,
                        hint: 'password_min_hint'.tr,
                        controller: controller.newPasswordController,
                        validator: controller.validateNewPassword,
                        obscureText: controller.obscureNewPassword.value,
                        onToggleObscure: controller.obscureNewPassword.toggle,
                      )),
                  const SizedBox(height: AppSizes.spacingL),
                  Obx(() => AuthTextField(
                        label: 'confirm_password'.tr,
                        hint: 'confirm_new_password_hint'.tr,
                        controller: controller.confirmNewPasswordController,
                        validator: controller.validateConfirmNewPassword,
                        obscureText: controller.obscureConfirmNewPassword.value,
                        onToggleObscure:
                            controller.obscureConfirmNewPassword.toggle,
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
                  Obx(() => GestureDetector(
                        onTap: controller.isLoading.value
                            ? null
                            : controller.resetPassword,
                        child: Container(
                          height: AppSizes.buttonHeightM,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill),
                          ),
                          alignment: Alignment.center,
                          child: controller.isLoading.value
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
    );
  }
}
