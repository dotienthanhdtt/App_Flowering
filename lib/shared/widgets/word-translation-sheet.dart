import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../models/word-translation-model.dart';
import 'app_text.dart';

/// Bottom sheet displaying word translation details (design 08a).
/// States: loading (data==null, error==null), error, populated.
class WordTranslationSheet extends StatelessWidget {
  final String word;
  final WordTranslationModel? data;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final VoidCallback? onPlayAudio;

  const WordTranslationSheet({
    super.key,
    required this.word,
    this.data,
    this.error,
    this.onRetry,
    this.onClose,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingXXL, AppSizes.paddingM, AppSizes.paddingXXL, AppSizes.padding3XL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              const SizedBox(height: AppSizes.spacingL),
              _buildHeader(),
              if (error != null) ...[
                const SizedBox(height: AppSizes.spacingXXL),
                _buildError(),
              ] else if (data == null) ...[
                const SizedBox(height: AppSizes.spacingXXL),
                _buildLoading(),
              ] else ...[
                _buildContent(),
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
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderStrong,
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
        const SizedBox(width: AppSizes.spacingS),
        _CircleButton(
          color: AppColors.primarySoft,
          icon: Icons.volume_up_rounded,
          iconColor: AppColors.primary,
          onTap: onPlayAudio,
        ),
        const SizedBox(width: AppSizes.spacingS),
        _CircleButton(
          color: AppColors.surfaceMuted,
          icon: Icons.close,
          iconColor: AppColors.textTertiary,
          onTap: onClose,
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Column(
      children: [
        AppText(
          'word_translation_error'.tr,
          variant: AppTextVariant.bodyMedium,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: AppSizes.spacingM),
        GestureDetector(
          onTap: onRetry,
          child: AppText(
            'word_translation_retry'.tr,
            variant: AppTextVariant.label,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
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
          const SizedBox(height: AppSizes.spacingXS),
          _buildPronunciationRow(model),
        ],
        const SizedBox(height: AppSizes.spacingM),
        const Divider(height: 1, color: AppColors.borderLight),
        const SizedBox(height: AppSizes.spacingM),
        // Translation
        _buildTranslation(model.translation),
        // Definition
        if (model.definition != null && model.definition!.isNotEmpty) ...[
          const SizedBox(height: AppSizes.spacingL),
          _buildDefinition(model.definition!),
        ],
        // Examples
        if (model.examples.isNotEmpty) ...[
          const SizedBox(height: AppSizes.spacingL),
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
            color: AppColors.textTertiary,
          ),
        if (model.pronunciation != null && model.partOfSpeech != null)
          const SizedBox(width: AppSizes.spacingS),
        if (model.partOfSpeech != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingXS,
              vertical: AppSizes.spacingXXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentBlueLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: AppText(
              model.partOfSpeech!,
              variant: AppTextVariant.caption,
              fontSize: AppSizes.fontXXS,
              fontWeight: FontWeight.w600,
              color: AppColors.accentBlueDark,
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
            const Icon(Icons.language, size: AppSizes.iconXS, color: AppColors.accentBlue),
            const SizedBox(width: AppSizes.spacingXS),
            AppText(
              'word_translation_title'.tr,
              variant: AppTextVariant.bodySmall,
              fontWeight: FontWeight.w600,
              color: AppColors.accentBlue,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingXS),
        AppText(
          translation,
          variant: AppTextVariant.bodyLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
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
        const SizedBox(height: AppSizes.spacingXS),
        AppText(
          definition,
          variant: AppTextVariant.bodyMedium,
          color: AppColors.textSecondary,
          height: AppSizes.lineHeightLoose,
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
        const SizedBox(height: AppSizes.spacingS),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingSM),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: examples
                .map((ex) => Padding(
                      padding: EdgeInsets.only(
                        bottom: ex != examples.last ? AppSizes.spacingS : 0,
                      ),
                      child: AppText(
                        ex,
                        variant: AppTextVariant.bodySmall,
                        fontSize: AppSizes.fontSM,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        height: AppSizes.lineHeightLoose,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
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
