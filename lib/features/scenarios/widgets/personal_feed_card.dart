import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/personal_scenario_item.dart';
import '../models/scenario_user_status.dart';
import 'source_badge.dart';

/// Text-only row card for the For-You tab.
///
/// Left: accent circle with the first letter of the title. Center: title +
/// difficulty + source badge. Right: a trailing check when `status == learned`.
class PersonalFeedCard extends StatelessWidget {
  final PersonalScenarioItem item;
  final VoidCallback? onTap;

  const PersonalFeedCard({super.key, required this.item, this.onTap});

  static const double _avatarSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final isLearned = item.status == ScenarioUserStatus.learned;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.space3),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: AppColors.borderLightColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: AppSizes.space3),
            Expanded(child: _buildBody(isLearned)),
            if (isLearned) ...[
              const SizedBox(width: AppSizes.space2),
              const Icon(
                LucideIcons.checkCircle,
                size: AppSizes.iconL,
                color: AppColors.successColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final letter = item.title.isNotEmpty ? item.title[0].toUpperCase() : '•';
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: const BoxDecoration(
        color: AppColors.primarySoftColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AppText(
        letter,
        variant: AppTextVariant.h3,
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildBody(bool isLearned) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: AppText(
                item.title,
                variant: AppTextVariant.bodyLarge,
                fontWeight: FontWeight.w600,
                color: isLearned
                    ? AppColors.textTertiaryColor
                    : AppColors.textPrimaryColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSizes.space2),
            SourceBadge(source: item.source),
          ],
        ),
        const SizedBox(height: AppSizes.space1),
        AppText(
          item.difficulty,
          variant: AppTextVariant.caption,
          color: AppColors.textTertiaryColor,
        ),
      ],
    );
  }
}
