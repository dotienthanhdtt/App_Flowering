import 'package:get/get.dart';
import '../core/services/cache-invalidator-service.dart';
import '../core/services/language-context-service.dart';
import '../core/services/storage_service.dart';
import '../core/services/auth_storage.dart';
import '../core/services/connectivity_service.dart';
import '../features/onboarding/services/onboarding_progress_service.dart';
import '../core/services/audio/contracts/tts-provider-contract.dart';
import '../core/services/audio/contracts/stt-provider-contract.dart';
import '../core/services/audio/contracts/audio-recorder-provider-contract.dart';
import '../core/services/audio/providers/flutter-tts-provider.dart';
import '../core/services/audio/providers/speech-to-text-provider.dart';
import '../core/services/audio/providers/record-audio-provider.dart';
import '../core/services/audio/tts-service.dart';
import '../core/services/audio/voice-input-service.dart';
import '../core/network/api_client.dart';
import '../features/subscription/controllers/subscription-controller.dart';
import '../features/subscription/services/revenuecat-service.dart';
import '../features/subscription/services/subscription-service.dart';
import '../core/services/translation-service.dart';
import '../features/scenarios/services/scenarios_service.dart';

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

    // Language context — single source of truth for active learning language
    Get.lazyPut<LanguageContextService>(
      () => LanguageContextService(),
      fenix: true,
    );

    // Cache invalidator — flushes language-scoped caches on language switch
    Get.lazyPut<CacheInvalidatorService>(
      () => CacheInvalidatorService(),
      fenix: true,
    );

    // Onboarding progress — unified resume state across restarts
    Get.lazyPut<OnboardingProgressService>(
      () => OnboardingProgressService(),
      fenix: true,
    );

    // Connectivity monitoring
    Get.lazyPut<ConnectivityService>(
      () => ConnectivityService(),
      fenix: true,
    );

    // Audio providers — registered by contract type for swappability
    Get.lazyPut<TtsProviderContract>(
      () => FlutterTtsProvider(),
      fenix: true,
    );

    Get.lazyPut<SttProviderContract>(
      () => SpeechToTextProvider(),
      fenix: true,
    );

    Get.lazyPut<AudioRecorderProviderContract>(
      () => RecordAudioProvider(),
      fenix: true,
    );

    // Audio services
    Get.lazyPut<TtsService>(
      () => TtsService(),
      fenix: true,
    );

    Get.lazyPut<VoiceInputService>(
      () => VoiceInputService(),
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

    // Scenarios service — shared by both Home feed controllers.
    Get.lazyPut<ScenariosService>(
      () => ScenariosService(),
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

  // Language context — must init BEFORE ApiClient so interceptor has a code on boot
  final languageContext = Get.put(LanguageContextService());
  await languageContext.init();

  // Cache invalidator — subscribes to language changes; must init after language context
  final cacheInvalidator = Get.put(CacheInvalidatorService());
  await cacheInvalidator.init();

  // Onboarding progress — depends on StorageService; runs legacy-key migration
  final onboardingProgress = Get.put(OnboardingProgressService());
  await onboardingProgress.init();

  // Network connectivity monitoring
  final connectivityService = Get.put(ConnectivityService());
  await connectivityService.init();

  // Audio providers (lazy — initialized by services)
  Get.put<TtsProviderContract>(FlutterTtsProvider());
  Get.put<SttProviderContract>(SpeechToTextProvider());
  Get.put<AudioRecorderProviderContract>(RecordAudioProvider());

  // Audio services — TTS before VoiceInput (VoiceInput depends on TTS)
  final ttsService = Get.put(TtsService());
  await ttsService.init();

  final voiceInputService = Get.put(VoiceInputService());
  await voiceInputService.init();

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
