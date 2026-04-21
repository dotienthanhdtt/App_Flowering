import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/services/language-context-service.dart';
import '../models/personal_scenario_item.dart';
import '../services/scenarios_service.dart';

/// Controller for the For You tab on the Home screen.
///
/// Owns paginated state for `/scenarios/personal`. Mirrors
/// [FloweringFeedController] but operates on [PersonalScenarioItem].
class ForYouFeedController extends BaseController {
  final ScenariosService _service = Get.find<ScenariosService>();
  final LanguageContextService _langCtx = Get.find<LanguageContextService>();

  final items = <PersonalScenarioItem>[].obs;
  final isRefreshing = false.obs;

  static const int _pageLimit = 20;
  int _page = 1;
  bool _hasMore = true;
  Worker? _langWorker;
  // Monotonic fetch generation. Every call bumps it; responses whose captured
  // generation no longer matches are dropped. Lets a refresh cancel-in-effect
  // the initial fetch without awaiting it.
  int _fetchGen = 0;

  bool get hasMore => _hasMore;
  int get currentPage => _page;

  @override
  void onInit() {
    super.onInit();
    fetchFeed();
    _langWorker = ever<String?>(_langCtx.activeCode, (_) {
      // Clear synchronously so the tab's empty+loading branch lights up
      // (full LoadingWidget). Pull-to-refresh intentionally does NOT clear —
      // there the PullToRefreshList indicator is the loading signal.
      items.clear();
      errorMessage.value = '';
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
    // Pagination dedupes against concurrent calls; explicit refresh bypasses
    // the guard so a pull or language-switch can supersede an in-flight fetch.
    if (!refresh && isLoading.value) return;
    if (!refresh && !_hasMore) return;

    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    final gen = ++_fetchGen;

    await apiCall(
      () => _service.getPersonalFeed(page: _page, limit: _pageLimit),
      showLoading: items.isEmpty,
      onSuccess: (resp) {
        // Drop stale responses from a fetch superseded by a newer one.
        if (gen != _fetchGen) return;
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
