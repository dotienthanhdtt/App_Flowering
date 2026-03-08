import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_colors.dart';
import 'app_text.dart';

class AppTappablePhrase extends StatefulWidget {
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
  State<AppTappablePhrase> createState() => _AppTappablePhraseState();
}

class _AppTappablePhraseState extends State<AppTappablePhrase> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final baseStyle = _getBaseStyle();
    final words = widget.text.split(' ');
    final spans = <InlineSpan>[];

    for (var i = 0; i < words.length; i++) {
      if (i > 0) {
        spans.add(TextSpan(text: ' ', style: baseStyle));
      }

      final word = words[i];
      final isHighlighted =
          widget.highlightedWordIndices?.contains(i) ?? false;
      final customStyle = widget.wordStyleBuilder?.call(word, i);

      TextStyle wordStyle = customStyle ?? baseStyle;
      if (isHighlighted) {
        wordStyle = wordStyle.copyWith(
          color: widget.highlightColor ?? AppColors.primary,
          backgroundColor: widget.highlightBackground,
          fontWeight: FontWeight.w600,
        );
      }

      TapGestureRecognizer? recognizer;
      if (widget.onWordTap != null) {
        recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onWordTap!(word, i);
        _recognizers.add(recognizer);
      }

      spans.add(
        TextSpan(text: word, style: wordStyle, recognizer: recognizer),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: widget.textAlign ?? TextAlign.start,
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.clip,
    );
  }

  TextStyle _getBaseStyle() {
    final style = switch (widget.variant) {
      AppTextVariant.h1 => AppTextStyles.h1,
      AppTextVariant.h2 => AppTextStyles.h2,
      AppTextVariant.h3 => AppTextStyles.h3,
      AppTextVariant.bodyLarge => AppTextStyles.bodyLarge,
      AppTextVariant.bodyMedium => AppTextStyles.bodyMedium,
      AppTextVariant.bodySmall => AppTextStyles.bodySmall,
      AppTextVariant.caption => AppTextStyles.caption,
      AppTextVariant.label => AppTextStyles.label,
    };
    return widget.color != null ? style.copyWith(color: widget.color) : style;
  }
}
