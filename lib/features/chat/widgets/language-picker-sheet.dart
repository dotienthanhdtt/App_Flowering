import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../../onboarding/models/onboarding_language_model.dart';

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
        return _PickerRow(
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

/// Row matching design `tLfyG` (Language Card). Kept private to the sheet so
/// the shared onboarding [LanguageListCard] stays focused on its own use case.
class _PickerRow extends StatelessWidget {
  final OnboardingLanguage language;
  final bool isActive;
  final VoidCallback onTap;

  const _PickerRow({
    required this.language,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: language.isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: language.isEnabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(
              color: isActive ? AppColors.primaryColor : AppColors.borderLightColor,
              width: isActive ? AppSizes.borderMedium : AppSizes.borderThin,
            ),
          ),
          child: Row(
            children: [
              _buildFlag(),
              const SizedBox(width: AppSizes.cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      language.name,
                      variant: AppTextVariant.bodyLarge,
                      fontSize: AppSizes.cardTitleFont,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryColor,
                    ),
                    if (language.subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.space1),
                      AppText(
                        language.subtitle,
                        variant: AppTextVariant.bodySmall,
                        fontSize: AppSizes.cardSubtitleFont,
                        color: AppColors.textSecondaryColor,
                      ),
                    ],
                  ],
                ),
              ),
              _buildTrailing(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlag() {
    const size = AppSizes.cardFlagSizeLarge;
    final url = language.flagUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) =>
              Text(language.flag, style: const TextStyle(fontSize: size * 0.65)),
          placeholder: (_, _) =>
              Text(language.flag, style: const TextStyle(fontSize: size * 0.65)),
        ),
      );
    }
    return Text(language.flag, style: const TextStyle(fontSize: size * 0.65));
  }

  Widget _buildTrailing() {
    if (isActive) {
      return const Icon(
        LucideIcons.check,
        size: AppSizes.cardChevronSize,
        color: AppColors.primaryColor,
      );
    }
    return const Icon(
      LucideIcons.chevronRight,
      size: AppSizes.cardChevronSize,
      color: AppColors.textSecondaryColor,
    );
  }
}
