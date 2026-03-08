import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';

/// Single conversation tile in chat home list
class ChatConversationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timestamp;
  final VoidCallback onTap;

  const ChatConversationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.paddingSM,
          horizontal: AppSizes.paddingXS,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: AppSizes.avatarM / 2,
              backgroundColor: AppColors.primarySoft,
              child: const Icon(
                LucideIcons.messageCircle,
                size: AppSizes.iconSM,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label),
                  const SizedBox(height: AppSizes.spacingXXS),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(timestamp, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
