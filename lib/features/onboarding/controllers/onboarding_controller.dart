import 'dart:async';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_controller.dart';
import '../models/onboarding_language_model.dart';
import '../models/onboarding_profile_model.dart';
import '../services/onboarding_language_service.dart';

class OnboardingController extends BaseController {
  final selectedNativeLanguage = 'vi'.obs;
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

  /// Persisted across onboarding screens; set by AiChatController on session start.
  String? conversationId;

  /// Set by AiChatController after POST /onboarding/complete.
  OnboardingProfile? onboardingProfile;

  Timer? _navigationTimer;

  /// Max languages to show before "Show all" is tapped.
  static const int _initialLanguageCount = 7;

  @override
  void onInit() {
    super.onInit();
    loadLanguages();
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

  void selectNativeLanguage(String code, {String? id}) {
    selectedNativeLanguage.value = code;
    selectedNativeLanguageId = id;
    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 400), () {
      Get.toNamed(AppRoutes.onboardingLearningLanguage);
    });
  }

  void selectLearningLanguage(String code, {String? id}) {
    selectedLearningLanguage.value = code;
    selectedLearningLanguageId = id;
  }

  /// Called by Continue button on learning language screen.
  void confirmLearningLanguage() {
    if (selectedLearningLanguage.value.isNotEmpty) {
      Get.toNamed(AppRoutes.chat);
    }
  }

  void toggleShowAllLanguages() {
    showAllLearningLanguages.value = !showAllLearningLanguages.value;
  }

  @override
  void onClose() {
    _navigationTimer?.cancel();
    super.onClose();
  }
}
