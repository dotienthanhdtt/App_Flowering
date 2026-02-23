import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Animated loading widget with pulsating glow
class LoadingWidget extends StatefulWidget {
  final String? message;
  final double? size;
  final Color? glowColor;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.glowColor,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? AppColors.primary;
    final loadingSize = widget.size ?? 80.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Container(
              width: loadingSize + 20,
              height: loadingSize + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Pulsating glow effect
                  BoxShadow(
                    color: glowColor.withValues(
                      alpha: 0.3 + 0.2 * math.sin(_controller.value * 2 * math.pi),
                    ),
                    blurRadius: 30 + 10 * math.sin(_controller.value * 2 * math.pi),
                    spreadRadius: 5 + 5 * math.sin(_controller.value * 2 * math.pi),
                  ),
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.15),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: child,
                ),
              ),
            ),
            child: Container(
              width: loadingSize,
              height: loadingSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.local_florist,
                size: loadingSize * 0.6,
                color: glowColor,
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            Text(
              widget.message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
