# Code Review — Onboarding / Home / Profile / Vocabulary / Lessons

**Summary:** Onboarding resume flow is solid (progress service well-designed, awaited writes, idempotent init/migration). Several translation-key bugs will ship as `literal key strings` in UI. A handful of BaseScreen/AppText/AppButton violations. Cold-resume edge cases around `refetchProfileIfNeeded` and `isClosed` guards are minor. No security or data-leak issues.

---

## Critical (must fix)

### C1. Missing translation keys — UI will show raw keys
Used in code, **not defined** in either `english-translations-en-us.dart` or `vietnamese-translations-vi-vn.dart`:
- `onboarding_welcome_headline` — `lib/features/onboarding/views/onboarding-welcome-screen.dart:47`
- `welcome_back_headline` — `lib/features/onboarding/views/welcome-back-screen.dart:46`
- `log_in` — `lib/features/onboarding/views/onboarding-welcome-screen.dart:103`

**Fix:** Add all three keys to BOTH `lib/l10n/english-translations-en-us.dart` and `lib/l10n/vietnamese-translations-vi-vn.dart`. These are top-of-funnel screens — broken copy is user-facing on first launch.

### C2. `.tr` fallthrough shows raw key string
GetX default: missing key returns the key string itself. No assert in debug to catch it. Add a grep-based pre-commit or temp test that loads both locale maps and asserts every `.tr` token used in `lib/features/onboarding/**` exists in both.

### C3. Hardcoded error string bypasses i18n
`lib/features/profile/controllers/profile-controller.dart:44` — `errorMessage.value = 'Something went wrong'`. Also `lib/core/base/base_controller.dart:67` + `lib/core/network/api_exceptions.dart:142,157`. Shipping English literals to VI users.
**Fix:** replace with `'unknown_error'.tr` (already defined in both locales).

---

## Important

### I1. Raw `Text`/`ElevatedButton`/`TextField`/`OutlinedButton` violate base-widget rule
CLAUDE.md mandates `AppText`/`AppButton`/`AppTextField`.
- `lib/features/onboarding/widgets/scenario_card.dart:218` — `Text(_iconEmoji(), …)` (OK justification: single emoji char; still prefer `AppText` for consistency)
- `lib/features/onboarding/views/onboarding-welcome-screen.dart:65-87` — raw `ElevatedButton`, should use `AppButton`
- `lib/features/onboarding/views/welcome-back-screen.dart:64-85` — raw `ElevatedButton`, should use `AppButton`
- `lib/features/profile/views/profile-screen.dart:94` — raw `OutlinedButton.icon`, should use `AppButton` (destructive variant)
- `lib/features/vocabulary/views/vocabulary-screen.dart:50` — raw `TextField`, should use `AppTextField` (native language screen uses `AppTextField` correctly — inconsistent)

### I2. Splash hardcoded 3s delay blocks boot even on instant token validation
`lib/features/onboarding/controllers/splash_controller.dart:37-40` uses `Future.wait([Future.delayed(3s), _validateToken()])`. Always waits a minimum of 3 seconds. Poor UX especially for returning users.
**Fix:** Use a min-hold pattern (e.g., `Future.wait([minDelay(600ms), _validateToken()])`) or show splash until the first real frame is ready.

### I3. `refetchProfileIfNeeded` fires wasted API call on cold-resume non-scenario paths
`onboarding_controller.dart:69` runs `Future.microtask(refetchProfileIfNeeded)` at controller init. Because `OnboardingController` is `permanent: true`, onInit runs ONCE when any onboarding screen first binds. If user cold-resumes into `AppRoutes.chat` (not scenario-gift), the microtask still executes but short-circuits via the `profileComplete` check — OK. But simultaneously `_hydrateFromProgress().then((_) => loadLanguages())` triggers an unnecessary `/languages` network call when we're already past language selection.
**Fix:** gate `loadLanguages()` on the current route (only call on native/learning language screens) or make it lazy on screen `onInit`.

### I4. `refetchProfileIfNeeded` — unbounded retries on failure; on-screen loading stuck
`onboarding_controller.dart:172-194`. Catches all errors silently, sets `isRefetchingProfile = false`. UX result: empty scenarios grid with `scenario_empty` copy, no retry button. If network is flaky, user sees empty grid forever.
**Fix:** On failure, show retry CTA on `_ScenarioGrid` empty path, or bubble error to `errorMessage` and render a retry tile.

### I5. `_clearSession()` in chat — unawaited progress write
`lib/features/chat/controllers/ai_chat_controller_session.dart:162-167` — `_progressSvc.clearChat()` is async but not awaited inside `_clearSession()` (a sync function). If user navigates away immediately after a 404/400 error, `clearChat` may not have completed — cold-resume still sees stale conversation id and 404s again (self-recovering, but adds a cycle).
**Fix:** make `_clearSession()` async and `await` the clearChat; or document the self-healing retry as acceptable.

### I6. `BaseController.isLoading`/`errorMessage` swap — no `isClosed` guard on long await
`OnboardingController.refetchProfileIfNeeded` writes `isRefetchingProfile.value` after `await api.post(...)`. Permanent controller → safe. But `ProfileController._performLogout()` (`profile-controller.dart:34-48`) awaits `_authStorage.clearTokens`, `_storageService.clearAll`, `FirebaseAuth.instance.signOut`, THEN navigates. During this window the user cannot cancel. Acceptable — but wrap with `try/finally` for `isLoading.value = false` (already present). Consider `Get.isRegistered<ProfileController>()` before final setState.

### I7. `FirebaseAuth.instance` used without null-check
`profile-controller.dart:41` — if Firebase isn't initialized on logout path (unlikely but possible in dev builds without firebase), this throws. Existing fallback logic `clearAll/clearTokens` runs first (good — local state cleared before throw), but error is caught generically and shown as "Something went wrong" (I1 above).

### I8. `LanguageSelectionLayout` — `separatorBuilder: (_, _) =>` + `?bottomWidget` require Dart 3.7+
`lib/features/onboarding/widgets/language_selection_layout.dart:85,97`. SDK constraint `^3.10.3` satisfies this, but the `?bottomWidget` null-aware collection element may surprise readers. Add a short comment documenting the syntax.

---

## Minor

### M1. `scenario_card.dart` at 225 lines — just over 200-line cap
CLAUDE.md rule: split files >200 LoC. Candidates to extract:
- `_CardBody` → `scenario_card_body.dart`
- `_LevelDots` → `scenario_level_dots.dart`
- `_PlaceholderBg` + emoji/color mapping → `scenario_placeholder.dart`

### M2. `onboarding_controller.dart` at 202 lines — right at cap
Consider extracting `_hydrateFromProgress` + `refetchProfileIfNeeded` into `onboarding_controller_resume.dart` (part file) mirroring the `ai_chat_controller_*.dart` split pattern.

### M3. `VocabularyScreen` + `ReadScreen` — use stateless Get.find instead of binding-controller rebuild
`vocabulary-screen.dart:18` and `read-screen.dart:17` use `Get.find<…>()` inside `build()`. Works because `fenix:true` in `main-shell-binding.dart`, but rebuilds won't pick up newly-registered controllers. Low risk.

### M4. `ReadScreen._buildBody` returns `SizedBox.shrink()` for every item
`read-screen.dart:77-81` — dead `ListView.builder` that renders nothing when `sections` has content. Placeholder; flag for implementation or gate behind a feature flag.

### M5. `VocabularyController`/`ReadController` — no real data source
Stub controllers with empty observable lists. Fine as scaffolding but add a `TODO` comment referencing the ticket/issue owner.

### M6. `onboarding_language_service.dart` has zero cache
Every language screen entry refetches. In a 3G environment the skeleton shows for seconds. Consider persisting to `preferences` box (tiny payload, 2–4 KB).

### M7. `_LevelDots` in scenario_card — `AppText('scenario_level'.tr)` uses `caption` variant with no explicit color against variable-opacity background
Gradient goes from transparent to 0xDDFFFFFF (near-white). Default text color on the upper half of the card body overlay will render on mid-opacity background — could be low-contrast.

### M8. `OnboardingProgress.fromJson` returns empty on unknown `_v`
`onboarding_progress_model.dart:26` — if schema version changes, user silently restarts onboarding. Acceptable now (v1 only); note in roadmap that v2 must write migration.

### M9. `OnboardingProgressService._write` is not atomic across process kill mid-encode
`jsonEncode → setPreference` is one atomic Hive put — OK. No action needed, just verifying.

### M10. `profile-screen.dart` — hardcoded stat values `'0'`, `'0%'`
Line 71-73. Intentional until backend integration; add TODO.

---

## Adversarial findings

### A1. Force-quit mid-step
- Native→Learning: `selectNativeLanguage` awaits progress write BEFORE 50ms timer → **safe** (write persists).
- Learning→Chat: `_langCtx.setActive` + `_progress.setLearningLang` both awaited before timer → **safe**.
- Chat `setProfileComplete(true)` is awaited before `Get.offNamed(scenarioGift)` → **safe**.
- **Gap:** `setChatConversationId` awaited at `ai_chat_controller_session.dart:114`, but if backend returns success and app dies between `_conversationId = session.conversationId` (line 113) and the await at 114 finishing, state on next boot is inconsistent — backend has session, client forgot it. Cold resume will create a duplicate session. Low probability (sub-millisecond window).

### A2. Low-memory kill of OnboardingController
Permanent controller → wiped on process kill. On restart, splash routes via `computeOnboardingResumeTarget(progress)`. Progress in Hive is the source of truth — **safe**.

### A3. Backend returns partial progress (e.g. `conversation_id: null`)
`_createSession` at `ai_chat_controller_session.dart:114` — `_conversationId!` bang-assert on possibly-null response. If backend glitches and returns null `conversation_id`, app **crashes** with null-check operator exception. **Fix:** guard with `if (_conversationId == null) { errorMessage.value = 'chat_session_error'.tr; return; }`.

### A4. User changes device language mid-onboarding
GetX `.tr` is resolved once per build. Non-Obx screens (welcome-back, value screens 1-3) won't rebuild on locale change. Low risk — users rarely change system language mid-flow. Not a blocker.

### A5. Rotation during step
No state loss — everything is in GetX rx/permanent controller. IndexedStack in `MainShellScreen` preserves state across tabs. OK.

### A6. Backend snake_case mismatch
Models use dual fallback (`snake_case ?? camelCase`) — `OnboardingLanguage`, `Scenario`, `OnboardingSession`, `OnboardingProfile`. Robust.

---

## Positive observations

1. `OnboardingProgressService` is tight — unified JSON blob, schema version guard, legacy migration idempotent, awaited writes, corruption-safe reads.
2. `computeOnboardingResumeTarget` pure function — exported and trivially unit-testable. 
3. Dual snake_case/camelCase parsing across all onboarding models — defensive.
4. `ever()` worker disposed in `onClose()` (line 198). Timer cancelled. Good controller hygiene.
5. Debug prints all guarded by `kDebugMode` — no log noise or PII in release.
6. `_hydrateFromProgress` **awaits** `_langCtx.setActive` before subsequent API calls — correct ordering so interceptor has the code.

---

## Metrics
- Lines reviewed: ~2,800 (feature scope)
- Files with >200 LoC: 2 (`scenario_card.dart` 225, `onboarding_controller.dart` 202)
- Raw-widget violations: 5 files
- Missing translation keys: 3 (`onboarding_welcome_headline`, `welcome_back_headline`, `log_in`)
- Hardcoded error strings: 4 locations
- Unbounded/ungated API calls: 1 (`loadLanguages` on cold-resume to non-language routes)

---

## Unresolved questions
1. Should `OnboardingController` still run `loadLanguages()` when resume target is scenario-gift or chat?
2. `refetchProfileIfNeeded` retries: acceptable silent failure, or need user-facing retry affordance (I4)?
3. Is the 3s splash minimum intentional (brand reveal) or vestigial (I2)?
4. Missing keys `onboarding_welcome_headline` / `welcome_back_headline` — is the rendered fallback key string intentional during dev, or genuinely unshipped?
5. `A3` null `conversation_id` — does backend guarantee non-null on 200? If yes, document and keep bang-assert.
