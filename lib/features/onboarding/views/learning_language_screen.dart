import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/language_card.dart';
import '../widgets/language_list_skeleton.dart';
import '../widgets/language_load_error.dart';

class LearningLanguageScreen extends BaseScreen<OnboardingController> {
  const LearningLanguageScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back arrow
        Padding(
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
        ),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
          child: AppText(
            'language_select_title'.tr,
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: AppSizes.trackingSnug,
            ),
            textAlign: TextAlign.left,
          ),
        ),

        const SizedBox(height: AppSizes.space6),

        // Language list + show all
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
            child: Obx(() {
              if (controller.isLoadingLanguages.value) {
                return const LanguageListSkeleton(itemCount: 6);
              }
              if (controller.learningLanguages.isEmpty) {
                return LanguageLoadError(onRetry: controller.loadLanguages);
              }
              final languages = controller.visibleLearningLanguages;
              return ListView(
                children: [
                  ...List.generate(languages.length, (index) {
                    final lang = languages[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < languages.length - 1
                            ? AppSizes.space2
                            : 0,
                      ),
                      child: LanguageListCard(
                        language: lang,
                        isSelected:
                            controller.selectedLearningLanguage.value ==
                                lang.code,
                        flagSize: AppSizes.avatarXL,
                        cardPadding: AppSizes.space4,
                        onTap: () => controller.selectLearningLanguage(
                          lang.code,
                          id: lang.id,
                        ),
                      ),
                    );
                  }),
                  // Show all button
                  if (controller.canShowMoreLanguages)
                    _buildShowAllButton(),
                ],
              );
            }),
          ),
        ),

        // Continue button
        _buildContinueButton(context),
      ],
    );
  }

  Widget _buildShowAllButton() {
    return GestureDetector(
      onTap: controller.toggleShowAllLanguages,
      child: Container(
        height: 36,
        margin: const EdgeInsets.only(top: AppSizes.space2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              'show_all_languages'.tr,
              variant: AppTextVariant.bodySmall,
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryColor,
            ),
            const SizedBox(width: AppSizes.space1),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: AppColors.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Obx(() {
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
            onPressed:
                hasSelection ? controller.confirmLearningLanguage : null,
          ),
        ),
      );
    });
  }
}
