import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/onboarding_language_model.dart';

/// Reusable list card for language selection screens (06 & 07).
///
/// [flagSize] — 36 for native language (screen 06), 48 for learning (screen 07).
/// [cardPadding] — 12 for native, 16 for learning.
class LanguageListCard extends StatelessWidget {
  final OnboardingLanguage language;
  final bool isSelected;
  final VoidCallback? onTap;
  final double flagSize;
  final double cardPadding;

  const LanguageListCard({
    super.key,
    required this.language,
    required this.isSelected,
    this.onTap,
    this.flagSize = 36,
    this.cardPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: language.isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: language.isEnabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(
              color: AppColors.borderLightColor,
              width: AppSizes.borderThin,
            ),
          ),
          child: Row(
            children: [
              LanguageFlag(language: language, size: flagSize),
              const SizedBox(width: AppSizes.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      language.name,
                      variant: AppTextVariant.bodyLarge,
                      fontSize: AppSizes.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryColor,
                    ),
                    const SizedBox(height: AppSizes.space1),
                    AppText(
                      language.subtitle,
                      variant: AppTextVariant.bodySmall,
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textSecondaryColor,
                    ),
                  ],
                ),
              ),
              if (!language.isEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space2,
                    vertical: AppSizes.space1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningLightColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: AppText(
                    'language_coming_soon'.tr,
                    variant: AppTextVariant.caption,
                    fontSize: AppSizes.fontSizeXSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warningColor,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays a language flag — network image from [flagUrl] with emoji fallback.
class LanguageFlag extends StatelessWidget {
  final OnboardingLanguage language;
  final double size;

  const LanguageFlag({super.key, required this.language, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = language.flagUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) =>
              Text(language.flag, style: TextStyle(fontSize: size * 0.65)),
          placeholder: (_, _) =>
              Text(language.flag, style: TextStyle(fontSize: size * 0.65)),
        ),
      );
    }
    return Text(language.flag, style: TextStyle(fontSize: size * 0.65));
  }
}
