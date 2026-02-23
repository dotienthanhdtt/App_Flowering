import 'package:get/get.dart';
import '../network/api_exceptions.dart';

/// Base controller with common loading/error handling
abstract class BaseController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// Wrap API calls with loading state and error handling
  Future<T?> apiCall<T>(
    Future<T> Function() call, {
    bool showLoading = true,
    void Function(T result)? onSuccess,
    void Function(ApiException error)? onError,
  }) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final result = await call();

      if (onSuccess != null) {
        onSuccess(result);
      }

      return result;
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;

      if (onError != null) {
        onError(e);
      } else {
        _showErrorSnackbar(e.userMessage);
      }

      return null;
    } catch (e) {
      const message = 'Something went wrong';
      errorMessage.value = message;

      if (onError != null) {
        onError(const ApiErrorException(
          message: 'Unknown error',
          userMessage: message,
        ));
      } else {
        _showErrorSnackbar(message);
      }

      return null;
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    if (Get.isSnackbarOpen) return;

    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show success snackbar
  void showSuccess(String message) {
    if (Get.isSnackbarOpen) return;

    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}
