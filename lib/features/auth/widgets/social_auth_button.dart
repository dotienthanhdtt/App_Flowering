import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

enum SocialProvider { apple, google }

/// Sign-in button styled for Apple (dark) or Google (outlined) login.
class SocialAuthButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback onTap;

  const SocialAuthButton({
    super.key,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isApple = provider == SocialProvider.apple;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizes.buttonHeightM,
        decoration: BoxDecoration(
          color: isApple ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: isApple
              ? null
              : Border.all(color: AppColors.borderLight, width: AppSizes.borderMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isApple ? '🍎' : 'G',
              style: TextStyle(
                fontSize: isApple ? AppSizes.font3XL : AppSizes.fontXXL,
                fontWeight: FontWeight.w800,
                color: isApple ? Colors.white : const Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isApple ? 'Continue with Apple' : 'Continue with Google',
              style: GoogleFonts.outfit(
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.w600,
                color: isApple ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
