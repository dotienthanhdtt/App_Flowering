import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/vocabulary-model.dart';

class VocabularyCard extends StatelessWidget {
  final VocabularyItem item;
  final bool showBox;

  const VocabularyCard({super.key, required this.item, this.showBox = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(color: AppColors.borderLightColor),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSubtleColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  item.word,
                  variant: AppTextVariant.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.space1),
                AppText(
                  item.translation,
                  variant: AppTextVariant.caption,
                  color: AppColors.textSecondaryColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showBox) ...[
            const SizedBox(width: AppSizes.space3),
            _BoxChip(box: item.box),
          ],
        ],
      ),
    );
  }
}

class _BoxChip extends StatelessWidget {
  final int box;

  const _BoxChip({required this.box});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space2,
        vertical: AppSizes.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoftColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: AppText(
        'Box $box',
        variant: AppTextVariant.caption,
        color: AppColors.primaryColor,
      ),
    );
  }
}
