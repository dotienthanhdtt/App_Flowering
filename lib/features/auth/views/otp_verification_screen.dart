import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/otp_input_field.dart';

/// Screen 13 — OTP verification with 6-box input, countdown timer, resend.
class OtpVerificationScreen extends BaseScreen<ForgotPasswordController> {
  const OtpVerificationScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    final otpKey = GlobalKey<OtpInputFieldState>();

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
                      '${'otp_subtitle'.tr} ${controller.maskedEmail}',
                      variant: AppTextVariant.bodyMedium,
                      color: AppColors.textSecondaryColor,
                      height: AppSizes.lineHeightNormal,
                    )),
                const SizedBox(height: AppSizes.spacing4XL),
                Obx(() => OtpInputField(
                      key: otpKey,
                      onCompleted: controller.isLoading.value
                          ? (_) {}
                          : (otp) async {
                              await controller.verifyOtp(otp);
                              if (controller.errorMessage.value.isNotEmpty) {
                                otpKey.currentState?.clear();
                              }
                            },
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
                const SizedBox(height: AppSizes.spacing4XL),
                // Loading indicator while verifying
                Obx(() => controller.isLoading.value
                    ? const Center(
                        child: SizedBox(
                          width: AppSizes.iconXL,
                          height: AppSizes.iconXL,
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
                const SizedBox(height: AppSizes.spacingXXL),
                // Resend / countdown row
                Obx(() {
                  final seconds = controller.otpCountdown.value;
                  final canResend = seconds == 0;
                  final minutes = seconds ~/ 60;
                  final secs = seconds % 60;
                  final label = canResend
                      ? '${'otp_didnt_receive'.tr} '
                      : '${'otp_resend_in_timer'.tr} $minutes:${secs.toString().padLeft(2, '0')} — ';

                  return Center(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.fontM,
                          color: AppColors.textSecondaryColor,
                        ),
                        children: [
                          TextSpan(text: label),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: canResend ? controller.resendOtp : null,
                              child: AppText(
                                'otp_resend'.tr,
                                variant: AppTextVariant.bodyMedium,
                                fontWeight: FontWeight.w600,
                                color: canResend
                                    ? AppColors.primaryColor
                                    : AppColors.textTertiaryColor,
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
    );
  }
}
