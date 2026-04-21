import 'dart:async';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/language-context-service.dart';
import '../models/onboarding_language_model.dart';
import '../models/onboarding_profile_model.dart';
import '../services/onboarding_language_service.dart';
import '../services/onboarding_progress_service.dart';

class OnboardingController extends BaseController {
  final selectedNativeLanguage = 'vi'.obs;

  /// Mirror of LanguageContextService.activeCode for existing Obx() callers.
  /// Kept in sync via ever() subscription in onInit(). Do NOT write directly.
  final selectedLearningLanguage = ''.obs;

  final nativeLanguages = <OnboardingLanguage>[].obs;
  final learningLanguages = <OnboardingLanguage>[].obs;
  final isLoadingLanguages = true.obs;

  /// Search query for native language screen filtering.
  final nativeSearchQuery = ''.obs;

  /// Whether to show all languages on learning screen.
  final showAllLearningLanguages = false.obs;

  /// UUID from API; null for fallback (hardcoded) languages.
  String? selectedNativeLanguageId;
  String? selectedLearningLanguageId;

  LanguageContextService get _langCtx => Get.find<LanguageContextService>();
  Worker? _langCtxWorker;

  /// Persisted across onboarding screens; set by AiChatController on session start.
  String? conversationId;

  /// Set by AiChatController after POST /onboarding/complete.
  OnboardingProfile? onboardingProfile;

  /// True while scenario-gift screen re-fetches profile after a cold resume.
  final isRefetchingProfile = false.obs;

  Timer? _navigationTimer;

  /// Max languages to show before "Show all" is tapped.
  static const int _initialLanguageCount = 7;

  OnboardingProgressService get _progress =>
      Get.find<OnboardingProgressService>();

  @override
  void onInit() {
    super.onInit();
    // Seed mirror from service and keep in sync for the lifetime of this controller
    selectedLearningLanguage.value = _langCtx.activeCode.value ?? '';
    selectedLearningLanguageId = _langCtx.activeId.value;
    _langCtxWorker = ever<String?>(_langCtx.activeCode, (code) {
      selectedLearningLanguage.value = code ?? '';
      selectedLearningLanguageId = _langCtx.activeId.value;
    });
    _hydrateFromProgress().then((_) => loadLanguages());
    // On cold-resume into scenario-gift, the in-memory profile is null but the
    // progress map says completion happened. Microtask defers the network call
    // so the controller is fully constructed first.
    Future.microtask(refetchProfileIfNeeded);
  }

  /// Restores prior selections from persisted progress so resume screens
  /// reflect the user's previous choices without re-selection.
  Future<void> _hydrateFromProgress() async {
    final p = _progress.read();
    if (p.nativeLang != null) {
      selectedNativeLanguage.value = p.nativeLang!.code;
      selectedNativeLanguageId = p.nativeLang!.id;
    }
    if (p.learningLang != null) {
      // Await so interceptor has the code before any subsequent API calls
      await _langCtx.setActive(p.learningLang!.code, p.learningLang!.id);
      // Mirror updated reactively via ever() worker
    }
    if (p.chat != null) {
      conversationId = p.chat!.conversationId;
    }
  }

  /// Native languages filtered by search query.
  List<OnboardingLanguage> get filteredNativeLanguages {
    final query = nativeSearchQuery.value.toLowerCase().trim();
    if (query.isEmpty) return nativeLanguages;
    return nativeLanguages.where((lang) {
      return lang.name.toLowerCase().contains(query) ||
          lang.subtitle.toLowerCase().contains(query);
    }).toList();
  }

  /// Learning languages — limited or full list.
  List<OnboardingLanguage> get visibleLearningLanguages {
    if (showAllLearningLanguages.value ||
        learningLanguages.length <= _initialLanguageCount) {
      return learningLanguages;
    }
    return learningLanguages.sublist(0, _initialLanguageCount);
  }

  /// Whether "Show all" button should be visible.
  bool get canShowMoreLanguages =>
      !showAllLearningLanguages.value &&
      learningLanguages.length > _initialLanguageCount;

  Future<void> loadLanguages() async {
    isLoadingLanguages.value = true;
    try {
      final service = Get.find<OnboardingLanguageService>();
      final results = await Future.wait([
        service.getNativeLanguages(),
        service.getLearningLanguages(),
      ]);
      nativeLanguages.value = results[0];
      learningLanguages.value = results[1];
    } catch (_) {
      // Languages remain empty — views show error state with retry button
    } finally {
      isLoadingLanguages.value = false;
    }
  }

  /// Persists native language checkpoint before navigating. `await` guarantees
  /// the write completes even if the user kills the app mid-transition.
  Future<void> selectNativeLanguage(String code, {String? id}) async {
    selectedNativeLanguage.value = code;
    selectedNativeLanguageId = id;
    await _progress.setNativeLang(code, id: id);
    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 50), () {
      Get.toNamed(AppRoutes.onboardingLearningLanguage);
    });
  }

  Future<void> selectLearningLanguage(String code, {String? id}) async {
    // Service write must complete before navigation so interceptor has the code
    await _langCtx.setActive(code, id);
    await _progress.setLearningLang(code, id: id);
    // Mirror updates reactively via ever() worker — no manual assignment needed
    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 50), () {
      Get.toNamed(AppRoutes.chat);
    });
  }

  void toggleShowAllLanguages() {
    showAllLearningLanguages.value = !showAllLearningLanguages.value;
  }

  /// Re-fetches the onboarding profile when the scenario-gift screen is resumed
  /// from a cold start — in-memory `onboardingProfile` is null but the progress
  /// map says the user already completed onboarding.
  ///
  /// NOTE: Without backend idempotency (see `backend-requirements.md` §2), this
  /// re-triggers the LLM extraction and scenario UUIDs differ from the original
  /// run. Accepted trade-off documented in phase-03 risks.
  Future<void> refetchProfileIfNeeded() async {
    if (onboardingProfile != null) return;
    final p = _progress.read();
    if (!p.profileComplete || p.chat == null) return;

    isRefetchingProfile.value = true;
    try {
      final api = Get.find<ApiClient>();
      final response = await api.post<OnboardingProfile>(
        ApiEndpoints.onboardingComplete,
        data: {'conversation_id': p.chat!.conversationId},
        fromJson: (data) =>
            OnboardingProfile.fromJson(data as Map<String, dynamic>),
      );
      if (response.isSuccess && response.data != null) {
        onboardingProfile = response.data;
      }
    } catch (_) {
      // Best-effort — screen renders empty scenarios grid with translation key.
    } finally {
      isRefetchingProfile.value = false;
    }
  }

  @override
  void onClose() {
    _langCtxWorker?.dispose();
    _navigationTimer?.cancel();
    super.onClose();
  }
}
