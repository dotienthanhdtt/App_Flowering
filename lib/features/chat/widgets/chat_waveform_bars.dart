import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Animated waveform bars for recording visualization.
/// Bar heights are driven by real microphone [amplitude] (0.0–1.0).
/// When silent the bars stay flat; when loud they grow tall.
class ChatWaveformBars extends StatefulWidget {
  /// Normalized amplitude: 0.0 = silence, 1.0 = loudest.
  final double amplitude;

  const ChatWaveformBars({super.key, required this.amplitude});

  @override
  State<ChatWaveformBars> createState() => _ChatWaveformBarsState();
}

class _ChatWaveformBarsState extends State<ChatWaveformBars>
    with SingleTickerProviderStateMixin {
  static const int _barCount = 39;
  static const double _minHeight = 4.0;
  static const double _maxHeight = 28.0;

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
      builder: (_, __) {
        final amp = widget.amplitude;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_barCount, (i) {
            // Each bar gets a slight phase offset for a wave effect.
            final phase = (i / _barCount + _ctrl.value) % 1.0;
            final wave = 0.5 + 0.5 * _sin(phase * 3.14159 * 2);
            // Scale the wave by the real amplitude.
            final height =
                _minHeight + (_maxHeight - _minHeight) * amp * wave;
            return Padding(
              padding: EdgeInsets.only(right: i < _barCount - 1 ? 2 : 0),
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
        );
      },
    );
  }

  /// Fast sine approximation (Taylor series, avoids dart:math import).
  double _sin(double x) {
    x = x % (3.14159 * 2);
    if (x > 3.14159) x -= 3.14159 * 2;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}
