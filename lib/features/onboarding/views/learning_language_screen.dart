import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/language_card.dart';

class LearningLanguageScreen extends BaseScreen<OnboardingController> {
  const LearningLanguageScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.background;

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'language_select_title'.tr,
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: AppSizes.trackingSnug,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: AppSizes.spacingS),
              AppText(
                'language_select_subtitle'.tr,
                variant: AppTextVariant.bodyMedium,
                color: AppColors.textSecondary,
                height: AppSizes.lineHeightNormal,
                textAlign: TextAlign.left,
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
              return _buildError();
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

  Widget _buildError() {
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
