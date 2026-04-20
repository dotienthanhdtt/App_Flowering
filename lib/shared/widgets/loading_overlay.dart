import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_sizes.dart';
import 'loading_widget.dart';

/// Minimum time the loading dialog stays visible once shown, so fast
/// responses don't produce a jarring loading-flash.
const Duration _minLoadingDialogDisplay = Duration(seconds: 2);

/// Tracks the active loading dialog timeout to avoid race conditions.
Timer? _loadingDialogTimer;

/// Defers dismissal until the minimum display duration has elapsed.
Timer? _loadingDialogMinDurationTimer;

/// Timestamp the current loading dialog was shown — null when no dialog
/// is active. Used to compute remaining minimum-display delay on hide.
DateTime? _loadingDialogShownAt;

/// Loading overlay that blocks interaction
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final RxBool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Stack(
        children: [
          child,
          if (isLoading.value)
            Semantics(
              label: message ?? 'Loading, please wait',
              liveRegion: true,
              child: Container(
                color: Colors.black54,
                child: LoadingWidget(message: message),
              ),
            ),
        ],
      );
    });
  }
}

/// Show loading overlay as dialog with auto-dismiss timeout.
void showLoadingDialog({
  String? message,
  Duration timeout = const Duration(seconds: 30),
}) {
  _loadingDialogTimer?.cancel();
  _loadingDialogMinDurationTimer?.cancel();
  _loadingDialogMinDurationTimer = null;
  _loadingDialogShownAt = DateTime.now();

  Get.dialog(
    PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.space8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
          child: LoadingWidget(message: message, size: AppSizes.space16),
        ),
      ),
    ),
    barrierDismissible: false,
  );

  _loadingDialogTimer = Timer(timeout, () {
    if (Get.isDialogOpen ?? false) {
      _dismissLoadingDialog();
    }
  });
}

/// Hide loading dialog, enforcing the minimum display duration.
///
/// If the dialog was shown less than [_minLoadingDialogDisplay] ago,
/// dismissal is deferred until the minimum is reached. Otherwise it
/// dismisses immediately.
void hideLoadingDialog() {
  final shownAt = _loadingDialogShownAt;
  if (shownAt != null) {
    final elapsed = DateTime.now().difference(shownAt);
    if (elapsed < _minLoadingDialogDisplay) {
      _loadingDialogMinDurationTimer?.cancel();
      _loadingDialogMinDurationTimer = Timer(
        _minLoadingDialogDisplay - elapsed,
        _dismissLoadingDialog,
      );
      return;
    }
  }
  _dismissLoadingDialog();
}

void _dismissLoadingDialog() {
  _loadingDialogTimer?.cancel();
  _loadingDialogTimer = null;
  _loadingDialogMinDurationTimer?.cancel();
  _loadingDialogMinDurationTimer = null;
  _loadingDialogShownAt = null;
  if (Get.isDialogOpen ?? false) {
    Get.back();
  }
}
