import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../lessons/models/lesson-models.dart';

/// Controls the Chat home tab — fetches /lessons scenarios for selection.
class ChatHomeController extends BaseController {
  final _apiClient = Get.find<ApiClient>();

  final categories = <LessonCategory>[].obs;

  int _currentPage = 1;
  bool _hasMore = true;

  /// Total scenario count across all loaded categories.
  int get totalScenarios =>
      categories.fold(0, (sum, c) => sum + c.scenarios.length);

  @override
  void onInit() {
    super.onInit();
    fetchLessons();
  }

  Future<void> fetchLessons({bool refresh = false}) async {
    // Guard against concurrent calls (e.g. double pull-to-refresh)
    if (isLoading.value) return;
    if (!refresh && !_hasMore) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      // Do NOT clear categories here — keep old data visible during refresh.
      // assignAll in onSuccess replaces atomically once the response arrives.
    }

    await apiCall<ApiResponse<GetLessonsResponse>>(
      () => _apiClient.get<GetLessonsResponse>(
        ApiEndpoints.lessons,
        queryParameters: {'page': _currentPage, 'limit': 20},
        fromJson: (data) =>
            GetLessonsResponse.fromJson(data as Map<String, dynamic>),
      ),
      showLoading: categories.isEmpty,
      onSuccess: (response) {
        if (!response.isSuccess || response.data == null) {
          errorMessage.value = response.message;
          return;
        }
        final data = response.data!;
        if (_currentPage == 1) {
          categories.assignAll(data.categories);
        } else {
          _mergeCategories(data.categories);
        }
        _hasMore = _currentPage * data.pagination.limit < data.pagination.total;
        _currentPage++;
      },
    );
  }

  /// Merge incoming categories — single assignAll to fire one Obx update.
  void _mergeCategories(List<LessonCategory> incoming) {
    final merged = [...categories];
    for (final cat in incoming) {
      final idx = merged.indexWhere((c) => c.id == cat.id);
      if (idx >= 0) {
        final existing = merged[idx];
        merged[idx] = LessonCategory(
          id: existing.id,
          name: existing.name,
          icon: existing.icon,
          scenarios: [...existing.scenarios, ...cat.scenarios],
        );
      } else {
        merged.add(cat);
      }
    }
    categories.assignAll(merged);
  }

  Future<void> refreshLessons() => fetchLessons(refresh: true);
}
