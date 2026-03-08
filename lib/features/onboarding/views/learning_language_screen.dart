import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/language_card.dart';

class LearningLanguageScreen extends StatelessWidget {
  const LearningLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.inputHeight,
                left: AppSizes.paddingXXL,
                right: AppSizes.paddingXXL,
                bottom: AppSizes.paddingXXL,
              ),
              child: Column(
                children: [
                  AppText(
                    'language_select_title'.tr,
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: AppSizes.trackingSnug,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  AppText(
                    'language_select_subtitle'.tr,
                    variant: AppTextVariant.bodyMedium,
                    color: AppColors.textSecondary,
                    height: AppSizes.lineHeightNormal,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Language grid
            Expanded(
              child: Obx(() {
                if (controller.isLoadingLanguages.value) {
                  return _buildSkeleton();
                }
                if (controller.learningLanguages.isEmpty) {
                  return _buildError(controller);
                }
                return GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSizes.spacingL,
                  crossAxisSpacing: AppSizes.spacingL,
                  childAspectRatio: 0.95,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL),
                  children: controller.learningLanguages.map((lang) {
                    return LanguageGridCard(
                      language: lang,
                      isSelected:
                          controller.selectedLearningLanguage.value == lang.code,
                      onTap: () => controller.selectLearningLanguage(
                        lang.code,
                        id: lang.id,
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSizes.spacingL,
      crossAxisSpacing: AppSizes.spacingL,
      childAspectRatio: 0.95,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL),
      children: List.generate(
        6,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            border: Border.all(color: AppColors.borderLight),
          ),
        ),
      ),
    );
  }

  Widget _buildError(OnboardingController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            'language_load_error'.tr,
            variant: AppTextVariant.bodyMedium,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSizes.spacingL),
          GestureDetector(
            onTap: controller.loadLanguages,
            child: AppText(
              'retry'.tr,
              variant: AppTextVariant.label,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
