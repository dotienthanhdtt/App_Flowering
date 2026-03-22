import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

/// Context card shown at top of chat when a scenario description exists.
/// Orange/warning background with message-circle icon.
class ChatContextCard extends StatelessWidget {
  final String description;

  const ChatContextCard({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space4),
      decoration: BoxDecoration(
        color: AppColors.warningLightColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: AppSizes.iconL,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: AppSizes.space2),
          Expanded(
            child: AppText(
              description,
              fontSize: AppSizes.fontSizeMedium,
              color: AppColors.textPrimaryColor,
              height: AppSizes.lineHeightMedium,
            ),
          ),
        ],
      ),
    );
  }
}
