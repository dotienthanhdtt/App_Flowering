import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../models/word-translation-model.dart';
import 'app_text.dart';
import 'loading_widget.dart';

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
              _buildHeader(),
              if (error != null) ...[
                const SizedBox(height: AppSizes.space6),
                _buildError(),
              ] else if (data == null) ...[
                const SizedBox(height: AppSizes.space6),
                _buildLoading(),
              ] else ...[
                _buildContent(),
                if (onSave != null) ...[
                  const SizedBox(height: AppSizes.space4),
                  _buildSaveButton(),
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

  Widget _buildHeader() {
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
        _CircleButton(
          color: AppColors.primarySoftColor,
          icon: Icons.volume_up_rounded,
          iconColor: AppColors.primaryColor,
          onTap: onPlayAudio,
        ),
        const SizedBox(width: AppSizes.space2),
        _CircleButton(
          color: AppColors.surfaceMutedColor,
          icon: Icons.close,
          iconColor: AppColors.textTertiaryColor,
          onTap: onClose,
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const LoadingWidget(size: 48);
  }

  Widget _buildError() {
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

  Widget _buildContent() {
    final model = data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pronunciation + POS
        if (model.pronunciation != null || model.partOfSpeech != null) ...[
          const SizedBox(height: AppSizes.space1),
          _buildPronunciationRow(model),
        ],
        const SizedBox(height: AppSizes.space3),
        const Divider(height: 1, color: AppColors.borderLightColor),
        const SizedBox(height: AppSizes.space3),
        // Translation
        _buildTranslation(model.translation),
        // Definition
        if (model.definition != null && model.definition!.isNotEmpty) ...[
          const SizedBox(height: AppSizes.space4),
          _buildDefinition(model.definition!),
        ],
        // Examples
        if (model.examples.isNotEmpty) ...[
          const SizedBox(height: AppSizes.space4),
          _buildExamples(model.examples),
        ],
      ],
    );
  }

  Widget _buildPronunciationRow(WordTranslationModel model) {
    return Row(
      children: [
        if (model.pronunciation != null)
          AppText(
            model.pronunciation!,
            variant: AppTextVariant.bodyMedium,
            color: AppColors.textTertiaryColor,
          ),
        if (model.pronunciation != null && model.partOfSpeech != null)
          const SizedBox(width: AppSizes.space2),
        if (model.partOfSpeech != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space2,
              vertical: AppSizes.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondaryLightColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: AppText(
              model.partOfSpeech!,
              variant: AppTextVariant.caption,
              fontSize: AppSizes.fontSizeXSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryDarkColor,
            ),
          ),
      ],
    );
  }

  Widget _buildTranslation(String translation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.language, size: AppSizes.iconXS, color: AppColors.secondaryColor),
            const SizedBox(width: AppSizes.space1),
            AppText(
              'word_translation_title'.tr,
              variant: AppTextVariant.bodySmall,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryColor,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space1),
        AppText(
          translation,
          variant: AppTextVariant.bodyLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryColor,
        ),
      ],
    );
  }

  Widget _buildDefinition(String definition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'word_definition_label'.tr,
          variant: AppTextVariant.caption,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: AppSizes.space1),
        AppText(
          definition,
          variant: AppTextVariant.bodyMedium,
          color: AppColors.textSecondaryColor,
          height: AppSizes.lineHeightBase,
        ),
      ],
    );
  }

  Widget _buildExamples(List<String> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'word_examples_label'.tr,
          variant: AppTextVariant.caption,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: AppSizes.space2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.space3),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: examples
                .map((ex) => Padding(
                      padding: EdgeInsets.only(
                        bottom: ex != examples.last ? AppSizes.space2 : 0,
                      ),
                      child: AppText(
                        ex,
                        variant: AppTextVariant.bodySmall,
                        fontSize: AppSizes.fontSizeSmall,
                        color: AppColors.textSecondaryColor,
                        fontStyle: FontStyle.italic,
                        height: AppSizes.lineHeightBase,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
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

class _CircleButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _CircleButton({
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
