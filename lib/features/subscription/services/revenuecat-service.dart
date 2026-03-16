import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../config/env_config.dart';

/// Thin wrapper around RevenueCat SDK.
/// No business logic — just SDK calls. Callers handle errors.
class RevenueCatService extends GetxService {
  bool _isConfigured = false;
  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  bool get isConfigured => _isConfigured;

  Future<RevenueCatService> init() async {
    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      final apiKey = Platform.isIOS
          ? EnvConfig.revenueCatAppleApiKey
          : EnvConfig.revenueCatGoogleApiKey;
      if (apiKey.isEmpty) return this;
      final config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);
      _isConfigured = true;
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    } catch (e, stackTrace) {
      debugPrint('RevenueCat init failed: $e\n$stackTrace');
    }
    return this;
  }

  void _ensureConfigured() {
    if (!_isConfigured) {
      throw StateError('RevenueCatService not configured. Check API keys.');
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    if (!_customerInfoController.isClosed) {
      _customerInfoController.add(info);
    }
  }

  Future<LogInResult> logIn(String userId) {
    _ensureConfigured();
    return Purchases.logIn(userId);
  }

  Future<CustomerInfo> logOut() {
    _ensureConfigured();
    return Purchases.logOut();
  }

  Future<Offerings> getOfferings() {
    _ensureConfigured();
    return Purchases.getOfferings();
  }

  Future<CustomerInfo> purchasePackage(Package package) {
    _ensureConfigured();
    return Purchases.purchasePackage(package);
  }

  Future<CustomerInfo> restorePurchases() {
    _ensureConfigured();
    return Purchases.restorePurchases();
  }

  Future<CustomerInfo> getCustomerInfo() {
    _ensureConfigured();
    return Purchases.getCustomerInfo();
  }

  Stream<CustomerInfo> get customerInfoStream =>
      _customerInfoController.stream;

  @override
  void onClose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _customerInfoController.close();
    super.onClose();
  }
}
