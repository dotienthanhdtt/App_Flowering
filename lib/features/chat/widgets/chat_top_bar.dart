import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderLight, width: AppSizes.borderThin),
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
              Text(
                'Flowering',
                style: GoogleFonts.outfit(
                  fontSize: AppSizes.fontXL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Text(flagEmoji, style: const TextStyle(fontSize: AppSizes.fontXL)),
              const Spacer(),
              GestureDetector(
                onTap: onSkip,
                child: Text(
                  'chat_skip'.tr,
                  style: GoogleFonts.outfit(
                    fontSize: AppSizes.fontM,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
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
                Container(color: AppColors.borderLight),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  width: constraints.maxWidth * progress,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
