import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_text_field.dart';

/// Screen 12 — Email input to trigger OTP delivery.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

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
                  key: ctrl.forgotPasswordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Forgot Password?',
                        style: GoogleFonts.outfit(
                          fontSize: AppSizes.font6XL,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: AppSizes.trackingSnug,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingSM),
                      Text(
                        "Enter your email and we'll send a reset code",
                        style: GoogleFonts.outfit(
                          fontSize: AppSizes.fontM,
                          color: AppColors.textSecondary,
                          height: AppSizes.lineHeightNormal,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing4XL),
                      AuthTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        controller: ctrl.forgotEmailController,
                        validator: ctrl.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                      ),
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
                                : ctrl.forgotPassword,
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
                                      'Send Reset Code',
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
