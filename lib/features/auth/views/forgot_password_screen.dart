import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_text_field.dart';

/// Screen 12 — Email input to trigger OTP delivery.
class ForgotPasswordScreen extends BaseScreen<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

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
              key: controller.forgotPasswordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText(
                    'forgot_title'.tr,
                    variant: AppTextVariant.h2,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: AppSizes.space2),
                  AppText(
                    'forgot_subtitle'.tr,
                    variant: AppTextVariant.bodyMedium,
                    color: AppColors.textSecondaryColor,
                    height: AppSizes.lineHeightBase,
                  ),
                  const SizedBox(height: AppSizes.space8),
                  AuthTextField(
                    label: 'email'.tr,
                    hint: 'email_hint'.tr,
                    controller: controller.forgotEmailController,
                    validator: controller.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
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
                  Obx(() => GestureDetector(
                        onTap: controller.isLoading.value
                            ? null
                            : controller.forgotPassword,
                        child: Container(
                          height: AppSizes.buttonHeightLarge,
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
                                  'forgot_cta'.tr,
                                  variant: AppTextVariant.button,
                                  fontSize: AppSizes.fontSizeMedium,
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
