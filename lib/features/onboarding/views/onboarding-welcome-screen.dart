import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  static const Color _accentColor = Color(0xFFFF8762);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SizedBox(height: topPadding),
            // Mascot image
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space6,
              ),
              child: Image.asset(
                'assets/images/onboarding/mascot_welcome.png',
                height: 394,
                fit: BoxFit.contain,
              ),
            ),
            // Headline
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space6,
              ),
              child: AppText(
                'onboarding_welcome_headline'.tr,
                variant: AppTextVariant.h1,
                fontSize: AppSizes.fontSize5XLarge,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
                color: AppColors.textPrimaryColor,
                height: 1.2,
              ),
            ),
            const Spacer(),
            // Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space4,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Get.offNamed(AppRoutes.onboardingWelcome2);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    elevation: 0,
                  ),
                  child: AppText(
                    'get_started'.tr,
                    variant: AppTextVariant.button,
                    fontSize: AppSizes.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.space3),
            // Login row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  'already_have_account'.tr,
                  variant: AppTextVariant.bodyMedium,
                  fontSize: AppSizes.fontSizeMedium,
                  color: AppColors.textPrimaryColor,
                ),
                const SizedBox(width: AppSizes.space1),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.login),
                  child: AppText(
                    'log_in'.tr,
                    variant: AppTextVariant.bodyMedium,
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: bottomPadding + AppSizes.space8),
          ],
        ),
      ),
    );
  }
}
