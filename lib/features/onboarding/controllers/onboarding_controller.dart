import 'dart:async';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../models/onboarding_language_model.dart';
import '../models/onboarding_profile_model.dart';
import '../services/onboarding_language_service.dart';

class OnboardingController extends GetxController {
  final selectedNativeLanguage = 'vi'.obs;
  final selectedLearningLanguage = 'en'.obs;
  final nativeLanguages = <OnboardingLanguage>[].obs;
  final learningLanguages = <OnboardingLanguage>[].obs;
  final isLoadingLanguages = true.obs;

  /// UUID from API; null for fallback (hardcoded) languages.
  String? selectedNativeLanguageId;
  String? selectedLearningLanguageId;

  /// Persisted across onboarding screens; set by AiChatController on session start.
  String? sessionToken;

  /// Set by AiChatController after POST /onboarding/complete.
  OnboardingProfile? onboardingProfile;

  Timer? _navigationTimer;

  @override
  void onInit() {
    super.onInit();
    loadLanguages();
  }

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
    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 400), () {
      Get.toNamed(AppRoutes.chat);
    });
  }

  @override
  void onClose() {
    _navigationTimer?.cancel();
    super.onClose();
  }
}
