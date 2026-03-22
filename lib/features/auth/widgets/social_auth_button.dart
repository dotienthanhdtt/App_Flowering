import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

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
        height: AppSizes.buttonHeightLarge,
        decoration: BoxDecoration(
          color: isApple ? AppColors.textPrimaryColor : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: isApple
              ? null
              : Border.all(color: AppColors.borderLightColor, width: AppSizes.borderMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isApple ? '🍎' : 'G',
              style: TextStyle(
                fontSize: isApple ? AppSizes.fontSizeLarge : AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w800,
                color: isApple ? Colors.white : const Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 10),
            AppText(
              isApple ? 'continue_with_apple'.tr : 'continue_with_google'.tr,
              variant: AppTextVariant.bodyLarge,
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: isApple ? Colors.white : AppColors.textPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
