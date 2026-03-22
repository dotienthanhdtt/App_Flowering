import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final VoidCallback? onTap;

  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: size ?? AppSizes.iconXL,
      color: color ?? AppColors.textPrimaryColor,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.space2),
          child: iconWidget,
        ),
      );
    }

    return iconWidget;
  }
}
