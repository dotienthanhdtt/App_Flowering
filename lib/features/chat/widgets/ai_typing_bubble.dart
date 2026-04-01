import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
/// Animated three-dot AI typing indicator.
class AiTypingBubble extends StatefulWidget {
  const AiTypingBubble({super.key});

  @override
  State<AiTypingBubble> createState() => _AiTypingBubbleState();
}

class _AiTypingBubbleState extends State<AiTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Sentinel `true` ensures first didChangeDependencies always triggers start.
  bool _reduceMotion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      if (_reduceMotion) {
        _ctrl.stop();
        _ctrl.value = 0;
      } else {
        _ctrl.repeat();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.fontSizeLarge, vertical: AppSizes.space4),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(AppSizes.radiusL),
              bottomLeft: Radius.circular(AppSizes.radiusL),
              bottomRight: Radius.circular(AppSizes.radiusL),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSubtleColor,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final offset = (i / 3);
                final val =
                    ((_ctrl.value - offset) % 1.0).clamp(0.0, 1.0);
                final scale = _reduceMotion ? 1.0 : 0.6 + 0.4 * (val < 0.5 ? val * 2 : (1 - val) * 2);
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? AppSizes.space2 : 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: AppSizes.space2,
                      height: AppSizes.space2,
                      decoration: BoxDecoration(
                        color: i == 1
                            ? AppColors.primaryColor
                            : AppColors.primaryLightColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
