import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/services/language-context-service.dart';
import '../models/scenario_feed_item.dart';
import '../services/scenarios_service.dart';

/// Controller for the Flowering (default) tab on the Home screen.
///
/// Owns paginated state for `/scenarios/default`. Refreshes automatically
/// when the active learning language changes.
class FloweringFeedController extends BaseController {
  final ScenariosService _service = Get.find<ScenariosService>();
  final LanguageContextService _langCtx = Get.find<LanguageContextService>();

  final items = <ScenarioFeedItem>[].obs;
  final isRefreshing = false.obs;

  static const int _pageLimit = 20;
  int _page = 1;
  bool _hasMore = true;
  Worker? _langWorker;

  bool get hasMore => _hasMore;
  int get currentPage => _page;

  @override
  void onInit() {
    super.onInit();
    fetchFeed();
    _langWorker = ever<String?>(_langCtx.activeCode, (_) {
      fetchFeed(refresh: true);
    });
  }

  @override
  void onClose() {
    _langWorker?.dispose();
    _langWorker = null;
    super.onClose();
  }

  Future<void> fetchFeed({bool refresh = false}) async {
    if (isLoading.value) return;
    if (!refresh && !_hasMore) return;

    if (refresh) {
      _page = 1;
      _hasMore = true;
    }

    await apiCall(
      () => _service.getDefaultFeed(page: _page, limit: _pageLimit),
      showLoading: items.isEmpty,
      onSuccess: (resp) {
        if (!resp.isSuccess || resp.data == null) {
          errorMessage.value = resp.message;
          return;
        }
        final feed = resp.data!;
        if (_page == 1) {
          items.assignAll(feed.items);
        } else {
          items.addAll(feed.items);
        }
        final limit =
            feed.pagination.limit == 0 ? _pageLimit : feed.pagination.limit;
        _hasMore = _page * limit < feed.pagination.total;
        _page++;
      },
    );
  }

  Future<void> refreshFeed() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      await fetchFeed(refresh: true);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() => fetchFeed();
}
