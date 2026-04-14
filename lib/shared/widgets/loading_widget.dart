import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'app_text.dart';

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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
        _controller.stop();
        _controller.value = 0;
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? AppColors.primaryColor;
    final loadingSize = widget.size ?? 80.0;

    return Semantics(
      label: widget.message ?? 'Loading',
      liveRegion: true,
      child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Container(
              width: loadingSize + AppSizes.space5,
              height: loadingSize + AppSizes.space5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(
                      alpha: 0.4 + 0.2 * math.sin(_controller.value * 2 * math.pi),
                    ),
                    blurRadius: 30 + 10 * math.sin(_controller.value * 2 * math.pi),
                    spreadRadius: 10 + 5 * math.sin(_controller.value * 2 * math.pi),
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
              ),
              child: ExcludeSemantics(
                child: Image.asset(
                  'assets/logos/logo.png',
                  width: loadingSize * 0.6,
                  height: loadingSize * 0.6,
                ),
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: AppSizes.space6),
            AppText(
              widget.message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
