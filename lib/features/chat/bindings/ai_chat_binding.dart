import 'package:get/get.dart';
import '../../onboarding/bindings/onboarding_binding.dart';
import '../controllers/ai_chat_controller.dart';

class AiChatBinding extends Bindings {
  @override
  void dependencies() {
    // Resume path: users landing directly on /chat from a cold start skip the
    // onboarding screens, so OnboardingController (+ language service) were
    // never registered. Delegate to OnboardingBinding — it's idempotent via
    // Get.isRegistered guards, so no-op when arriving via the normal flow.
    OnboardingBinding().dependencies();

    Get.lazyPut<AiChatController>(() => AiChatController());
  }
}
