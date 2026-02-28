import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

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
          margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
          width: isActive ? 28 : 16,
          height: 4,
          decoration: BoxDecoration(
            color: isActive ? AppColors.textPrimary : AppColors.borderLight,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
