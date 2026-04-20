import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/for_you_feed_controller.dart';
import '../widgets/personal_feed_card.dart';

/// For-You tab — text-only list backed by `ForYouFeedController`.
/// Preserves scroll + state across tab switches.
class ForYouTab extends StatefulWidget {
  const ForYouTab({super.key});

  @override
  State<ForYouTab> createState() => _ForYouTabState();
}

class _ForYouTabState extends State<ForYouTab>
    with AutomaticKeepAliveClientMixin {
  final ForYouFeedController _controller = Get.find<ForYouFeedController>();

  @override
  bool get wantKeepAlive => true;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
      _controller.loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      if (_controller.isLoading.value && _controller.items.isEmpty) {
        return const LoadingWidget();
      }

      if (_controller.items.isEmpty) {
        return _EmptyOrError(
          message: _controller.errorMessage.value.isNotEmpty
              ? _controller.errorMessage.value
              : 'scenarios_empty_personal'.tr,
          onRetry: () => _controller.fetchFeed(refresh: true),
        );
      }

      return RefreshIndicator(
        onRefresh: _controller.refreshFeed,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: _controller.items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSizes.space3),
            itemBuilder: (_, i) =>
                PersonalFeedCard(item: _controller.items[i]),
          ),
        ),
      );
    });
  }
}

class _EmptyOrError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EmptyOrError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.heart,
              size: AppSizes.icon3XL,
              color: AppColors.textTertiaryColor,
            ),
            const SizedBox(height: AppSizes.space4),
            AppText(
              message,
              variant: AppTextVariant.bodyMedium,
              color: AppColors.textTertiaryColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.space4),
            TextButton(
              onPressed: onRetry,
              child: AppText(
                'scenarios_error_generic'.tr,
                variant: AppTextVariant.button,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
