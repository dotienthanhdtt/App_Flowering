import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flowering/core/network/api_client.dart';
import 'package:flowering/core/services/storage_service.dart';
import 'package:flowering/features/chat/bindings/ai_chat_binding.dart';
import 'package:flowering/features/onboarding/controllers/onboarding_controller.dart';
import 'package:flowering/features/onboarding/services/onboarding_progress_service.dart';

/// Regression test for cold-resume crash:
/// "OnboardingController not found" on splash → /chat after app restart.
///
/// Repro: splash routes directly to /chat from a persisted chat checkpoint,
/// skipping the onboarding screens that normally register OnboardingController.
/// Fix: AiChatBinding now delegates to OnboardingBinding first.
class _FakeStorageService extends StorageService {
  final Map<String, dynamic> _prefs = {};

  @override
  Future<StorageService> init() async => this;

  @override
  T? getPreference<T>(String key) => _prefs[key] as T?;

  @override
  Future<void> setPreference<T>(String key, T value) async {
    _prefs[key] = value;
  }

  @override
  Future<void> removePreference(String key) async {
    _prefs.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    // Minimum DI surface required by OnboardingController + language service
    Get.put<StorageService>(_FakeStorageService());
    Get.put<ApiClient>(ApiClient());
    Get.put<OnboardingProgressService>(OnboardingProgressService());
  });

  tearDown(() => Get.reset());

  test(
      'AiChatBinding registers OnboardingController when invoked without prior '
      'OnboardingBinding (cold-resume path)', () {
    expect(Get.isRegistered<OnboardingController>(), isFalse,
        reason: 'precondition: controller should not exist before binding');

    AiChatBinding().dependencies();

    expect(Get.isRegistered<OnboardingController>(), isTrue,
        reason:
            'AiChatBinding must make OnboardingController resolvable so that '
            'AiChatController.Get.find<OnboardingController>() does not throw.');
  });
}
