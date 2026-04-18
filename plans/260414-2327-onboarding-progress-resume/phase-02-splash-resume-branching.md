# Phase 02 — Splash Resume Branching

## Context Links
- Depends on: Phase 01 (`OnboardingProgressService` must exist)
- File: `lib/features/onboarding/controllers/splash_controller.dart`
- Routes: `lib/app/routes/app-route-constants.dart`

## Overview
- **Priority:** High
- **Status:** completed (2026-04-15)
- Extend `SplashController._checkAuthAndNavigate()` with a 3rd branch: read `OnboardingProgressService`, decide resume target if unauthenticated.

## Key Insights
- Current flow: `isValid` → home | `hasToken` → welcome-back | else → welcome.
- New flow inserts progress check in the `else` branch only.
- **Do NOT** change `welcome-back` behavior — expired-token users stay on existing path (they likely completed onboarding already).
- Resume to chat requires conversationId validation (not just presence) — delegated to `AiChatController`, splash just routes to chat screen.

## Requirements
**Functional**
- Compute resume target from progress map.
- Default to `onboardingWelcome` if progress empty or corrupt.
- Skip intro screens (user chose "only major checkpoints" — no intro tracking).

**Non-functional**
- Resume decision must be sync (no network calls in splash). Backend validation happens in chat controller on mount.

## Architecture

```
SplashController._checkAuthAndNavigate()
  │
  ├── auth.isValid            → AppRoutes.home
  ├── hasExpiredToken         → AppRoutes.onboardingWelcomeBack
  └── else ──────────────────→ _computeOnboardingResumeTarget()
                                │
                                ├── progress.profileComplete    → onboardingScenarioGift
                                ├── progress.chat != null       → chat
                                ├── progress.learningLang !=null→ chat (will start fresh)
                                ├── progress.nativeLang != null → onboardingLearningLanguage
                                └── empty                       → onboardingWelcome
```

## Related Code Files
**Modify:**
- `lib/features/onboarding/controllers/splash_controller.dart`
- `lib/features/onboarding/bindings/splash_binding.dart` (register `OnboardingProgressService` if not global)

**Read for context:**
- `lib/app/routes/app-route-constants.dart`

## Implementation Steps

1. **Inject** `OnboardingProgressService` into `SplashController`:
   ```dart
   final _progress = Get.find<OnboardingProgressService>();
   ```

2. **Add resume helper**:
   ```dart
   String _computeOnboardingResumeTarget() {
     final p = _progress.read();
     if (p.profileComplete) return AppRoutes.onboardingScenarioGift;
     if (p.chat != null) return AppRoutes.chat;
     if (p.learningLang != null) return AppRoutes.chat;
     if (p.nativeLang != null) return AppRoutes.onboardingLearningLanguage;
     return AppRoutes.onboardingWelcome;
   }
   ```

3. **Update** `_checkAuthAndNavigate()`:
   ```dart
   if (isValid) {
     Get.offAllNamed(AppRoutes.home);
   } else if (hasToken) {
     Get.offAllNamed(AppRoutes.onboardingWelcomeBack);
   } else {
     Get.offAllNamed(_computeOnboardingResumeTarget());
   }
   ```

4. **Handle scenario_gift resume edge case:**
   - `onboardingScenarioGift` screen requires scenarios data. On resume, controller detects missing `onboardingProfile` and re-calls `POST /onboarding/complete` with stored `conversationId`. (Wired in Phase 03.)

5. **Pre-existing controller state:** `OnboardingController.selectedNativeLanguage` / `selectedLearningLanguage` must be hydrated from progress on init so resume screens reflect prior selections. (Wired in Phase 03.)

6. **Compile check:** `flutter analyze lib/features/onboarding/controllers/splash_controller.dart`

## Todo List
- [x] Inject `OnboardingProgressService` into `SplashController`
- [x] Add `computeOnboardingResumeTarget()` (extracted to pure top-level function for testability)
- [x] Update `_checkAuthAndNavigate()` to call helper in unauth branch
- [x] Verify splash_binding registers the service (global DI — no per-screen binding needed)
- [x] Unit-test 5 resume scenarios (empty, native only, learning+chat, chat, complete)

## Success Criteria
- Each of the 5 resume states routes to correct screen.
- Unauthenticated fresh install still goes to `onboardingWelcome`.
- Authenticated user still goes directly to `home`.

## Risk Assessment
- **Risk:** Progress says `chat` but conversationId is dead → chat screen shows empty UI. **Mitigation:** Phase 03 adds validation in `AiChatController.onInit()` that clears chat and restarts session if server returns 404.
- **Risk:** Race between splash delay and progress read. **Mitigation:** Progress read is sync (in-memory); happens before the `Future.wait` delay completes.

## Security Considerations
- No auth check bypass — auth branch stays first priority.

## Next Steps
- Phase 03 hydrates controller state from progress + wires all checkpoint writes.
