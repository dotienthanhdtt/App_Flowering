import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/loading_overlay.dart';
import 'base_controller.dart';

/// Base screen with loading overlay and error handling
abstract class BaseScreen<T extends BaseController> extends GetView<T> {
  const BaseScreen({super.key});

  /// Build screen content
  Widget buildContent(BuildContext context);

  /// Optional app bar
  PreferredSizeWidget? buildAppBar(BuildContext context) => null;

  /// Optional floating action button
  Widget? buildFab(BuildContext context) => null;

  /// Optional bottom navigation bar
  Widget? buildBottomNav(BuildContext context) => null;

  /// Background color
  Color? get backgroundColor => null;

  /// Whether to use safe area
  bool get useSafeArea => true;

  /// Whether to show loading overlay
  bool get showLoadingOverlay => true;

  /// Custom loading message
  String? get loadingMessage => null;

  @override
  Widget build(BuildContext context) {
    Widget content = buildContent(context);

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    // Wrap with loading overlay
    if (showLoadingOverlay) {
      content = LoadingOverlay(
        isLoading: controller.isLoading,
        message: loadingMessage,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildAppBar(context),
      body: content,
      floatingActionButton: buildFab(context),
      bottomNavigationBar: buildBottomNav(context),
    );
  }
}

/// Simple stateless screen without controller
abstract class BaseStatelessScreen extends StatelessWidget {
  const BaseStatelessScreen({super.key});

  Widget buildContent(BuildContext context);

  PreferredSizeWidget? buildAppBar(BuildContext context) => null;
  Widget? buildFab(BuildContext context) => null;
  Widget? buildBottomNav(BuildContext context) => null;
  Color? get backgroundColor => null;
  bool get useSafeArea => true;

  @override
  Widget build(BuildContext context) {
    Widget content = buildContent(context);

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildAppBar(context),
      body: content,
      floatingActionButton: buildFab(context),
      bottomNavigationBar: buildBottomNav(context),
    );
  }
}
