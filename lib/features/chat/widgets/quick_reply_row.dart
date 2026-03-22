import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

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
      padding: const EdgeInsets.only(left: AppSizes.buttonHeightMedium),
      child: Wrap(
        spacing: AppSizes.space2,
        runSpacing: AppSizes.space2,
        children: options
            .map(
              (opt) => GestureDetector(
                onTap: () => onSelect(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space4, vertical: AppSizes.space2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(color: AppColors.borderLightColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08191919),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: AppText(
                    opt,
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
