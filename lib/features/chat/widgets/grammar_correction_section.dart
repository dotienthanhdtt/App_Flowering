import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

/// Standalone grammar correction card shown below user bubble.
/// Red border with sparkles icon and corrected text.
class GrammarCorrectionSection extends StatelessWidget {
  final String correctedText;

  const GrammarCorrectionSection({
    super.key,
    required this.correctedText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.all(AppSizes.space2),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border.all(color: AppColors.errorColor, width: AppSizes.borderThin),
        borderRadius: BorderRadius.circular(AppSizes.buttonRadiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: AppSizes.iconSM,
            color: AppColors.errorColor,
          ),
          const SizedBox(width: AppSizes.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'chat_try_instead'.tr,
                  fontSize: AppSizes.fontSizeXSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.errorColor,
                ),
                const SizedBox(height: AppSizes.space1),
                AppText(
                  correctedText,
                  fontSize: AppSizes.fontSizeSmall,
                  color: AppColors.textPrimaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
