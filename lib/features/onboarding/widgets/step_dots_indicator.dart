import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class StepDotsIndicator extends StatelessWidget {
  final int activeStep;
  final int totalSteps;

  const StepDotsIndicator({
    super.key,
    required this.activeStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == activeStep;
        return Container(
          margin: EdgeInsets.only(right: index < totalSteps - 1 ? AppSizes.space2 : 0),
          width: isActive ? AppSizes.space6 : AppSizes.space4,
          height: AppSizes.space1,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryColor : AppColors.infoColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusXS),
          ),
        );
      }),
    );
  }
}
