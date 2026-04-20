import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../onboarding/models/onboarding_language_model.dart';
import '../../onboarding/widgets/language_card.dart' show LanguageFlag;

/// Header button showing the active learning-language flag with a dropdown
/// chevron. Matches `flowering_design.pen` node `mRMes` (Flag & Dropdown).
///
/// Tapping it should open the language picker sheet (caller's responsibility).
/// Renders a placeholder globe icon when [active] is null (first paint before
/// `/languages/user` returns).
class HomeLanguageButton extends StatelessWidget {
  final OnboardingLanguage? active;
  final VoidCallback? onTap;

  const HomeLanguageButton({super.key, required this.active, this.onTap});

  static const double _flagSize = 32;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.space2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFlag(),
            const SizedBox(width: AppSizes.space1),
            const Icon(
              LucideIcons.chevronDown,
              size: AppSizes.iconL,
              color: AppColors.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlag() {
    if (active == null) {
      return Container(
        width: _flagSize,
        height: _flagSize,
        decoration: const BoxDecoration(
          color: AppColors.surfaceMutedColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.globe,
          size: AppSizes.iconL,
          color: AppColors.textSecondaryColor,
        ),
      );
    }
    return SizedBox(
      width: _flagSize,
      height: _flagSize,
      child: Center(child: LanguageFlag(language: active!, size: _flagSize)),
    );
  }
}
