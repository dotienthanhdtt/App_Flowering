import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class VocabularyBoxTabs extends StatelessWidget {
  final int selectedBox;
  final ValueChanged<int> onChanged;

  const VocabularyBoxTabs({
    super.key,
    required this.selectedBox,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space6,
        vertical: AppSizes.space2,
      ),
      child: Row(
        children: List.generate(5, (index) {
          final box = index + 1;
          final selected = box == selectedBox;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == 4 ? AppSizes.space0 : AppSizes.space2,
              ),
              child: _BoxTab(
                box: box,
                selected: selected,
                onTap: () => onChanged(box),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BoxTab extends StatelessWidget {
  final int box;
  final bool selected;
  final VoidCallback onTap;

  const _BoxTab({
    required this.box,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Box $box',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryColor
                : AppColors.surfaceMutedColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            border: Border.all(
              color: selected ? AppColors.primaryColor : AppColors.borderColor,
            ),
          ),
          child: Text(
            '$box',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: AppSizes.fontSizeBase,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppColors.textOnPrimaryColor
                  : AppColors.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
