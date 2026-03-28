import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';

/// Manages the 3-screen forgot-password flow: email → OTP → new password.
/// resetToken held in memory only; never persisted.
class ForgotPasswordController extends BaseController {
  final ApiClient _apiClient = Get.find();

  final forgotEmail = ''.obs;
  final otpCountdown = 0.obs;
  final obscureNewPassword = true.obs;
  final obscureConfirmNewPassword = true.obs;

  final forgotPasswordFormKey = GlobalKey<FormState>();
  final newPasswordFormKey = GlobalKey<FormState>();
  final forgotEmailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  String? _resetToken;
  Timer? _countdownTimer;

  /// e.g. "user@example.com" → "u***@example.com"
  String get maskedEmail {
    final email = forgotEmail.value;
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final masked = local.length <= 2 ? local : '${local[0]}${'*' * (local.length - 1)}';
    return '$masked@${parts[1]}';
  }

  // ── Validators ──────────────────────────────────────────────────

  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'email_required'.tr;
    if (!GetUtils.isEmail(v.trim())) return 'email_invalid'.tr;
    return null;
  }

  String? validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'password_required'.tr;
    if (v.length < 8) return 'password_min_length'.tr;
    return null;
  }

  String? validateConfirmNewPassword(String? v) {
    if (v != newPasswordController.text) return 'passwords_not_match'.tr;
    return null;
  }

  // ── Actions ─────────────────────────────────────────────────────

  Future<void> forgotPassword() async {
    if (!(forgotPasswordFormKey.currentState?.validate() ?? false)) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final email = forgotEmailController.text.trim();
      final response = await _apiClient.post<dynamic>(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      if (response.isSuccess) {
        forgotEmail.value = email;
        _startCountdown();
        Get.toNamed(AppRoutes.otpVerification);
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

  Future<void> resendOtp() async {
    if (otpCountdown.value > 0) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.post<dynamic>(
        ApiEndpoints.forgotPassword,
        data: {'email': forgotEmail.value},
      );
      if (response.isSuccess) {
        _startCountdown();
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

  Future<void> verifyOtp(String otp) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.verifyOtp,
        data: {'email': forgotEmail.value, 'otp': otp},
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        _resetToken = response.data!['reset_token'] as String?;
        Get.toNamed(AppRoutes.newPassword);
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

  Future<void> resetPassword() async {
    if (!(newPasswordFormKey.currentState?.validate() ?? false)) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.post<dynamic>(
        ApiEndpoints.resetPassword,
        data: {
          'reset_token': _resetToken,
          'new_password': newPasswordController.text,
        },
      );
      if (response.isSuccess) {
        _resetToken = null;
        Get.offNamedUntil(AppRoutes.login, (_) => false);
        Get.snackbar(
          'password_reset_title'.tr,
          'password_reset_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
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

  void _startCountdown() {
    otpCountdown.value = 47;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpCountdown.value <= 0) {
        timer.cancel();
      } else {
        otpCountdown.value--;
      }
    });
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    forgotEmailController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.onClose();
  }
}
