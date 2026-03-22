import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Animated waveform bars for recording visualization.
/// 39 bars with 2px gaps, height range 6-26px.
class ChatWaveformBars extends StatefulWidget {
  const ChatWaveformBars({super.key});

  @override
  State<ChatWaveformBars> createState() => _ChatWaveformBarsState();
}

class _ChatWaveformBarsState extends State<ChatWaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(39, (i) {
          final phase = (i / 39 + _ctrl.value) % 1.0;
          final height = 6.0 + 20.0 * (0.5 + 0.5 * _sin(phase * 3.14159 * 2));
          return Padding(
            padding: EdgeInsets.only(right: i < 38 ? 2 : 0),
            child: Container(
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          );
        }),
      ),
    );
  }

  double _sin(double x) {
    x = x % (3.14159 * 2);
    if (x > 3.14159) x -= 3.14159 * 2;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}
