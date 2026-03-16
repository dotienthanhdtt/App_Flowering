import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Circular avatar showing the Flora AI logo.
class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.avatarM,
      height: AppSizes.avatarM,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Image.asset('assets/logos/logo.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}
