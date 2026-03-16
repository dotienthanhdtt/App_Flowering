import 'package:get/get.dart';
import '../core/services/storage_service.dart';
import '../core/services/auth_storage.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/audio_service.dart';
import '../core/network/api_client.dart';
import '../features/subscription/controllers/subscription-controller.dart';
import '../features/subscription/services/revenuecat-service.dart';
import '../features/subscription/services/subscription-service.dart';
import '../core/services/translation-service.dart';

/// Global dependency injection for core services
///
/// Uses lazy loading with fenix:true for automatic recreation
/// when dependencies are accessed after disposal
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Storage services - permanent, lazy loaded
    Get.lazyPut<StorageService>(
      () => StorageService(),
      fenix: true,
    );

    Get.lazyPut<AuthStorage>(
      () => AuthStorage(),
      fenix: true,
    );

    // Connectivity monitoring
    Get.lazyPut<ConnectivityService>(
      () => ConnectivityService(),
      fenix: true,
    );

    // Audio playback and recording
    Get.lazyPut<AudioService>(
      () => AudioService(),
      fenix: true,
    );

    // API client depends on AuthStorage
    Get.lazyPut<ApiClient>(
      () => ApiClient(),
      fenix: true,
    );

    // Subscription services
    Get.lazyPut<RevenueCatService>(
      () => RevenueCatService(),
      fenix: true,
    );

    Get.lazyPut<SubscriptionService>(
      () => SubscriptionService(),
      fenix: true,
    );

    // SubscriptionController registered globally — used by SubscriptionStatusWidget
    // across multiple screens (settings, profile, etc.)
    Get.lazyPut<SubscriptionController>(
      () => SubscriptionController(),
      fenix: true,
    );
  }
}

/// Initialize all core services in dependency order
///
/// Call this in main.dart before runApp()
/// Services are initialized with proper dependency chain
Future<void> initializeServices() async {
  // Auth storage first (required by API client)
  final authStorage = Get.put(AuthStorage());
  await authStorage.init();

  // General storage service
  final storageService = Get.put(StorageService());
  await storageService.init();

  // Network connectivity monitoring
  final connectivityService = Get.put(ConnectivityService());
  await connectivityService.init();

  // Audio services for voice messages
  final audioService = Get.put(AudioService());
  await audioService.init();

  // API client last (depends on auth storage)
  final apiClient = Get.put(ApiClient());
  await apiClient.init(authStorage);

  // RevenueCat SDK — must be after API client
  final revenueCatService = Get.put(RevenueCatService());
  await revenueCatService.init();

  // Subscription service — depends on RevenueCatService, ApiClient, AuthStorage, StorageService
  final subscriptionService = Get.put(SubscriptionService());
  await subscriptionService.init();

  // Translation service (depends on API client)
  Get.put(TranslationService(), permanent: true);
}
