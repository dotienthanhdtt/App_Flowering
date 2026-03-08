import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/auth_storage.dart';
import '../../../core/services/storage_service.dart';
import '../models/auth_response_model.dart';

/// Manages email/password auth + social auth stubs.
/// Reads sessionToken from StorageService to link onboarding with account.
class AuthController extends GetxController {
  final ApiClient _apiClient = Get.find();
  final AuthStorage _authStorage = Get.find();
  final StorageService _storageService = Get.find();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;

  // Signup form
  final signupFormKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Login form
  final loginFormKey = GlobalKey<FormState>();
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  String? get _sessionToken =>
      _storageService.getPreference<String>('onboarding_session_token');

  // ── Validators ──────────────────────────────────────────────────

  String? validateFullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'full_name_required'.tr;
    return null;
  }

  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'email_required'.tr;
    if (!GetUtils.isEmail(v.trim())) return 'email_invalid'.tr;
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'password_required'.tr;
    if (v.length < 8) return 'password_min_length'.tr;
    return null;
  }

  String? validateConfirmPassword(String? v, String password) {
    if (v != password) return 'passwords_not_match'.tr;
    return null;
  }

  // ── Auth actions ─────────────────────────────────────────────────

  Future<void> register() async {
    if (!(signupFormKey.currentState?.validate() ?? false)) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.post<AuthResponse>(
        ApiEndpoints.register,
        data: {
          'fullName': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          if (_sessionToken != null) 'sessionToken': _sessionToken,
        },
        fromJson: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
      );
      if (response.isSuccess && response.data != null) {
        await _handleAuthSuccess(response.data!);
      } else {
        errorMessage.value = response.message;
      }
    } on ValidationException catch (e) {
      errorMessage.value = e.userMessage;
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;
    } catch (_) {
      errorMessage.value = 'unknown_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() async {
    if (!(loginFormKey.currentState?.validate() ?? false)) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.post<AuthResponse>(
        ApiEndpoints.login,
        data: {
          'email': loginEmailController.text.trim(),
          'password': loginPasswordController.text,
          if (_sessionToken != null) 'sessionToken': _sessionToken,
        },
        fromJson: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
      );
      if (response.isSuccess && response.data != null) {
        await _handleAuthSuccess(response.data!);
      } else {
        errorMessage.value = response.message;
      }
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;
    } catch (_) {
      errorMessage.value = 'unknown_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleAuthSuccess(AuthResponse auth) async {
    await _authStorage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    await _authStorage.saveUserId(auth.user.id);
    await _storageService.removePreference('onboarding_session_token');
    Get.offAllNamed(AppRoutes.home);
  }

  // Social auth — implemented when native SDKs are configured
  Future<void> signInWithGoogle() async {
    // TODO: implement google_sign_in
  }

  Future<void> signInWithApple() async {
    // TODO: implement sign_in_with_apple
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    super.onClose();
  }
}
