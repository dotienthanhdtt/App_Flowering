import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Skeleton loading placeholder for language list screens.
class LanguageListSkeleton extends StatelessWidget {
  final int itemCount;
  final double spacing;

  const LanguageListSkeleton({
    super.key,
    this.itemCount = 7,
    this.spacing = AppSizes.space2,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (_, __) => Container(
        height: AppSizes.space16,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppColors.borderLightColor),
        ),
      ),
    );
  }
}
