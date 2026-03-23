import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

/// Text button with leading icon for message actions.
/// Supports optional pill-shaped background.
class TextActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool hasPillBackground;

  const TextActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.hasPillBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconXS, color: color),
        const SizedBox(width: AppSizes.space1),
        AppText(
          label,
          variant: AppTextVariant.caption,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: hasPillBackground
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space2,
                vertical: AppSizes.space1,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(AppSizes.buttonRadiusSmall),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowLightColor,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: content,
            )
          : content,
    );
  }
}
