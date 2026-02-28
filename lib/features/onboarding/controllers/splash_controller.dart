import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_storage.dart';

class SplashController extends GetxController {
  final _authStorage = Get.find<AuthStorage>();
  final _apiClient = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      _validateToken(),
    ]);

    final isValid = results[1] as bool;

    if (isValid) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.onboardingWelcome);
    }
  }

  Future<bool> _validateToken() async {
    if (!_authStorage.isLoggedIn) return false;

    try {
      // Dio already has built-in 15s connect + 30s receive timeouts
      final response = await _apiClient.get(ApiEndpoints.userMe);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }
}
