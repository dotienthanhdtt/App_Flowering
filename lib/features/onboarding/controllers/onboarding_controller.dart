import 'dart:async';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';

class OnboardingController extends GetxController {
  final selectedNativeLanguage = 'vi'.obs;
  final selectedLearningLanguage = 'en'.obs;

  Timer? _navigationTimer;

  void selectNativeLanguage(String code) {
    selectedNativeLanguage.value = code;
    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 400), () {
      Get.toNamed(AppRoutes.onboardingLearningLanguage);
    });
  }

  void selectLearningLanguage(String code) {
    selectedLearningLanguage.value = code;
    _navigationTimer?.cancel();
    // Navigate to Screen 3 (AI Chat placeholder)
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
