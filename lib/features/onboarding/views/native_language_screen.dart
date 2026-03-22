import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/language_card.dart';

class NativeLanguageScreen extends BaseScreen<OnboardingController> {
  const NativeLanguageScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.space4, left: AppSizes.space6),
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: AppSizes.buttonHeightMedium,
              height: AppSizes.buttonHeightMedium,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                border: Border.all(color: AppColors.borderLightColor),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.textPrimaryColor,
              ),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.only(
            top: AppSizes.space6,
            left: AppSizes.space6,
            right: AppSizes.space6,
            bottom: AppSizes.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'native_language_title'.tr,
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: AppSizes.trackingSnug,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: AppSizes.space2),
              AppText(
                'native_language_subtitle'.tr,
                variant: AppTextVariant.bodyMedium,
                color: AppColors.textSecondaryColor,
                height: 1.5,
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),

        // Language list
        Expanded(
          child: Obx(() {
            if (controller.isLoadingLanguages.value) {
              return _buildSkeleton();
            }
            if (controller.nativeLanguages.isEmpty) {
              return _buildError();
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space6,
                vertical: AppSizes.space2,
              ),
              itemCount: controller.nativeLanguages.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSizes.space3),
              itemBuilder: (context, index) {
                final lang = controller.nativeLanguages[index];
                return LanguageListCard(
                  language: lang,
                  isSelected:
                      controller.selectedNativeLanguage.value == lang.code,
                  onTap: () =>
                      controller.selectNativeLanguage(lang.code, id: lang.id),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space6, vertical: AppSizes.space2),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.space3),
      itemBuilder: (_, _) => Container(
        height: AppSizes.space16,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: AppColors.borderLightColor),
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
            color: AppColors.textSecondaryColor,
          ),
          const SizedBox(height: AppSizes.space4),
          GestureDetector(
            onTap: controller.loadLanguages,
            child: AppText(
              'retry'.tr,
              variant: AppTextVariant.label,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
