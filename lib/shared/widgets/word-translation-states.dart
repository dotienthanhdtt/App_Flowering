import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'app_text.dart';
import 'loading_widget.dart';

/// Loading state for [WordTranslationSheet] (data == null, error == null).
class WordTranslationLoadingState extends StatelessWidget {
  const WordTranslationLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingWidget(size: 48);
  }
}

/// Error state for [WordTranslationSheet] with optional retry callback.
class WordTranslationErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const WordTranslationErrorState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText(
          'word_translation_error'.tr,
          variant: AppTextVariant.bodyMedium,
          color: AppColors.textSecondaryColor,
        ),
        const SizedBox(height: AppSizes.space3),
        GestureDetector(
          onTap: onRetry,
          child: AppText(
            'word_translation_retry'.tr,
            variant: AppTextVariant.label,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}
