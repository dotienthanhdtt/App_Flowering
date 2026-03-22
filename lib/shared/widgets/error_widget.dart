import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'app_button.dart';
import 'app_text.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
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
              icon ?? Icons.error_outline,
              size: AppSizes.icon4XL,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: AppSizes.space4),
            AppText(
              message,
              variant: AppTextVariant.bodyLarge,
              textAlign: TextAlign.center,
              color: AppColors.textSecondaryColor,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.space6),
              AppButton(
                text: 'retry'.tr,
                onPressed: onRetry,
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
