import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../network/api_exceptions.dart';

/// Base controller with common loading/error handling
abstract class BaseController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// Minimum time [isLoading] stays `true` once shown, so fast responses
  /// don't produce a jarring loading-flash.
  static const Duration _minLoadingDuration = Duration(seconds: 2);

  /// Per-controller cancel token. Cancelled in [onClose] so in-flight
  /// requests drop their results instead of mutating disposed state.
  /// Callers may pass this to [ApiClient] methods via the `cancelToken` arg.
  final CancelToken _lifecycleToken = CancelToken();
  CancelToken get cancelToken => _lifecycleToken;

  @override
  void onClose() {
    if (!_lifecycleToken.isCancelled) {
      _lifecycleToken.cancel('controller_disposed');
    }
    super.onClose();
  }

  /// Wrap API calls with loading state and error handling
  Future<T?> apiCall<T>(
    Future<T> Function() call, {
    bool showLoading = true,
    void Function(T result)? onSuccess,
    void Function(ApiException error)? onError,
  }) async {
    DateTime? loadingStartedAt;
    try {
      if (showLoading) {
        isLoading.value = true;
        loadingStartedAt = DateTime.now();
      }
      errorMessage.value = '';

      final result = await call();

      if (_lifecycleToken.isCancelled) return null;
      if (onSuccess != null) {
        onSuccess(result);
      }

      return result;
    } on ApiException catch (e) {
      if (_lifecycleToken.isCancelled) return null;
      errorMessage.value = e.userMessage;

      if (onError != null) {
        onError(e);
      } else {
        _showErrorSnackbar(e.userMessage);
      }

      return null;
    } catch (e) {
      // Dio cancellation surfaces as a DioException — treat as a no-op drop.
      if (e is DioException && CancelToken.isCancel(e)) return null;
      if (_lifecycleToken.isCancelled) return null;

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
      if (showLoading && loadingStartedAt != null && !_lifecycleToken.isCancelled) {
        final elapsed = DateTime.now().difference(loadingStartedAt);
        if (elapsed < _minLoadingDuration) {
          await Future.delayed(_minLoadingDuration - elapsed);
        }
        if (!_lifecycleToken.isCancelled) {
          isLoading.value = false;
        }
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
