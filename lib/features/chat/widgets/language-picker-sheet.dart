import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../../onboarding/models/onboarding_language_model.dart';
import 'language-picker-row.dart';

/// Bottom sheet listing the user's enrolled learning languages.
/// The active language is highlighted with a check icon; others show a chevron.
///
/// Open via [show] which wraps `showModalBottomSheet` with the correct styling.
class LanguagePickerSheet extends StatelessWidget {
  final List<OnboardingLanguage> languages;
  final String? activeCode;
  final ValueChanged<OnboardingLanguage> onSelect;

  const LanguagePickerSheet({
    super.key,
    required this.languages,
    required this.activeCode,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required List<OnboardingLanguage> languages,
    required String? activeCode,
    required ValueChanged<OnboardingLanguage> onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguagePickerSheet(
        languages: languages,
        activeCode: activeCode,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.7;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXL),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            Flexible(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: AppSizes.space3),
      decoration: BoxDecoration(
        color: AppColors.borderColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space5,
        AppSizes.space4,
        AppSizes.space3,
        AppSizes.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              'language_picker_title'.tr,
              variant: AppTextVariant.h2,
              fontSize: AppSizes.fontSizeXLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryColor,
            ),
          ),
          Semantics(
            label: 'language_picker_close'.tr,
            button: true,
            child: IconButton(
              icon: const Icon(
                LucideIcons.x,
                size: AppSizes.iconL,
                color: AppColors.textSecondaryColor,
              ),
              onPressed: () => Navigator.of(Get.overlayContext ?? Get.context!).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (languages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.space6),
        child: AppText(
          'language_picker_empty'.tr,
          variant: AppTextVariant.bodyMedium,
          color: AppColors.textSecondaryColor,
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space4,
        AppSizes.space1,
        AppSizes.space4,
        AppSizes.space5,
      ),
      itemCount: languages.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.space3),
      itemBuilder: (_, i) {
        final lang = languages[i];
        return LanguagePickerRow(
          language: lang,
          isActive: lang.code == activeCode,
          onTap: () {
            onSelect(lang);
            Navigator.of(Get.overlayContext ?? Get.context!).pop();
          },
        );
      },
    );
  }
}
