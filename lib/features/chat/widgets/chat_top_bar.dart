import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

/// Top bar for the AI chat screen.
/// Shows back arrow + centered title + optional more icon.
class ChatTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showMoreButton;
  final VoidCallback? onMore;

  const ChatTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.showMoreButton = false,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: AppSizes.topBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
          color: AppColors.surfaceColor,
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack ?? () => Get.back(),
                child: const Icon(
                  Icons.arrow_back,
                  size: AppSizes.iconXL,
                  color: AppColors.neutralColor,
                ),
              ),
              Expanded(
                child: Center(
                  child: AppText(
                    title,
                    fontSize: AppSizes.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
              ),
              if (showMoreButton)
                GestureDetector(
                  onTap: onMore,
                  child: const Icon(
                    Icons.more_vert,
                    size: AppSizes.iconXL,
                    color: AppColors.neutralColor,
                  ),
                )
              else
                const SizedBox(width: AppSizes.iconXL),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.infoColor),
      ],
    );
  }
}
