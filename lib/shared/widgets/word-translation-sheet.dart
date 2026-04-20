import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../models/word-translation-model.dart';
import 'app_text.dart';
import 'word-translation-content.dart';
import 'word-translation-header.dart';
import 'word-translation-states.dart';

/// Bottom sheet displaying word translation details (design 08a).
/// States: loading (data==null, error==null), error, populated.
class WordTranslationSheet extends StatelessWidget {
  final String word;
  final WordTranslationModel? data;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onSave;

  const WordTranslationSheet({
    super.key,
    required this.word,
    this.data,
    this.error,
    this.onRetry,
    this.onClose,
    this.onPlayAudio,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.space6, AppSizes.space4, AppSizes.space6, AppSizes.space8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              const SizedBox(height: AppSizes.space4),
              WordTranslationHeader(
                word: word,
                onPlayAudio: onPlayAudio,
                onClose: onClose,
              ),
              if (error != null) ...[
                const SizedBox(height: AppSizes.space6),
                WordTranslationErrorState(onRetry: onRetry),
              ] else if (data == null) ...[
                const SizedBox(height: AppSizes.space6),
                const WordTranslationLoadingState(),
              ] else ...[
                WordTranslationContent(data: data!),
                if (onSave != null) ...[
                  const SizedBox(height: AppSizes.space4),
                  _WordTranslationSaveButton(onSave: onSave),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderStrongColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
        ),
      ),
    );
  }
}

/// Save-to-words button rendered at the bottom of [WordTranslationSheet].
class _WordTranslationSaveButton extends StatelessWidget {
  final VoidCallback? onSave;

  const _WordTranslationSaveButton({this.onSave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSave,
      child: Container(
        height: AppSizes.buttonHeightLarge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppColors.primaryColor, width: AppSizes.borderMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, color: AppColors.primaryColor, size: AppSizes.iconL),
            const SizedBox(width: AppSizes.space2),
            AppText(
              'chat_save_to_words'.tr,
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
