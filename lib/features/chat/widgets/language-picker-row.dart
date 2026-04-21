import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../../onboarding/models/onboarding_language_model.dart';

/// Row matching design `tLfyG` (Language Card).
///
/// Internal use: consumed only by [LanguagePickerSheet]. Kept in its own file
/// to respect the 200-line limit. The shared onboarding [LanguageListCard]
/// stays focused on its own use case.
class LanguagePickerRow extends StatelessWidget {
  final OnboardingLanguage language;
  final bool isActive;
  final VoidCallback onTap;

  const LanguagePickerRow({
    super.key,
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
