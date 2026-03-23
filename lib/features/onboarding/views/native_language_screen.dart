import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/language_selection_layout.dart';

class NativeLanguageScreen extends BaseScreen<OnboardingController> {
  const NativeLanguageScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    return Obx(() => LanguageSelectionLayout(
          title: 'native_language_title'.tr,
          isLoading: controller.isLoadingLanguages.value,
          languages: controller.filteredNativeLanguages,
          selectedCode: controller.selectedNativeLanguage.value,
          onSelect: (lang) =>
              controller.selectNativeLanguage(lang.code, id: lang.id),
          onRetry: controller.loadLanguages,
          searchField: AppTextField(
            hint: 'search_language'.tr,
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.textTertiaryColor,
              size: 20,
            ),
            onChanged: (value) =>
                controller.nativeSearchQuery.value = value,
          ),
        ));
  }
}
