import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/services/language-context-service.dart';
import '../../lessons/models/lesson-models.dart';
import '../../onboarding/models/onboarding_language_model.dart';

/// Controls the Chat home tab — fetches /lessons scenarios for selection.
class ChatHomeController extends BaseController {
  final _apiClient = Get.find<ApiClient>();
  final _langCtx = Get.find<LanguageContextService>();

  final categories = <LessonCategory>[].obs;
  final isRefreshing = false.obs;

  final availableLanguages = <OnboardingLanguage>[].obs;
  final Rx<OnboardingLanguage?> activeLanguage = Rx<OnboardingLanguage?>(null);
  bool _availableLoaded = false;
  Worker? _activeCodeWorker;

  int _currentPage = 1;
  bool _hasMore = true;

  /// Total scenario count across all loaded categories.
  int get totalScenarios =>
      categories.fold(0, (sum, c) => sum + c.scenarios.length);

  @override
  void onInit() {
    super.onInit();
    fetchLessons();
    // Fire-and-forget so first paint isn't blocked on the languages endpoint.
    loadAvailableLanguages();
    _activeCodeWorker = ever<String?>(_langCtx.activeCode, _syncActiveFromCode);
  }

  @override
  void onClose() {
    _activeCodeWorker?.dispose();
    super.onClose();
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

    final activeCode = _langCtx.activeCode.value;
    await apiCall<ApiResponse<GetLessonsResponse>>(
      () => _apiClient.get<GetLessonsResponse>(
        ApiEndpoints.lessons,
        queryParameters: {'page': _currentPage, 'limit': 20},
        options: activeCode != null && activeCode.isNotEmpty
            ? Options(headers: {'X-Learning-Language': activeCode})
            : null,
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

  Future<void> refreshLessons() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      await fetchLessons(refresh: true);
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Loads every language the backend marks as available to learn
  /// (`/languages?type=learning` → `LanguageDto[]` flat list, already filtered
  /// by `isLearningAvailable: true`). Idempotent unless [force]; client also
  /// filters defensively in case the server sends an unfiltered list.
  Future<void> loadAvailableLanguages({bool force = false}) async {
    if (_availableLoaded && !force) return;
    try {
      final resp = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.languages,
        queryParameters: {'type': 'learning'},
        fromJson: (d) => d as List<dynamic>,
      );
      if (!resp.isSuccess || resp.data == null) return;
      final parsed = resp.data!
          .whereType<Map<String, dynamic>>()
          .map((j) => OnboardingLanguage.fromJson(j, type: 'learning'))
          .where((l) => l.isEnabled)
          .toList();
      availableLanguages.assignAll(parsed);
      _availableLoaded = true;
      _syncActiveFromCode(_langCtx.activeCode.value);
    } catch (_) {
      // Swallow — picker can still be opened (shows empty state) and another
      // call will retry on next open.
    }
  }

  /// Persists the selected language and refetches lessons under the new header.
  /// Clears categories first so the body swaps from stale data to the loading
  /// indicator while the request is in flight — the loading branch in the view
  /// only triggers when `categories.isEmpty`.
  Future<void> switchActiveLanguage(OnboardingLanguage next) async {
    if (!next.isEnabled) return;
    if (next.code == _langCtx.activeCode.value) return;
    await _langCtx.setActive(next.code, next.id);
    activeLanguage.value = next;
    categories.clear();
    errorMessage.value = '';
    await fetchLessons(refresh: true);
  }

  void _syncActiveFromCode(String? code) {
    if (code == null || code.isEmpty) {
      activeLanguage.value = null;
      return;
    }
    final match = availableLanguages.firstWhereOrNull((l) => l.code == code);
    if (match != null) activeLanguage.value = match;
  }
}
