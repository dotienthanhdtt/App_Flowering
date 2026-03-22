import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

/// Text button with leading icon for message actions.
class TextActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const TextActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
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
      ),
    );
  }
}
