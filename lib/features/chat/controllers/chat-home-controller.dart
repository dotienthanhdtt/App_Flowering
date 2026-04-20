import 'package:get/get.dart' hide Response;

import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/language-context-service.dart';
import '../../onboarding/models/onboarding_language_model.dart';

/// Controls the Chat home screen header — manages the active-learning-language
/// flag button and the picker sheet. Body content (scenarios) is owned by
/// `FloweringFeedController` and `ForYouFeedController` via the top-tabs.
class ChatHomeController extends BaseController {
  final _apiClient = Get.find<ApiClient>();
  final _langCtx = Get.find<LanguageContextService>();

  final availableLanguages = <OnboardingLanguage>[].obs;
  final Rx<OnboardingLanguage?> activeLanguage = Rx<OnboardingLanguage?>(null);
  bool _availableLoaded = false;
  Worker? _activeCodeWorker;

  @override
  void onInit() {
    super.onInit();
    // Fire-and-forget so first paint isn't blocked on the languages endpoint.
    loadAvailableLanguages();
    _activeCodeWorker = ever<String?>(_langCtx.activeCode, _syncActiveFromCode);
  }

  @override
  void onClose() {
    _activeCodeWorker?.dispose();
    super.onClose();
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

  /// Persists the selected language. Feed controllers listen to
  /// `_langCtx.activeCode` and refresh themselves.
  Future<void> switchActiveLanguage(OnboardingLanguage next) async {
    if (!next.isEnabled) return;
    if (next.code == _langCtx.activeCode.value) return;
    await _langCtx.setActive(next.code, next.id);
    activeLanguage.value = next;
    errorMessage.value = '';
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
