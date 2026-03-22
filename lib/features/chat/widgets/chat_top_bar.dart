import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

/// Top bar for the AI chat onboarding screen.
/// Shows logo + brand name + flag emoji + progress bar + skip button.
class ChatTopBar extends StatelessWidget {
  final double progress;
  final String flagEmoji;
  final VoidCallback? onSkip;

  const ChatTopBar({
    super.key,
    this.progress = 0.75,
    this.flagEmoji = '🇬🇧',
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: AppSizes.topBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderLightColor, width: AppSizes.borderThin),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                child: Image.asset(
                  'assets/logos/logo.png',
                  width: AppSizes.avatarS,
                  height: AppSizes.avatarS,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              AppText(
                'app_name'.tr,
                variant: AppTextVariant.bodyLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryColor,
              ),
              const SizedBox(width: AppSizes.space2),
              Text(flagEmoji, style: const TextStyle(fontSize: AppSizes.fontSizeMedium)),
              const Spacer(),
              GestureDetector(
                onTap: onSkip,
                child: AppText(
                  'chat_skip'.tr,
                  variant: AppTextVariant.label,
                  color: AppColors.textTertiaryColor,
                ),
              ),
            ],
          ),
        ),
        // Thin progress bar
        SizedBox(
          height: 3,
          child: LayoutBuilder(
            builder: (_, constraints) => Stack(
              children: [
                Container(color: AppColors.borderLightColor),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  width: constraints.maxWidth * progress,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
