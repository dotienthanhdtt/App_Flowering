import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Quick-reply chip row — goal selection buttons shown under Flora's first message.
class QuickReplyRow extends StatelessWidget {
  final List<String> options;
  final void Function(String) onSelect;

  const QuickReplyRow({
    super.key,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.inputHeight),
      child: Wrap(
        spacing: AppSizes.spacingS,
        runSpacing: AppSizes.spacingS,
        children: options
            .map(
              (opt) => GestureDetector(
                onTap: () => onSelect(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08191919),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.outfit(
                      fontSize: AppSizes.fontSM,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
