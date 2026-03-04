import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/onboarding_controller.dart';
import '../services/onboarding_language_service.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    // Register service before controller so onInit() can find it.
    if (!Get.isRegistered<OnboardingLanguageService>()) {
      Get.lazyPut<OnboardingLanguageService>(
        () => OnboardingLanguageService(
          Get.find<ApiClient>(),
          Get.find<StorageService>(),
        ),
      );
    }

    // permanent: true keeps the controller alive across screens so language
    // selections persist throughout the entire onboarding flow.
    // IMPORTANT: Call Get.delete<OnboardingController>() after successful auth.
    if (!Get.isRegistered<OnboardingController>()) {
      Get.put<OnboardingController>(OnboardingController(), permanent: true);
    }
  }
}
