import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/personal_source.dart';

/// Tiny pill placed next to the title of a For-You card.
/// `personalized` → "AI" (primary). `kol` → "KOL" (gold).
class SourceBadge extends StatelessWidget {
  final PersonalSource source;

  const SourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final isKol = source == PersonalSource.kol;
    final bg = isKol ? AppColors.accentGoldColor : AppColors.primaryColor;
    final label = isKol ? 'source_kol_badge'.tr : 'source_ai_badge'.tr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: AppText(
        label,
        variant: AppTextVariant.caption,
        color: AppColors.textOnPrimaryColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
