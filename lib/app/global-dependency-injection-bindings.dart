import 'dart:async';

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

/// Tracks whether [initializeDeferredServices] has finished running.
/// Screens that touch a deferred service on an unusually fast route can
/// `await deferredInitDone` to guarantee the service is ready.
final Completer<void> _deferredInitCompleter = Completer<void>();
Future<void> get deferredInitDone => _deferredInitCompleter.future;

/// Initialize only services required to paint the first frame and make the
/// splash-screen auth decision.
///
/// Call this in `main.dart` BEFORE `runApp`. Deferred services are kicked
/// off after the first frame via [initializeDeferredServices].
Future<void> initializeCriticalServices() async {
  // Auth storage (splash reads cached token to route)
  final authStorage = Get.put(AuthStorage());
  await authStorage.init();

  // Storage — onboarding progress, LRU caches
  final storageService = Get.put(StorageService());
  await storageService.init();

  // Language context — must init before ApiClient so interceptor has a code
  final languageContext = Get.put(LanguageContextService());
  await languageContext.init();

  // Cache invalidator — subscribes to language changes
  final cacheInvalidator = Get.put(CacheInvalidatorService());
  await cacheInvalidator.init();

  // Onboarding progress — splash uses this to pick the resume route
  final onboardingProgress = Get.put(OnboardingProgressService());
  await onboardingProgress.init();

  // API client — first-frame routes may kick off prefetches
  final apiClient = Get.put(ApiClient());
  await apiClient.init(authStorage);
}

/// Initialize non-critical services post-first-frame. Safe to call once —
/// subsequent calls are no-ops. Completes [deferredInitDone] on success.
Future<void> initializeDeferredServices() async {
  if (_deferredInitCompleter.isCompleted) return;
  try {
    // Connectivity monitoring — offline banner appears only after 1st frame
    final connectivityService = Get.put(ConnectivityService());
    await connectivityService.init();

    // Audio stack — only used on chat screen
    Get.put<TtsProviderContract>(FlutterTtsProvider());
    Get.put<SttProviderContract>(SpeechToTextProvider());
    Get.put<AudioRecorderProviderContract>(RecordAudioProvider());

    final ttsService = Get.put(TtsService());
    await ttsService.init();

    final voiceInputService = Get.put(VoiceInputService());
    await voiceInputService.init();

    // Subscription stack — not needed before login completes
    final revenueCatService = Get.put(RevenueCatService());
    await revenueCatService.init();

    final subscriptionService = Get.put(SubscriptionService());
    await subscriptionService.init();

    Get.put(TranslationService(), permanent: true);
  } finally {
    if (!_deferredInitCompleter.isCompleted) {
      _deferredInitCompleter.complete();
    }
  }
}

/// Legacy entry point — preserved for callers/tests that expect the old
/// eager init order. Equivalent to critical + deferred run sequentially.
Future<void> initializeServices() async {
  await initializeCriticalServices();
  await initializeDeferredServices();
}
