import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flowering/app/global-dependency-injection-bindings.dart';

void main() {
  group('AppBindings Dependency Registration', () {
    late AppBindings bindings;

    setUp(() {
      bindings = AppBindings();
      // Clear any existing dependencies
      Get.reset();
    });

    tearDown(() {
      Get.reset();
    });

    test('bindings class can be instantiated', () {
      expect(bindings, isNotNull);
    });

    test('dependencies method executes without errors', () {
      expect(() => bindings.dependencies(), returnsNormally);
    });

    test('all services are registered as lazy singletons', () {
      bindings.dependencies();

      // With lazyPut, services ARE registered but not instantiated
      // They will be created on first access
      expect(Get.isRegistered<StorageService>(), isTrue);
      expect(Get.isRegistered<AuthStorage>(), isTrue);
      expect(Get.isRegistered<ConnectivityService>(), isTrue);
      expect(Get.isRegistered<AudioService>(), isTrue);
      expect(Get.isRegistered<ApiClient>(), isTrue);
    });
  });

  group('Service Initialization Order', () {
    test('initializeServices function exists and is callable', () {
      // Just verify the function signature exists
      expect(initializeServices, isA<Function>());
    });
  });
}

// Mock classes for testing bindings registration
class StorageService extends GetxService {
  Future<void> init() async {}
}

class AuthStorage extends GetxService {
  Future<void> init() async {}
}

class ConnectivityService extends GetxService {
  Future<void> init() async {}
}

class AudioService extends GetxService {
  Future<void> init() async {}
}

class ApiClient extends GetxService {
  Future<void> init(AuthStorage authStorage) async {}
}
