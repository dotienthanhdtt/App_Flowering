// lib/core/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Connectivity service for online/offline detection
class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  final _isOnline = true.obs;
  bool get isOnline => _isOnline.value;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Initialize connectivity service
  Future<ConnectivityService> init() async {
    // Check initial state
    await _checkConnectivity();

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    return this;
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline.value;
    _isOnline.value = !results.contains(ConnectivityResult.none);

    // Notify when coming back online
    if (!wasOnline && _isOnline.value) {
      _onBackOnline();
    }
  }

  void _onBackOnline() {
    // Trigger sync queue processing
    // Will be implemented when sync service exists
  }

  /// Manually refresh connectivity status
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isOnline.value;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
