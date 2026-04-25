import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../shared/widgets/empty_or_error_view.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pull-to-refresh-list.dart';
import '../controllers/vocabulary-controller.dart';
import '../widgets/vocabulary-box-tabs.dart';
import '../widgets/vocabulary-card.dart';

/// Vocabulary tab — paginated API-backed list.
/// Tab child screen — exempt from BaseScreen to avoid nested Scaffold.
class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen>
    with AutomaticKeepAliveClientMixin {
  final VocabularyController _controller = Get.find<VocabularyController>();

  @override
  bool get wantKeepAlive => true;

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 240) {
      _controller.loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Obx(
            () => VocabularyBoxTabs(
              selectedBox: _controller.selectedBox.value,
              onChanged: _controller.changeBox,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.space6,
        right: AppSizes.space6,
        top: AppSizes.space4,
        bottom: AppSizes.space2,
      ),
      child: AppText('vocabulary_title'.tr, variant: AppTextVariant.h2),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space6,
        vertical: AppSizes.space2,
      ),
      child: TextField(
        onChanged: _controller.updateSearch,
        decoration: InputDecoration(
          hintText: 'vocabulary_search'.tr,
          hintStyle: AppTextStyles.caption,
          prefixIcon: const Icon(
            LucideIcons.search,
            size: AppSizes.iconL,
            color: AppColors.textTertiaryColor,
          ),
          filled: true,
          fillColor: AppColors.surfaceMutedColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.space3),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return PullToRefreshList(
      isRefreshing: _controller.isRefreshing,
      onRefresh: _controller.refreshVocabulary,
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
            final hasError = _controller.errorMessage.value.isNotEmpty;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: EmptyOrErrorView(
                    icon: LucideIcons.languages,
                    message: hasError
                        ? _controller.errorMessage.value
                        : 'vocabulary_empty'.tr,
                    onRetry: hasError
                        ? () => _controller.fetchVocabulary(refresh: true)
                        : null,
                    retryLabel: 'retry'.tr,
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
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space4,
              AppSizes.space4,
              AppSizes.space4,
              AppSizes.space6,
            ),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSizes.space3),
            itemBuilder: (_, index) => VocabularyCard(item: items[index]),
          );
        }),
      ),
    );
  }
}
