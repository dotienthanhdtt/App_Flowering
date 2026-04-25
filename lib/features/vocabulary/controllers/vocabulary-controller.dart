import 'dart:async';

import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../models/vocabulary-model.dart';
import '../services/vocabulary-service.dart';

/// Controller for vocabulary tab — API-backed box filters, search, pagination.
class VocabularyController extends BaseController {
  final VocabularyService _service = Get.find<VocabularyService>();

  final items = <VocabularyItem>[].obs;
  final selectedBox = 1.obs;
  final searchQuery = ''.obs;
  final isRefreshing = false.obs;

  static const int pageLimit = 20;
  static const Duration searchDebounce = Duration(milliseconds: 300);

  int _page = 1;
  bool _hasMore = true;
  int _fetchGen = 0;
  Timer? _searchTimer;

  bool get hasMore => _hasMore;
  int get currentPage => _page;

  @override
  void onInit() {
    super.onInit();
    fetchVocabulary(refresh: true);
  }

  @override
  void onClose() {
    _searchTimer?.cancel();
    super.onClose();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDebounce, () {
      fetchVocabulary(refresh: true);
    });
  }

  Future<void> changeBox(int box) async {
    if (selectedBox.value == box) return;
    selectedBox.value = box;
    items.clear();
    await fetchVocabulary(refresh: true);
  }

  Future<void> fetchVocabulary({bool refresh = false}) async {
    if (!refresh && isLoading.value) return;
    if (!refresh && !_hasMore) return;

    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    final gen = ++_fetchGen;

    await apiCall(
      () => _service.getVocabulary(
        page: _page,
        limit: pageLimit,
        box: selectedBox.value,
        search: searchQuery.value,
      ),
      showLoading: items.isEmpty,
      onSuccess: (resp) {
        if (gen != _fetchGen) return;
        if (!resp.isSuccess || resp.data == null) {
          errorMessage.value = resp.message;
          return;
        }
        final data = resp.data!;
        if (_page == 1) {
          items.assignAll(data.items);
        } else {
          items.addAll(data.items);
        }
        final limit = data.limit == 0 ? pageLimit : data.limit;
        _hasMore = data.page * limit < data.total;
        _page = data.page + 1;
      },
    );
  }

  Future<void> refreshVocabulary() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      await fetchVocabulary(refresh: true);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() => fetchVocabulary();
}
