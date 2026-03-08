import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
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
                      Text(
                        'New Password',
                        style: GoogleFonts.outfit(
                          fontSize: AppSizes.font6XL,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: AppSizes.trackingSnug,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingSM),
                      Text(
                        'Create a strong password for your account',
                        style: GoogleFonts.outfit(
                          fontSize: AppSizes.fontM,
                          color: AppColors.textSecondary,
                          height: AppSizes.lineHeightNormal,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing4XL),
                      Obx(() => AuthTextField(
                            label: 'New Password',
                            hint: 'At least 8 characters',
                            controller: ctrl.newPasswordController,
                            validator: ctrl.validateNewPassword,
                            obscureText: ctrl.obscureNewPassword.value,
                            onToggleObscure: ctrl.obscureNewPassword.toggle,
                          )),
                      const SizedBox(height: AppSizes.spacingL),
                      Obx(() => AuthTextField(
                            label: 'Confirm Password',
                            hint: 'Repeat your new password',
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
                          child: Text(
                            ctrl.errorMessage.value,
                            style: GoogleFonts.outfit(
                              fontSize: AppSizes.fontSM,
                              color: AppColors.error,
                            ),
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
                                  : Text(
                                      'Reset Password',
                                      style: GoogleFonts.outfit(
                                        fontSize: AppSizes.fontXL,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
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
