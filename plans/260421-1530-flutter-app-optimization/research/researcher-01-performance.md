# Researcher 01 — Performance Report

Scope: launch time, rebuild amplification (Obx), Hive I/O, image caching, list rendering.

## Findings (ranked by impact)

### H1. Sync Hive I/O on every TTS call + token read
- `TtsService.autoPlayEnabled` reads from Hive (`getPreference`) on every `_addAiMessage` in chat. Cheap per call but happens in chat hot path. Cache in local bool at service init.
- `AuthInterceptor.onRequest` calls `_authStorage.getAccessToken()` on EVERY request (async read from flutter_secure_storage). `AuthStorage` already has `_cachedToken` for sync `isLoggedIn` — reuse it for the interceptor (fall back to disk on miss).
  - File: `lib/core/network/auth_interceptor.dart:27`
  - Expected win: removes one keychain round-trip per request (~5-20ms each on iOS).

### H2. Obx over-scoping inflates rebuilds
- `ai_chat_screen.dart:163` wraps the whole `ListView.separated` in `Obx` that reads `messages` and `isTyping`. Every typing-indicator flip rebuilds the entire list (delegate + separator + itemBuilder closures).
  - Fix: split into (a) `Obx` only for `isTyping` (footer item count), (b) use `GetBuilder<AiChatController>` + manual `update()` for messages, OR separate the typing bubble into its own `Obx` widget after the list.
- `login_email_screen.dart:143-184` has Obx wrapping full 40-line submit button subtree. Fine but `Obx(() => isLoading ? spinner : text)` is the typical mistake — acceptable here because scope is button only.
- Multiple screens (`scenarios/views/for_you_tab.dart:38`, `flowering_tab.dart:39`) wrap the entire list+refresh+empty state in one giant `Obx` — any state change rebuilds the `ListView.builder` wrapper.
  - Fix: move Obx inside itemBuilder for item-level reactivity, OR use `GetX<Controller>()` with specific id.

### H3. `Image.network` without caching
- `scenario_card.dart:42` and `feed_scenario_card.dart:72` use `Image.network` directly. No disk cache, no memory cache beyond Flutter's default ImageCache. Feed scroll re-fetches images on back-navigation.
  - Fix: replace with `CachedNetworkImage` (already in pubspec — `language-picker-sheet.dart` uses it).
  - Expected win: cuts bandwidth/CPU for feed scroll by ~70%, eliminates flicker on return.

### H4. List controllers pass `Obx` + `NotificationListener` double
- `flowering_tab.dart`/`for_you_tab.dart` wrap `RefreshIndicator` inside `Obx` — when `isLoading` flips, even though the list view itself doesn't need rebuild, the entire tree below is rebuilt (including `NotificationListener` and `GridView.builder`).
  - Fix: move `Obx` inside the `ListView.builder` itemBuilder count (`itemCount: controller.items.length + (loading ? 1 : 0)`) or extract loading indicator to a sibling `Obx` above the list.

### H5. App startup — everything eager in main()
- `main.dart` awaits: Firebase init + Hive init + all services sequentially in `initializeServices()`.
- `RevenueCatService.init()` makes a network call on startup (fetching offerings). `SubscriptionService.init()` → backend fetch for subscription.
- `TtsService.init()`, `VoiceInputService.init()` — audio stack loads flutter_tts + speech_to_text plugins.
- Measured impact (no profiler, static): plausible 800-1500ms startup delay. Splash likely masks it.
  - Fix: defer non-critical services until after first frame. Required immediately: AuthStorage, StorageService, LanguageContext, ApiClient. Defer: RevenueCat, Subscription, TTS, VoiceInput (already lazy on first mic tap), TranslationService.

### H6. `assignAll`/`refresh()` on full message list
- `ai_chat_controller.dart` uses `messages.refresh()` after mutating a single message (line 283, 304, 398, 414, 453). Triggers all Obx listeners. For a 50-message transcript this rebuilds all 50 bubbles.
  - Fix: use `GetBuilder` + `update(['message-$id'])` for targeted rebuilds, OR migrate message ops to individual `.obs` fields inside the model and wrap each bubble in its own Obx reading its own observable.

### H7. `ChatMessage.refresh()` misuse for async toggles
- `toggleTranslation()` calls `messages.refresh()` for a single message mutation. Same fix path as H6.

### H8. `Image.asset` ok — assets bundled correctly, no fix needed

## Secondary findings (low impact)

- `vocabulary-screen.dart:98` correctly uses `ListView.builder` but wraps in `Obx`. Fine since vocab list is typically <100 items.
- `language-picker-sheet.dart:130` uses `ListView.separated(shrinkWrap: true)` — OK for bottom sheets, small lists.
- `paywall-screen.dart:65` uses `List.generate(...)` in a `Column` instead of `ListView.builder`. Fine for ≤5 plans.
- Route transitions standardized to `250ms` — already lean.

## Unresolved questions
- No empirical launch-time measurement available — assumes standard startup overhead. Recommend adding timing print in `initializeServices` to validate H5.
- Hive key-scan for chat messages (`getChatMessages`) is O(N) on every call. If `chat_cache` grows toward 10MB cap, this becomes slow. Not yet observed but worth index.
