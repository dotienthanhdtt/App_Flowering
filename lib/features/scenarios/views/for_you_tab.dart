import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/empty_or_error_view.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pull-to-refresh-list.dart';
import '../../../app/routes/app-route-constants.dart';
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
                    icon: LucideIcons.heart,
                    message: _controller.errorMessage.value.isNotEmpty
                        ? _controller.errorMessage.value
                        : 'scenarios_empty_personal'.tr,
                    onRetry: () => _controller.fetchFeed(refresh: true),
                    retryLabel: 'scenarios_error_generic'.tr,
                  ),
                ),
              ],
            );
          }
          final items = _controller.items;
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (ctx, i) =>
                const SizedBox(height: AppSizes.space3),
            itemBuilder: (_, i) => PersonalFeedCard(
              item: items[i],
              onTap: () => Get.toNamed(
                AppRoutes.scenarioDetail,
                arguments: {'id': items[i].id},
              ),
            ),
          );
        }),
      ),
    );
  }
}
