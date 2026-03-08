import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/otp_input_field.dart';

/// Screen 13 — OTP verification with 6-box input, countdown timer, resend.
class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ForgotPasswordController>();
    final otpKey = GlobalKey<OtpInputFieldState>();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      'otp_title'.tr,
                      variant: AppTextVariant.h2,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: AppSizes.spacingSM),
                    Obx(() => AppText(
                          'We sent a 6-digit code to ${ctrl.maskedEmail}',
                          variant: AppTextVariant.bodyMedium,
                          color: AppColors.textSecondary,
                          height: AppSizes.lineHeightNormal,
                        )),
                    const SizedBox(height: AppSizes.spacing4XL),
                    Obx(() => OtpInputField(
                          key: otpKey,
                          onCompleted: ctrl.isLoading.value
                              ? (_) {}
                              : (otp) async {
                                  await ctrl.verifyOtp(otp);
                                  if (ctrl.errorMessage.value.isNotEmpty) {
                                    otpKey.currentState?.clear();
                                  }
                                },
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
                    const SizedBox(height: AppSizes.spacing4XL),
                    // Loading indicator while verifying
                    Obx(() => ctrl.isLoading.value
                        ? const Center(
                            child: SizedBox(
                              width: AppSizes.iconXL,
                              height: AppSizes.iconXL,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
                    const SizedBox(height: AppSizes.spacingXXL),
                    // Resend / countdown row
                    Obx(() {
                      final seconds = ctrl.otpCountdown.value;
                      final canResend = seconds == 0;
                      final minutes = seconds ~/ 60;
                      final secs = seconds % 60;
                      final label = canResend
                          ? "Didn't receive the code? "
                          : 'Resend in $minutes:${secs.toString().padLeft(2, '0')} — ';

                      return Center(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: AppSizes.fontM,
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              TextSpan(text: label),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: canResend ? ctrl.resendOtp : null,
                                  child: AppText(
                                    'otp_resend'.tr,
                                    variant: AppTextVariant.bodyMedium,
                                    fontWeight: FontWeight.w600,
                                    color: canResend
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
