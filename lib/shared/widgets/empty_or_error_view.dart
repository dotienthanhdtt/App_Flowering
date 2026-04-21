import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'app_text.dart';

/// Shared empty/error placeholder: icon + message + optional retry action.
/// Replaces the identical `_EmptyOrError` widgets that previously lived
/// inside each feed tab file.
class EmptyOrErrorView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const EmptyOrErrorView({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSizes.icon3XL,
              color: AppColors.textTertiaryColor,
            ),
            const SizedBox(height: AppSizes.space4),
            AppText(
              message,
              variant: AppTextVariant.bodyMedium,
              color: AppColors.textTertiaryColor,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.space4),
              TextButton(
                onPressed: onRetry,
                child: AppText(
                  retryLabel ?? '',
                  variant: AppTextVariant.button,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
