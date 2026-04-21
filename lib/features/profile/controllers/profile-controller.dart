import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/services/auth_storage.dart';
import '../../../core/services/language-context-service.dart';
import '../../../core/services/storage_service.dart';

/// Controller for profile tab
class ProfileController extends BaseController {
  final AuthStorage _authStorage = Get.find();
  final StorageService _storageService = Get.find();

  final userName = ''.obs;
  final userEmail = ''.obs;

  void logout() {
    Get.defaultDialog(
      title: 'logout'.tr,
      middleText: 'logout_confirm'.tr,
      textConfirm: 'confirm'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Get.theme.colorScheme.onError,
      buttonColor: Get.theme.colorScheme.error,
      onConfirm: () {
        Get.back();
        _performLogout();
      },
    );
  }

  Future<void> _performLogout() async {
    isLoading.value = true;
    try {
      await _authStorage.clearTokens();
      await _storageService.clearAll();
      if (Get.isRegistered<LanguageContextService>()) {
        await Get.find<LanguageContextService>().clear();
      }
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed(AppRoutes.onboardingWelcome);
    } catch (_) {
      errorMessage.value = 'Something went wrong';
    } finally {
      isLoading.value = false;
    }
  }
}
