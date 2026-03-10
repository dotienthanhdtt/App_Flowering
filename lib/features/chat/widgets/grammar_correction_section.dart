import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

/// Correction section shown inside user bubble when grammar errors are found.
/// Displays corrected text with a green "Corrected" label and Hide/Show toggle.
class GrammarCorrectionSection extends StatelessWidget {
  final String correctedText;
  final bool isExpanded;
  final VoidCallback onToggle;

  const GrammarCorrectionSection({
    super.key,
    required this.correctedText,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: AppSizes.borderThin,
          color: AppColors.primaryLight,
        ),
        const SizedBox(height: AppSizes.spacingS),
        if (isExpanded) ...[
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: AppSizes.iconXXS,
                color: AppColors.accentGreenDark,
              ),
              const SizedBox(width: AppSizes.spacingXS),
              AppText(
                'corrected'.tr,
                fontSize: AppSizes.fontXXS,
                fontWeight: FontWeight.w600,
                color: AppColors.accentGreenDark,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingXS),
          AppText(
            correctedText,
            fontSize: AppSizes.fontSM,
            color: Colors.white,
            height: AppSizes.lineHeightLoose,
          ),
          const SizedBox(height: AppSizes.spacingS),
        ],
        GestureDetector(
          onTap: onToggle,
          child: AppText(
            isExpanded ? 'hide'.tr : 'show'.tr,
            fontSize: AppSizes.fontXS,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryLight,
          ),
        ),
      ],
    );
  }
}
