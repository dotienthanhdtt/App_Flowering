import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          top: AppSizes.topBarHeight, left: AppSizes.padding3XL, right: AppSizes.padding3XL),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            child: Image.asset(
              'assets/logos/logo.png',
              width: AppSizes.avatarS,
              height: AppSizes.avatarS,
            ),
          ),
          const SizedBox(width: AppSizes.spacingS),
          Text(
            'Flowering',
            style: GoogleFonts.outfit(
              fontSize: AppSizes.font3XL,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.login),
            child: Text(
              'Log in',
              style: GoogleFonts.outfit(
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.w600,
                color: AppColors.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
