import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'loading_widget.dart';

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
            Container(
              color: Colors.black54,
              child: LoadingWidget(message: message),
            ),
        ],
      );
    });
  }
}

/// Show loading overlay as dialog
void showLoadingDialog({String? message}) {
  Get.dialog(
    PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LoadingWidget(message: message, size: 60),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

/// Hide loading dialog
void hideLoadingDialog() {
  if (Get.isDialogOpen ?? false) {
    Get.back();
  }
}
