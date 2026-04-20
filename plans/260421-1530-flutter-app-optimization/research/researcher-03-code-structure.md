# Researcher 03 — Code Structure Report

Scope: files >200 lines, duplicated patterns, missed use of shared widgets.

## Files violating 200-line rule (descending)

| Lines | File | Split strategy |
|---|---|---|
| 538 | `features/chat/controllers/ai_chat_controller.dart` | Extract: session (bootstrap/rehydrate/create), voice/TTS bridge, grammar, translation, message helpers |
| 338 | `shared/widgets/word-translation-sheet.dart` | Extract: header, loading/error states, translation/definition/examples sections |
| 299 | `core/services/storage_service.dart` | Extract: lessons-cache, chat-cache, preferences, per-language boxes into mixins or sub-services |
| 282 | `core/services/audio_service.dart` | Likely legacy (superseded by `audio/` package). Candidate for deletion — see "Dead code" below |
| 274 | `features/auth/controllers/auth_controller.dart` | Extract: email flow, social flow (Google/Apple), form validators |
| 257 | `app/routes/app-page-definitions-with-transitions.dart` | Split by feature area: onboarding-routes.dart, auth-routes.dart, main-routes.dart |
| 254 | `features/chat/widgets/language-picker-sheet.dart` | Extract `_PickerRow` (already private) into its own file; sheet is otherwise fine |
| 230 | `core/network/api_client.dart` | Extract SSE stream handling into `api-sse-client.dart`; keep HTTP methods in main file |
| 226 | `features/chat/views/ai_chat_screen.dart` | Extract `_ChatList`, `_ErrorBanner`, `_VoiceInputOverlay` into widgets/ |
| 222 | `features/onboarding/widgets/scenario_card.dart` | Extract `_CardBody`, `_LearnedBadge`, `_LevelDots`, `_PlaceholderBg` |
| 219 | `features/auth/views/login_email_screen.dart` | Extract: social auth section, email form, submit button |
| 208 | `core/network/api_exceptions.dart` | Keep — exception types are cohesive. Accept minor overage OR split mapping/utilities into separate file |

## Duplicated patterns

### D1. Scroll-to-load-more boilerplate repeated 2x+
- `flowering_tab.dart:28-33`, `for_you_tab.dart:28-33` — identical `_onScroll` + `NotificationListener` wiring.
- Extract to `shared/widgets/infinite_scroll_list.dart` (params: controller, loadMore, threshold).

### D2. Empty/Error state widget duplicated
- `_EmptyOrError` in `flowering_tab.dart:73-113` and `for_you_tab.dart:73-113` — same shape.
- Extract to `shared/widgets/empty_or_error_view.dart`.

### D3. Feed card placeholders duplicate image fallback
- `scenario_card.dart:42-48` and `feed_scenario_card.dart:69-90` — both have `Image.network` + `errorBuilder` + placeholder. Merge into shared `CachedScenarioImage` widget (also fixes caching issue per Researcher 01 H3).

### D4. `_showLoadingOverlay` / `_hideLoadingOverlay` in `auth_controller.dart:226-237`
- Pattern appears only there, but could become shared `LoadingOverlayHelper` if reused. Skip for now (YAGNI).

### D5. Hive preference get/set pattern repeated across services
- `TtsService._autoPlayKey / _rateKey / _pitchKey` — 3 identical accessors. Could macro into typed preference bag but not worth DRY churn for 3 fields.

## Missing use of shared widgets

### M1. Raw `Text` in cards/lists instead of `AppText`
- `feed_scenario_card.dart:106-117` — hard-coded `Text(item.title, ...)` with full `TextStyle` constructor. Violates project rule "always AppText". Already has the font family/size in AppText.
  - Fix: replace with `AppText(item.title, variant: AppTextVariant.bodyMedium, fontWeight: FontWeight.w600, ...)`.

### M2. Raw `ElevatedButton` / `TextButton` usage
- `paywall-screen.dart:157-164` `ElevatedButton` in empty state retry.
- `for_you_tab.dart:100-108`, `flowering_tab.dart:105-113` `TextButton` in retry.
- `paywall-bottom-sheet.dart`, `paywall-bottom-actions-widget.dart` — `ElevatedButton` and `TextButton`.
- `onboarding-welcome-screen.dart`, `welcome-back-screen.dart` — `ElevatedButton`.
  - Fix: replace with `AppButton` where possible. Accept exceptions for native widgets (`SignInWithAppleButton`, `OutlinedButton` with icon — `AppButton` doesn't support icon yet).

### M3. Raw `Text` in hero sections / placeholders
- `paywall-screen.dart:118-130`, `paywall-screen.dart:151-154` — raw `Text` with manual `TextStyle`.
- Fix: switch to `AppText`.

### M4. Raw `TextField` in vocabulary search
- `vocabulary-screen.dart:50-71` — uses `TextField` directly instead of `AppTextField`. But the search styling is custom (icon prefix, pill fill). Either extend `AppTextField` to support this variant OR leave as documented exception.

### M5. `_PlaceholderScreen` hard-coded `Text` + `ElevatedButton`
- `app-page-definitions-with-transitions.dart:40-47`. Placeholder only, low priority — fix only if/when placeholders become real screens.

## Dead / suspect code

### X1. `core/services/audio_service.dart` appears unused
- Searched imports: only referenced by itself. The real audio stack is `core/services/audio/` (tts-service, voice-input-service, providers).
- Verify with cross-repo grep then DELETE (saves 282 lines of noise and real leak-adjacent code).

### X2. `_PlaceholderScreen` still routed for `register/lessons/profile/settings` 
- Placeholder routes exist while real screens exist in features (e.g., profile is rendered in main shell, not via route). Clean up unused placeholder routes.

## Shared-widget gaps to create
- `InfiniteScrollList<T>` — wraps ListView.builder/GridView.builder with scroll-to-bottom loadMore
- `EmptyOrErrorView` — icon + message + retry button
- `CachedScenarioImage` — CachedNetworkImage + placeholder, used by all scenario cards

## Unresolved questions
- Confirm `audio_service.dart` truly unused (grep shows zero imports — strong signal but verify in CI after removal).
- Should `AppButton` be extended with `icon` slot to cover 90% of OutlinedButton usages?
