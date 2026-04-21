import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'loading_widget.dart';

/// Pull-to-refresh wrapper that shows [LoadingWidget] gradually during pull.
///
/// Wraps a scrollable child with overscroll detection and a custom
/// loading indicator that scales/fades in as the user pulls down.
///
/// Usage:
/// ```dart
/// PullToRefreshList(
///   isRefreshing: controller.isRefreshing,
///   onRefresh: controller.refreshLessons,
///   child: ListView.builder(...),
/// )
/// ```
class PullToRefreshList extends StatefulWidget {
  final RxBool isRefreshing;
  final Future<void> Function() onRefresh;
  final Widget child;
  final double threshold;
  final double indicatorSize;

  const PullToRefreshList({
    super.key,
    required this.isRefreshing,
    required this.onRefresh,
    required this.child,
    this.threshold = 80.0,
    this.indicatorSize = 40,
  });

  @override
  State<PullToRefreshList> createState() => _PullToRefreshListState();
}

class _PullToRefreshListState extends State<PullToRefreshList> {
  late Worker _refreshWorker;
  double _pullOffset = 0;
  double _maxPullOffset = 0;

  @override
  void initState() {
    super.initState();
    _refreshWorker = ever(widget.isRefreshing, (isRefreshing) {
      if (!isRefreshing && mounted) {
        setState(() {
          _pullOffset = 0;
          _maxPullOffset = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshWorker.dispose();
    super.dispose();
  }

  bool _handleScroll(ScrollNotification notification) {
    if (widget.isRefreshing.value) return false;

    if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      if (pixels < 0) {
        final offset = -pixels;
        if (offset > _maxPullOffset) _maxPullOffset = offset;
        // Once past threshold, lock at full — prevents shrink during bounce-back
        final effective = _maxPullOffset >= widget.threshold
            ? widget.threshold
            : offset;
        if (effective != _pullOffset) {
          setState(() => _pullOffset = effective);
        }
      } else if (_maxPullOffset < widget.threshold && _pullOffset != 0) {
        setState(() => _pullOffset = 0);
      }
    } else if (notification is ScrollEndNotification) {
      if (_maxPullOffset >= widget.threshold) {
        widget.onRefresh();
      } else {
        setState(() {
          _pullOffset = 0;
          _maxPullOffset = 0;
        });
      }
    }
    return false;
  }

  Widget _buildIndicator() {
    if (widget.isRefreshing.value) {
      return LoadingWidget(size: widget.indicatorSize);
    }
    if (_pullOffset <= 0) return const SizedBox.shrink();

    final progress = (_pullOffset / widget.threshold).clamp(0.0, 1.0);
    return Opacity(
      opacity: progress,
      child: Transform.scale(
        scale: progress,
        child: LoadingWidget(size: widget.indicatorSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: Column(
        children: [
          // Obx so the true→false and false→true transitions of
          // `isRefreshing` both rebuild the indicator. Without it, the
          // `true` transition never triggers a rebuild and the indicator
          // visually freezes at whatever pull-offset the user released at.
          Obx(() => _buildIndicator()),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
