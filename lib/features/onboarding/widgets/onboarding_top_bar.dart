import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 56, left: 32, right: 32),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/logos/logo.png',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Flowering',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {}, // TODO: implement login navigation
            child: Text(
              'Log in',
              style: GoogleFonts.outfit(
                fontSize: 15,
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
