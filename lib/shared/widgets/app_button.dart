import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_text.dart';

enum AppButtonVariant { primary, secondary, text, outline }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? AppSizes.icon3XL;
    final buttonPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL);

    Widget child = isLoading
        ? const SizedBox(
            width: AppSizes.iconXL,
            height: AppSizes.iconXL,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconL),
                const SizedBox(width: AppSizes.spacingS),
              ],
              AppText(text, style: _textStyle),
            ],
          );

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30FF7A27),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              minimumSize:
                  Size(isFullWidth ? double.infinity : 0, buttonHeight),
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusPill),
              ),
              elevation: 0,
            ),
            child: child,
          ),
        );
        break;

      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primary,
            minimumSize:
                Size(isFullWidth ? double.infinity : 0, buttonHeight),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusPill),
            ),
            elevation: 0,
          ),
          child: child,
        );
        break;

      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textSecondary,
            minimumSize:
                Size(isFullWidth ? double.infinity : 0, buttonHeight),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusPill),
            ),
            side: const BorderSide(
              color: AppColors.borderStrong,
              width: AppSizes.borderMedium,
            ),
          ),
          child: child,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize:
                Size(isFullWidth ? double.infinity : 0, buttonHeight),
            padding: buttonPadding,
          ),
          child: child,
        );
        break;
    }

    return button;
  }

  TextStyle get _textStyle {
    final base = AppTextStyles.button.copyWith(
      fontSize: AppSizes.fontL,
      fontWeight: FontWeight.w600,
    );
    switch (variant) {
      case AppButtonVariant.primary:
        return base.copyWith(color: AppColors.textOnPrimary);
      case AppButtonVariant.secondary:
        return base.copyWith(color: AppColors.primary);
      case AppButtonVariant.outline:
        return base.copyWith(color: AppColors.textSecondary);
      case AppButtonVariant.text:
        return base.copyWith(color: AppColors.primary);
    }
  }
}
