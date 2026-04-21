# Phase 05 — Startup Time: Deferred Service Init

## Context Links
- `research/researcher-01-performance.md` H5

## Overview
- **Priority:** P2 (perceived launch speed)
- **Status:** pending
- **Effort:** ~2h

Reduce time-to-first-frame by deferring non-critical service init until after the first frame renders.

## Key Insights
- `initializeServices()` currently awaits every service before `runApp`. Required immediately: AuthStorage (for splash auth check), StorageService (for onboarding progress), LanguageContext (for API interceptor), ApiClient.
- Non-critical at first frame: RevenueCat (paywall), SubscriptionService (only needed after login for non-free features), TtsService (only needed in chat), VoiceInputService (already lazy), ConnectivityService (listeners can start after frame), TranslationService, ScenariosService.

## Requirements

**Functional**
- App launches to first rendered frame as fast as possible.
- Deferred services must be ready before their first use (guaranteed by `Future` await chain or Get.lazyPut).

**Non-functional**
- No flash of wrong UI, no crash from missing service.
- Preserve auth splash redirect logic.

## Architecture

```
main() {
  WidgetsFlutterBinding.ensureInitialized();
  // CRITICAL PATH (sequential)
  await dotenv.load;
  await Firebase.initializeApp;
  await Hive.initFlutter;
  await authStorage.init();
  await storageService.init();
  await languageContext.init();
  await apiClient.init(authStorage);
  // First frame can render

  runApp(FloweringApp);

  // DEFERRED — scheduled post-first-frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initDeferredServices();
  });
}

Future<void> _initDeferredServices() async {
  // Connectivity (unblocks offline banner)
  await Get.put(ConnectivityService()).init();
  // Cache invalidator
  await Get.put(CacheInvalidatorService()).init();
  // Onboarding progress (needed on splash route only)
  await Get.put(OnboardingProgressService()).init();
  // Audio stack (needed on chat screen)
  Get.put<TtsProviderContract>(FlutterTtsProvider());
  Get.put<SttProviderContract>(SpeechToTextProvider());
  Get.put<AudioRecorderProviderContract>(RecordAudioProvider());
  await Get.put(TtsService()).init();
  await Get.put(VoiceInputService()).init();
  // Subscription stack (not needed before login completes)
  await Get.put(RevenueCatService()).init();
  await Get.put(SubscriptionService()).init();
  Get.put(TranslationService(), permanent: true);
}
```

⚠️ This breaks `OnboardingProgressService` dependency at splash screen. Splash uses it via `_cachedToken` check — needs measuring. Options:
1. Keep `OnboardingProgressService` in critical path (still fast — only reads one Hive box).
2. Move splash off direct service use to a lighter-weight route decision helper.

**Chosen**: keep OnboardingProgressService in critical path (Option 1 — minimal defer gain is not worth complexity).

## Related Code Files

**Modify**
- `lib/main.dart`
- `lib/app/global-dependency-injection-bindings.dart` — split `initializeServices()` into `initializeCriticalServices()` and `initializeDeferredServices()`

## Implementation Steps

1. In `global-dependency-injection-bindings.dart`, create `initializeCriticalServices()` with: AuthStorage, StorageService, LanguageContext, CacheInvalidator (depends on LanguageContext), OnboardingProgressService, ApiClient.
2. Create `initializeDeferredServices()` with: Connectivity, audio providers, TtsService, VoiceInputService, RevenueCatService, SubscriptionService, TranslationService.
3. In `main.dart`: await `initializeCriticalServices()` before `runApp`.
4. In `FloweringApp` root widget (`flowering-app-widget-with-getx.dart`), add `addPostFrameCallback` that kicks off `initializeDeferredServices()`.
5. For screens that access deferred services (chat, paywall, etc.), the existing `Get.lazyPut` + `fenix` bindings handle the case where init hasn't completed — verify no race.
6. Add a `_deferredInitCompleted = Completer<void>()` to force-await if a screen opens before init finishes (rare: user opens chat in <100ms).
7. Smoke-test: cold start → splash → home. Open chat → TTS works. Open paywall → offerings load.

## Todo List
- [ ] Split `initializeServices()` into critical/deferred
- [ ] Update `main.dart` to await only critical path
- [ ] Add `addPostFrameCallback` in root app widget to run deferred init
- [ ] Guard deferred-service usage with await on `_deferredInitCompleted`
- [ ] Add timing prints (debug only) around each init block to measure gains
- [ ] Cold-start timing comparison (before/after on same device)
- [ ] Manual smoke: chat screen works (TTS + voice input)
- [ ] Manual smoke: paywall screen works (offerings load)

## Success Criteria
- First frame paints noticeably earlier (subjective + optional print-timing).
- No crash from missing service on any screen.
- `flutter test` green.

## Risk Assessment
- **Risk**: race where a user navigates to chat before audio services init. Mitigation: `_deferredInitCompleted` completer; chat binding awaits it.
- **Risk**: subscription check happens before `SubscriptionService` inits → user appears free. Mitigation: `isPremium` defaults to `free()` model which is the safe default.
- **Risk**: deferred init eats background CPU right when user interacts with splash. Real but acceptable; alternative (defer to Future.delayed(2s)) risks bad UX on fast launch.

## Security Considerations
- No tokens or secrets deferred — auth path remains synchronous on critical path.

## Next Steps
- Phase 06 adds network cache/debouncing — benefits from stable service init.
