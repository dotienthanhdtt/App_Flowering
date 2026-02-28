import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
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
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusL),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : 1,
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
              Text(language.flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      language.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      language.subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!language.isEnabled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppColors.radiusS),
                  ),
                  child: Text(
                    'Soon',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                )
              else if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid variant card for Screen 2B (learning language)
class LanguageGridCard extends StatelessWidget {
  final OnboardingLanguage language;
  final bool isSelected;
  final VoidCallback? onTap;

  const LanguageGridCard({
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusL),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : 1,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                language.name,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                language.subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: language.isEnabled
                      ? FontWeight.w400
                      : FontWeight.w500,
                  color: language.isEnabled
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
                ),
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
