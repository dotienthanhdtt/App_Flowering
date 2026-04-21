import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/onboarding_controller.dart';
import '../services/onboarding_language_service.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent across the onboarding/chat route stack. Route-scoped registration
    // gets disposed when the owning route is removed via Get.offNamed, even if
    // downstream routes still depend on it — producing "controller not found"
    // errors. Persistent data still lives in OnboardingProgressService.
    if (!Get.isRegistered<OnboardingLanguageService>()) {
      Get.put<OnboardingLanguageService>(
        OnboardingLanguageService(
          Get.find<ApiClient>(),
          Get.find<StorageService>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<OnboardingController>()) {
      Get.put<OnboardingController>(OnboardingController(), permanent: true);
    }
  }
}
