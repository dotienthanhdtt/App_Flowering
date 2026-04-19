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
import '../../../core/services/storage_service.dart';
import '../../onboarding/services/onboarding_progress_service.dart';
import '../models/auth_response_model.dart';
import '../utils/firebase_auth_error_mapper.dart';

/// Manages email/password auth + social auth stubs.
/// Reads conversationId from StorageService to link onboarding with account.
class AuthController extends BaseController {
  final ApiClient _apiClient = Get.find();
  final AuthStorage _authStorage = Get.find();
  final StorageService _storageService = Get.find();
  final OnboardingProgressService _progressSvc =
      Get.find<OnboardingProgressService>();

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
    // Mark that this device has completed login at least once.
    // This flag persists through logout so returning users see auth on
    // onboarding intro screens instead of re-entering onboarding flows.
    await _storageService.setHasCompletedLogin();
    Get.offAllNamed(AppRoutes.home);
  }

  // ── Social auth via Firebase ──────────────────────────────────

  Future<void> signInWithGoogle() async {
    errorMessage.value = '';
    try {
      // serverClientId = Web Client ID (type 3) from google-services.json
      // Required on Android to receive an idToken from Google Sign-In
      final googleSignIn = GoogleSignIn(
        scopes: ['email'],
        serverClientId:
            '898715197112-g89g04i54mpeqcjau6ptpu6vn33iful0.apps.googleusercontent.com',
      );
      // No overlay during native picker — OS owns that UI
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // user cancelled

      // Native picker closed with an account — show overlay during Firebase/API calls
      isLoading.value = true;
      _showLoadingOverlay();
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _authenticateWithFirebase(credential);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = mapFirebaseAuthErrorCode(e.code).tr;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      errorMessage.value = 'google_sign_in_failed'.tr;
    } finally {
      isLoading.value = false;
      _hideLoadingOverlay();
    }
  }

  Future<void> signInWithApple() async {
    if (!Platform.isIOS) return;
    errorMessage.value = '';
    try {
      // No overlay during native picker — OS owns that UI
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Native picker closed with credentials — show overlay during Firebase/API calls
      isLoading.value = true;
      _showLoadingOverlay();
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await _authenticateWithFirebase(oauthCredential);
    } on SignInWithAppleAuthorizationException {
      // user cancelled — do nothing
    } on FirebaseAuthException catch (e) {
      errorMessage.value = mapFirebaseAuthErrorCode(e.code).tr;
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      errorMessage.value = 'apple_sign_in_failed'.tr;
    } finally {
      isLoading.value = false;
      _hideLoadingOverlay();
    }
  }

  void _showLoadingOverlay() {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      const Center(child: LoadingWidget()),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
  }

  void _hideLoadingOverlay() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  /// Signs in to Firebase, gets ID token, then calls backend /auth/firebase.
  Future<void> _authenticateWithFirebase(AuthCredential credential) async {
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) {
      errorMessage.value = 'firebase_token_error'.tr;
      return;
    }
    final response = await _apiClient.post<AuthResponse>(
      ApiEndpoints.loginFirebase,
      data: {
        'id_token': idToken,
        'display_name': userCredential.user?.displayName,
        if (_conversationId != null) 'conversation_id': _conversationId,
      },
      fromJson: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );
    if (response.isSuccess && response.data != null) {
      await _handleAuthSuccess(response.data!);
    } else {
      errorMessage.value = response.message;
    }
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
