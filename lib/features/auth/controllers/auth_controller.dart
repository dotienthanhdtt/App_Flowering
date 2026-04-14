import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/auth_storage.dart';
import '../../../core/services/storage_service.dart';
import '../models/auth_response_model.dart';

/// Manages email/password auth + social auth stubs.
/// Reads conversationId from StorageService to link onboarding with account.
class AuthController extends BaseController {
  final ApiClient _apiClient = Get.find();
  final AuthStorage _authStorage = Get.find();
  final StorageService _storageService = Get.find();

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

  String? get _conversationId =>
      _storageService.getPreference<String>('onboarding_conversation_id');

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
    await _storageService.removePreference('onboarding_conversation_id');
    Get.offAllNamed(AppRoutes.home);
  }

  // ── Social auth via Firebase ──────────────────────────────────

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // serverClientId = Web Client ID (type 3) from google-services.json
      // Required on Android to receive an idToken from Google Sign-In
      final googleSignIn = GoogleSignIn(
        scopes: ['email'],
        serverClientId:
            '898715197112-g89g04i54mpeqcjau6ptpu6vn33iful0.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return; // user cancelled
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _authenticateWithFirebase(credential);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'google_sign_in_failed'.tr;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      errorMessage.value = 'google_sign_in_failed'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithApple() async {
    if (!Platform.isIOS) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await _authenticateWithFirebase(oauthCredential);
    } on SignInWithAppleAuthorizationException {
      // user cancelled — do nothing
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'apple_sign_in_failed'.tr;
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      errorMessage.value = 'apple_sign_in_failed'.tr;
    } finally {
      isLoading.value = false;
    }
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
        'idToken': idToken,
        'displayName': userCredential.user?.displayName,
        if (_conversationId != null) 'conversationId': _conversationId,
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
