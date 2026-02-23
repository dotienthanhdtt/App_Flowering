import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';

enum AppTextVariant { h1, h2, h3, bodyLarge, bodyMedium, bodySmall, caption, label }

class AppText extends StatelessWidget {
  final String text;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _getStyle().copyWith(color: color),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _getStyle() {
    switch (variant) {
      case AppTextVariant.h1:
        return AppTextStyles.h1;
      case AppTextVariant.h2:
        return AppTextStyles.h2;
      case AppTextVariant.h3:
        return AppTextStyles.h3;
      case AppTextVariant.bodyLarge:
        return AppTextStyles.bodyLarge;
      case AppTextVariant.bodyMedium:
        return AppTextStyles.bodyMedium;
      case AppTextVariant.bodySmall:
        return AppTextStyles.bodySmall;
      case AppTextVariant.caption:
        return AppTextStyles.caption;
      case AppTextVariant.label:
        return AppTextStyles.label;
    }
  }
}
