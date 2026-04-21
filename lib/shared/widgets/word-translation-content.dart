import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../models/word-translation-model.dart';
import 'app_text.dart';

/// Populated content for [WordTranslationSheet]:
/// pronunciation row, divider, translation, definition, examples.
class WordTranslationContent extends StatelessWidget {
  final WordTranslationModel data;

  const WordTranslationContent({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pronunciation + POS
        if (data.pronunciation != null || data.partOfSpeech != null) ...[
          const SizedBox(height: AppSizes.space1),
          _PronunciationRow(model: data),
        ],
        const SizedBox(height: AppSizes.space3),
        const Divider(height: 1, color: AppColors.borderLightColor),
        const SizedBox(height: AppSizes.space3),
        // Translation
        _TranslationSection(translation: data.translation),
        // Definition
        if (data.definition != null && data.definition!.isNotEmpty) ...[
          const SizedBox(height: AppSizes.space4),
          _DefinitionSection(definition: data.definition!),
        ],
        // Examples
        if (data.examples.isNotEmpty) ...[
          const SizedBox(height: AppSizes.space4),
          _ExamplesSection(examples: data.examples),
        ],
      ],
    );
  }
}

class _PronunciationRow extends StatelessWidget {
  final WordTranslationModel model;

  const _PronunciationRow({required this.model});

  @override
  Widget build(BuildContext context) {
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
}

class _TranslationSection extends StatelessWidget {
  final String translation;

  const _TranslationSection({required this.translation});

  @override
  Widget build(BuildContext context) {
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
}

class _DefinitionSection extends StatelessWidget {
  final String definition;

  const _DefinitionSection({required this.definition});

  @override
  Widget build(BuildContext context) {
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
}

class _ExamplesSection extends StatelessWidget {
  final List<String> examples;

  const _ExamplesSection({required this.examples});

  @override
  Widget build(BuildContext context) {
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
}

