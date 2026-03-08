import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_colors.dart';
import 'app_text.dart';

class AppTappablePhrase extends StatelessWidget {
  final String text;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final void Function(String word, int wordIndex)? onWordTap;
  final TextStyle Function(String word, int wordIndex)? wordStyleBuilder;
  final Set<int>? highlightedWordIndices;
  final Color? highlightColor;
  final Color? highlightBackground;

  const AppTappablePhrase(
    this.text, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.onWordTap,
    this.wordStyleBuilder,
    this.highlightedWordIndices,
    this.highlightColor,
    this.highlightBackground,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = _getBaseStyle();
    final words = text.split(' ');
    final spans = <InlineSpan>[];

    for (var i = 0; i < words.length; i++) {
      if (i > 0) {
        spans.add(TextSpan(text: ' ', style: baseStyle));
      }

      final word = words[i];
      final isHighlighted = highlightedWordIndices?.contains(i) ?? false;
      final customStyle = wordStyleBuilder?.call(word, i);

      TextStyle wordStyle = customStyle ?? baseStyle;
      if (isHighlighted) {
        wordStyle = wordStyle.copyWith(
          color: highlightColor ?? AppColors.primary,
          backgroundColor: highlightBackground,
          fontWeight: FontWeight.w600,
        );
      }

      spans.add(
        TextSpan(
          text: word,
          style: wordStyle,
          recognizer: onWordTap != null
              ? (TapGestureRecognizer()..onTap = () => onWordTap!(word, i))
              : null,
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  TextStyle _getBaseStyle() {
    final style = switch (variant) {
      AppTextVariant.h1 => AppTextStyles.h1,
      AppTextVariant.h2 => AppTextStyles.h2,
      AppTextVariant.h3 => AppTextStyles.h3,
      AppTextVariant.bodyLarge => AppTextStyles.bodyLarge,
      AppTextVariant.bodyMedium => AppTextStyles.bodyMedium,
      AppTextVariant.bodySmall => AppTextStyles.bodySmall,
      AppTextVariant.caption => AppTextStyles.caption,
      AppTextVariant.label => AppTextStyles.label,
    };
    return color != null ? style.copyWith(color: color) : style;
  }
}
