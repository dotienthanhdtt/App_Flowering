import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_button.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/language_selection_layout.dart';

class LearningLanguageScreen extends BaseScreen<OnboardingController> {
  const LearningLanguageScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    return Obx(() => LanguageSelectionLayout(
          title: 'language_select_title'.tr,
          isLoading: controller.isLoadingLanguages.value,
          languages: controller.learningLanguages,
          selectedCode: controller.selectedLearningLanguage.value,
          onSelect: (lang) =>
              controller.selectLearningLanguage(lang.code, id: lang.id),
          onRetry: controller.loadLanguages,
          skeletonCount: 6,
          topBar: _buildBackButton(),
          bottomWidget: _buildContinueButton(context),
        ));
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
      child: SizedBox(
        height: AppSizes.buttonHeightMedium,
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back,
              size: 24,
              color: AppColors.textSecondaryColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    final hasSelection =
        controller.selectedLearningLanguage.value.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.space4,
        right: AppSizes.space4,
        bottom: MediaQuery.of(context).padding.bottom + AppSizes.space8,
      ),
      child: Opacity(
        opacity: hasSelection ? 1.0 : 0.5,
        child: AppButton(
          text: 'continue_button'.tr,
          variant: AppButtonVariant.primary,
          height: AppSizes.buttonHeightLarge,
          onPressed: hasSelection ? controller.confirmLearningLanguage : null,
        ),
      ),
    );
  }
}
