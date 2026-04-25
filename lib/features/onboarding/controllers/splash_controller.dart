import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_storage.dart';
import '../../../core/services/device-info-service.dart';
import '../../../core/services/storage_service.dart';
import '../models/onboarding_progress_model.dart';
import '../services/onboarding_progress_service.dart';

/// Decides onboarding resume target from persisted progress. Priority is
/// reverse chronological — the most advanced checkpoint wins. Exported for
/// unit testing; the controller delegates to this function.
String computeOnboardingResumeTarget(OnboardingProgress p) {
  if (p.profileComplete) return AppRoutes.onboardingScenarioGift;
  if (p.chat != null) return AppRoutes.chat;
  if (p.learningLang != null) return AppRoutes.chat;
  if (p.nativeLang != null) return AppRoutes.onboardingLearningLanguage;
  return AppRoutes.onboardingWelcome;
}

class SplashController extends BaseController {
  final _authStorage = Get.find<AuthStorage>();
  final _apiClient = Get.find<ApiClient>();
  final _progress = Get.find<OnboardingProgressService>();
  final _storage = Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final hasToken = _authStorage.isLoggedIn;

    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      _validateToken(),
    ]);

    final isValid = results[1] as bool;

    if (isValid) {
      Get.offAllNamed(AppRoutes.home);
    } else if (hasToken) {
      // Had a session before but token expired — show welcome back
      Get.offAllNamed(AppRoutes.onboardingWelcomeBack);
    } else if (_storage.hasCompletedLogin) {
      // Previously logged-in but now logged out: gate them to the intro screens
      // only — never drop them into language selection or chat. Screen 1 will
      // auto-show the auth sheet so the fastest path back is still one tap.
      Get.offAllNamed(AppRoutes.onboardingWelcome);
    } else {
      Get.offAllNamed(computeOnboardingResumeTarget(_progress.read()));
    }
  }

  Future<bool> _validateToken() async {
    if (!_authStorage.isLoggedIn) return false;

    try {
      // Dio already has built-in 15s connect + 30s receive timeouts
      final response = await _apiClient.post(ApiEndpoints.userMe);
      if (response.isSuccess) {
        _syncDeviceInfo();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Fire-and-forget: collect device context and PATCH /users/me.
  // Never blocks navigation or token validation result.
  void _syncDeviceInfo() {
    DeviceInfoService().collect().then((deviceInfo) {
      _apiClient.patch(ApiEndpoints.updateUserMe, data: deviceInfo).ignore();
    }).ignore();
  }
}
