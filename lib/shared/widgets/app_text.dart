import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';

enum AppTextVariant {
  h1,
  h2,
  h3,
  bodyLarge,
  bodyMedium,
  bodySmall,
  button,
  caption,
  label,
}

class AppText extends StatelessWidget {
  final String text;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;
  final double? fontSize;
  final TextStyle? style;
  final TextDecoration? decoration;
  final FontStyle? fontStyle;
  final double? height;

  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    this.fontSize,
    this.style,
    this.decoration,
    this.fontStyle,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? _getStyle()).copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      decoration: decoration,
      fontStyle: fontStyle,
      height: height,
    );

    return Text(
      text,
      style: effectiveStyle,
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
      case AppTextVariant.button:
        return AppTextStyles.button;
      case AppTextVariant.caption:
        return AppTextStyles.caption;
      case AppTextVariant.label:
        return AppTextStyles.label;
    }
  }
}
