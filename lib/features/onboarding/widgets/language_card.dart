import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/onboarding_language_model.dart';

/// List variant card for Screen 2A (native language)
class LanguageListCard extends StatelessWidget {
  final OnboardingLanguage language;
  final bool isSelected;
  final VoidCallback? onTap;

  const LanguageListCard({
    super.key,
    required this.language,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: language.isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: language.isEnabled ? onTap : null,
        child: Container(
          height: AppSizes.cardHeightCompact,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : AppSizes.borderThin,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _LanguageFlag(language: language, size: AppSizes.avatarM),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      language.name,
                      variant: AppTextVariant.bodyLarge,
                      fontWeight: FontWeight.w600,
                    ),
                    AppText(
                      language.subtitle,
                      variant: AppTextVariant.bodySmall,
                      fontSize: AppSizes.fontSM,
                    ),
                  ],
                ),
              ),
              if (!language.isEnabled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS, vertical: AppSizes.spacingXS),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: AppText(
                    'language_coming_soon'.tr,
                    variant: AppTextVariant.caption,
                    fontSize: AppSizes.fontXXS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                )
              else if (isSelected)
                Container(
                  width: AppSizes.avatarS,
                  height: AppSizes.avatarS,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: AppSizes.iconXS, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays a language flag — network image from [flagUrl] with emoji fallback.
class _LanguageFlag extends StatelessWidget {
  final OnboardingLanguage language;
  final double size;

  const _LanguageFlag({required this.language, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = language.flagUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        errorWidget: (_, _, _) =>
            Text(language.flag, style: TextStyle(fontSize: size * 0.65)),
        placeholder: (_, _) =>
            Text(language.flag, style: TextStyle(fontSize: size * 0.65)),
      );
    }
    return Text(language.flag, style: TextStyle(fontSize: size * 0.65));
  }
}

/// Grid variant card for Screen 2B (learning language)
class LanguageGridCard extends StatelessWidget {
  final OnboardingLanguage language;
  final VoidCallback? onTap;

  const LanguageGridCard({
    super.key,
    required this.language,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: language.isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: language.isEnabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            border: Border.all(
              color: AppColors.borderLight,
              width: AppSizes.borderThin,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LanguageFlag(language: language, size: AppSizes.avatarXL),
              const SizedBox(height: AppSizes.spacingM),
              AppText(
                language.name,
                variant: AppTextVariant.bodyMedium,
                fontSize: AppSizes.font3XL,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingXS),
              AppText(
                language.subtitle,
                variant: AppTextVariant.caption,
                fontSize: AppSizes.fontXXS,
                fontWeight: language.isEnabled ? FontWeight.w400 : FontWeight.w500,
                color: language.isEnabled ? AppColors.textSecondary : AppColors.textTertiary,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
