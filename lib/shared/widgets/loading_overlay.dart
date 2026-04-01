import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_sizes.dart';
import 'loading_widget.dart';

/// Tracks the active loading dialog timeout to avoid race conditions.
Timer? _loadingDialogTimer;

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
      hideLoadingDialog();
    }
  });
}

/// Hide loading dialog and cancel any pending timeout.
void hideLoadingDialog() {
  _loadingDialogTimer?.cancel();
  _loadingDialogTimer = null;
  if (Get.isDialogOpen ?? false) {
    Get.back();
  }
}
