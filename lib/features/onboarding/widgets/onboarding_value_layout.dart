import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text.dart';
class OnboardingValueLayout extends StatelessWidget {
  final String imagePath;
  final String headlineKey;
  final String bodyKey;
  final String ctaKey;
  final AppButtonVariant ctaVariant;
  final VoidCallback onCtaPressed;

  const OnboardingValueLayout({
    super.key,
    required this.imagePath,
    required this.headlineKey,
    required this.bodyKey,
    required this.ctaKey,
    required this.ctaVariant,
    required this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            _buildSkipRow(),
            Image.asset(imagePath, width: double.infinity, fit: BoxFit.contain),
            const SizedBox(height: AppSizes.spacing4XL),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL),
                child: Column(
                  children: [
                    AppText(
                      headlineKey.tr,
                      variant: AppTextVariant.h1,
                      fontSize: AppSizes.font8XL,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                      color: AppColors.textPrimaryColor,
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    AppText(
                      bodyKey.tr,
                      variant: AppTextVariant.bodyLarge,
                      fontSize: AppSizes.font3XL,
                      textAlign: TextAlign.center,
                      color: AppColors.neutralColor,
                      height: AppSizes.lineHeightRelaxed,
                    ),
                    const Spacer(),
                    AppButton(
                      text: ctaKey.tr,
                      variant: ctaVariant,
                      height: AppSizes.buttonHeightM,
                      onPressed: onCtaPressed,
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + AppSizes.spacing4XL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipRow() {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.paddingL),
      child: SizedBox(
        height: AppSizes.topBarHeight,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Get.offNamed(AppRoutes.onboardingNativeLanguage),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingL,
                vertical: AppSizes.paddingXS,
              ),
              child: AppText(
                'onboarding_skip'.tr,
                variant: AppTextVariant.bodyMedium,
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.w600,
                color: AppColors.neutralColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
