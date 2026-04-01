import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'app_text.dart';
import 'app_button.dart';

/// Generic empty state with icon, title, subtitle, and optional CTA.
/// Use for empty lists, no data, offline states, etc.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.icon4XL + AppSizes.space4,
              height: AppSizes.icon4XL + AppSizes.space4,
              decoration: const BoxDecoration(
                color: AppColors.primarySoftColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppSizes.icon3XL,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.space6),
            AppText(
              title,
              variant: AppTextVariant.h3,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.space2),
              AppText(
                subtitle!,
                variant: AppTextVariant.bodyMedium,
                color: AppColors.textSecondaryColor,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.space6),
              AppButton(
                text: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
                variant: AppButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
