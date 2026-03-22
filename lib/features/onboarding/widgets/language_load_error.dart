import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

/// Error state with retry button for language list screens.
class LanguageLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const LanguageLoadError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            'language_load_error'.tr,
            variant: AppTextVariant.bodyMedium,
            color: AppColors.textSecondaryColor,
          ),
          const SizedBox(height: AppSizes.space4),
          GestureDetector(
            onTap: onRetry,
            child: AppText(
              'retry'.tr,
              variant: AppTextVariant.label,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
