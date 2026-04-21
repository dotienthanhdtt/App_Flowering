import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/auth_storage.dart';
import '../../../core/services/language-context-service.dart';
import '../../../core/services/storage_service.dart';
import '../../onboarding/services/onboarding_progress_service.dart';
import '../models/auth_response_model.dart';
import '../utils/firebase_auth_error_mapper.dart';
import 'auth_validators.dart';

part 'auth_controller_social.dart';

/// Manages email/password auth + social auth stubs.
/// Reads conversationId from StorageService to link onboarding with account.
class AuthController extends BaseController {
  final ApiClient _apiClient = Get.find();
  final AuthStorage _authStorage = Get.find();
  final StorageService _storageService = Get.find();
  final OnboardingProgressService _progressSvc =
      Get.find<OnboardingProgressService>();
  final LanguageContextService _langCtx = Get.find<LanguageContextService>();

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

  String? get _conversationId => _progressSvc.read().chat?.conversationId;

  // ── Validators (delegate to pure functions in auth_validators.dart) ──

  String? validateFullName(String? v) => validateFullNameFn(v);
  String? validateEmail(String? v) => validateEmailFn(v);
  String? validatePassword(String? v) => validatePasswordFn(v);
  String? validateConfirmPassword(String? v, String password) =>
      validateConfirmPasswordFn(v, password);

  // ── Auth actions ─────────────────────────────────────────────────

  Future<void> register() async {
    if (!(signupFormKey.currentState?.validate() ?? false)) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.post<AuthResponse>(
        ApiEndpoints.register,
        data: {
          'name': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          if (_conversationId != null) 'conversation_id': _conversationId,
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
          if (_conversationId != null) 'conversation_id': _conversationId,
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
    await _progressSvc.clearChat();
    // Returning users who sign in without going through onboarding have no
    // locally stored active language, which leaves the x-language header
    // empty. Seed from the server's languages list (createdAt DESC — newest
    // first) so subsequent requests carry a valid header. Preserve any
    // existing active code so we never clobber an in-flight onboarding
    // selection.
    final activeCode = _langCtx.activeCode.value;
    if ((activeCode == null || activeCode.isEmpty) && auth.languages.isNotEmpty) {
      final first = auth.languages.first;
      await _langCtx.setActive(first.language.code, first.languageId);
    }
    // Mark that this device has completed login at least once.
    // This flag persists through logout so returning users see auth on
    // onboarding intro screens instead of re-entering onboarding flows.
    await _storageService.setHasCompletedLogin();
    Get.offAllNamed(AppRoutes.home);
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
