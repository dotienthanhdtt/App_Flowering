import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/widgets/empty_or_error_view.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pull-to-refresh-list.dart';
import '../controllers/flowering_feed_controller.dart';
import '../widgets/feed_scenario_card.dart';

/// Flowering (default) tab — 2-column scrollable grid backed by
/// `FloweringFeedController`. Preserves scroll state across tab switches.
class FloweringTab extends StatefulWidget {
  const FloweringTab({super.key});

  @override
  State<FloweringTab> createState() => _FloweringTabState();
}

class _FloweringTabState extends State<FloweringTab>
    with AutomaticKeepAliveClientMixin {
  final FloweringFeedController _controller =
      Get.find<FloweringFeedController>();

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
    return PullToRefreshList(
      isRefreshing: _controller.isRefreshing,
      onRefresh: _controller.refreshFeed,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Obx(() {
          if (_controller.isLoading.value && _controller.items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: const [
                SizedBox(height: 120),
                Center(child: LoadingWidget()),
              ],
            );
          }
          if (_controller.items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: EmptyOrErrorView(
                    icon: LucideIcons.sparkles,
                    message: _controller.errorMessage.value.isNotEmpty
                        ? _controller.errorMessage.value
                        : 'scenarios_empty_default'.tr,
                    onRetry: () => _controller.fetchFeed(refresh: true),
                    retryLabel: 'scenarios_error_generic'.tr,
                  ),
                ),
              ],
            );
          }
          final items = _controller.items;
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 180 / 230,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => FeedScenarioCard(item: items[i]),
          );
        }),
      ),
    );
  }
}
