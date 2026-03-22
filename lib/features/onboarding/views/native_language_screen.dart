import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/language_card.dart';
import '../widgets/language_list_skeleton.dart';
import '../widgets/language_load_error.dart';

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
        // Top bar spacer (matches design empty top bar)
        const SizedBox(height: AppSizes.buttonHeightMedium),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
          child: AppText(
            'native_language_title'.tr,
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: AppSizes.trackingSnug,
            ),
            textAlign: TextAlign.left,
          ),
        ),

        const SizedBox(height: AppSizes.space6),

        // Search field + language list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
            child: Column(
              children: [
                // Search input
                AppTextField(
                  hint: 'search_language'.tr,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textTertiaryColor,
                    size: 20,
                  ),
                  onChanged: (value) =>
                      controller.nativeSearchQuery.value = value,
                ),
                const SizedBox(height: AppSizes.space4),

                // Language list
                Expanded(
                  child: Obx(() {
                    if (controller.isLoadingLanguages.value) {
                      return const LanguageListSkeleton();
                    }
                    if (controller.nativeLanguages.isEmpty) {
                      return LanguageLoadError(onRetry: controller.loadLanguages);
                    }
                    final languages = controller.filteredNativeLanguages;
                    return ListView.separated(
                      padding: const EdgeInsets.only(
                        bottom: AppSizes.space8,
                      ),
                      itemCount: languages.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSizes.space2),
                      itemBuilder: (context, index) {
                        final lang = languages[index];
                        return LanguageListCard(
                          language: lang,
                          isSelected:
                              controller.selectedNativeLanguage.value ==
                                  lang.code,
                          flagSize: 36,
                          cardPadding: 12,
                          onTap: () => controller.selectNativeLanguage(
                            lang.code,
                            id: lang.id,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
