import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true keeps the controller alive across screens so sessionToken
    // and language selections persist throughout the entire onboarding flow.
    // Guard prevents double-registration when binding is invoked for multiple routes.
    //
    // IMPORTANT: Call Get.delete<OnboardingController>() in Phase 05 AuthController
    // after successful auth to release this controller and its state.
    if (!Get.isRegistered<OnboardingController>()) {
      Get.put<OnboardingController>(OnboardingController(), permanent: true);
    }
  }
}
