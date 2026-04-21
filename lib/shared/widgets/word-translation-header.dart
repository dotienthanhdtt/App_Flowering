import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'app_text.dart';

/// Header row for WordTranslationSheet: word title + audio + close buttons.
class WordTranslationHeader extends StatelessWidget {
  final String word;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onClose;

  const WordTranslationHeader({
    super.key,
    required this.word,
    this.onPlayAudio,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppText(
            word,
            variant: AppTextVariant.h2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSizes.space2),
        WordTranslationCircleButton(
          color: AppColors.primarySoftColor,
          icon: Icons.volume_up_rounded,
          iconColor: AppColors.primaryColor,
          onTap: onPlayAudio,
        ),
        const SizedBox(width: AppSizes.space2),
        WordTranslationCircleButton(
          color: AppColors.surfaceMutedColor,
          icon: Icons.close,
          iconColor: AppColors.textTertiaryColor,
          onTap: onClose,
        ),
      ],
    );
  }
}

/// Small circular icon button used in [WordTranslationHeader].
/// Intended for internal use within the word-translation widget family.
class WordTranslationCircleButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const WordTranslationCircleButton({
    super.key,
    required this.color,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.avatarM,
        height: AppSizes.avatarM,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: AppSizes.iconSM, color: iconColor),
      ),
    );
  }
}
