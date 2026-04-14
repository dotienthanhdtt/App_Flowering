import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text.dart';
import '../../auth/widgets/login_gate_bottom_sheet.dart';
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
            _buildSkipRow(context),
            Image.asset(imagePath, width: double.infinity, fit: BoxFit.contain),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.space6),
                child: Column(
                  children: [
                    AppText(
                      headlineKey.tr,
                      variant: AppTextVariant.h1,
                      fontSize: AppSizes.fontSize3XLarge,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                      color: AppColors.textPrimaryColor,
                    ),
                    const SizedBox(height: AppSizes.space3),
                    AppText(
                      bodyKey.tr,
                      variant: AppTextVariant.bodyLarge,
                      fontSize: AppSizes.fontSizeLarge,
                      textAlign: TextAlign.center,
                      color: AppColors.neutralColor,
                      height: AppSizes.lineHeightLarge,
                    ),
                    const Spacer(),
                    AppButton(
                      text: ctaKey.tr,
                      variant: ctaVariant,
                      height: AppSizes.buttonHeightLarge,
                      onPressed: onCtaPressed,
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + AppSizes.space8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.space4),
      child: SizedBox(
        height: AppSizes.topBarHeight,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const LoginGateBottomSheet(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space4,
                vertical: AppSizes.space2,
              ),
              child: AppText(
                'onboarding_skip'.tr,
                variant: AppTextVariant.bodyMedium,
                fontSize: AppSizes.fontSizeMedium,
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
