# Phase 03 — OnboardingController Migration

## Context Links

- Brainstorm: [brainstorm-summary.md](brainstorm-summary.md) §1 + §6
- Phase 01: service is SoT. Phase 02: interceptor reads service.
- Referenced files: `lib/features/onboarding/controllers/onboarding_controller.dart` (lines 14, 27, 66-67, 128-129), `lib/features/onboarding/services/onboarding_progress_service.dart`

## Overview

- **Priority:** P0 (unblocks phase 4 chat cleanup + phase 8 switch UX)
- **Status:** done
- **Description:** Move `selectedLearningLanguage` state ownership from `OnboardingController` to `LanguageContextService`. Controller retains its existing public API (callers untouched) but delegates reads/writes to the service. Persist-before-navigate enforced at `selectLearningLanguage`.

## Key Insights

- `OnboardingController` is a short-lived controller (disposed post-onboarding) that cannot own long-lived language state.
- The controller's existing `selectedLearningLanguage.obs` and `selectedLearningLanguageId` are read by chat controller (phase 4) and progress service — maintain API shape to avoid cascading refactors.
- `OnboardingProgressService` already persists a `learningLang` checkpoint; keep that path but ALSO write to `LanguageContextService` so interceptor sees the code.
- `selectLearningLanguage()` must `await service.setActive(code, id)` BEFORE navigating to chat (brainstorm §6).

## Requirements

**Functional:**
- `OnboardingController.selectedLearningLanguage` becomes a getter delegating to `Get.find<LanguageContextService>().activeCode.value ?? ''`.
- Assignments to `selectedLearningLanguage.value = ...` replaced with `await service.setActive(code, id)`.
- `selectedLearningLanguageId` (plain `String?` field) sourced from `service.activeId.value`.
- `_hydrateFromProgress()` still reads from progress service but ALSO calls `service.setActive(code, id)` when a checkpoint exists (guarantees service state matches resumed session).
- `selectLearningLanguage()` awaits service write before `Get.toNamed(AppRoutes.chat)`.

**Non-functional:**
- Zero changes to onboarding UI files — public API of controller preserved.
- File stays < 200 lines.

## Architecture

**Before:**
```
OnboardingController.selectedLearningLanguage.obs  ←─ source of truth
      │
      ├─► OnboardingProgressService (persist checkpoint)
      └─► AiChatController (read as body.targetLanguage)
```

**After:**
```
LanguageContextService.activeCode  ←─ source of truth
      │
      ▲── OnboardingController.selectLearningLanguage() writes via setActive()
      │    └─► also writes to OnboardingProgressService checkpoint
      │
      └─► ActiveLanguageInterceptor (reads for header)
      └─► AiChatController (reads via service for TTS/STT; body no longer carries field — phase 4)
```

## Related Code Files

**MODIFY:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/features/onboarding/controllers/onboarding_controller.dart`

**READ FOR CONTEXT (no edits):**
- `lib/features/onboarding/services/onboarding_progress_service.dart`
- `lib/features/onboarding/views/*.dart` (verify no direct `.value =` writes outside controller)

**CREATE:** none.  
**DELETE:** none.

## Implementation Steps

1. In `onboarding_controller.dart` top of class, replace:
   ```dart
   final selectedLearningLanguage = ''.obs;
   String? selectedLearningLanguageId;
   ```
   with a getter bridge that still exposes `.value`-compatible reads but routes through the service. Cleanest approach — keep an internal `RxString` mirror that is kept in sync via `ever()`:
   ```dart
   // Mirror of LanguageContextService.activeCode, preserved for existing
   // Obx() callers. Kept in sync via ever() below.
   final selectedLearningLanguage = ''.obs;
   String? selectedLearningLanguageId;

   LanguageContextService get _langCtx => Get.find<LanguageContextService>();
   Worker? _langCtxWorker;
   ```
   In `onInit()` after `super.onInit()`:
   ```dart
   selectedLearningLanguage.value = _langCtx.activeCode.value ?? '';
   selectedLearningLanguageId = _langCtx.activeId.value;
   _langCtxWorker = ever<String?>(_langCtx.activeCode, (c) {
     selectedLearningLanguage.value = c ?? '';
     selectedLearningLanguageId = _langCtx.activeId.value;
   });
   ```
   In `onClose()`:
   ```dart
   _langCtxWorker?.dispose();
   ```

2. Update `_hydrateFromProgress()` (lines 59-72) — after reading learningLang from progress, also sync service:
   ```dart
   if (p.learningLang != null) {
     // Fire-and-forget service sync; service emits back into our mirror via ever()
     _langCtx.setActive(p.learningLang!.code, p.learningLang!.id);
   }
   ```
   Keep the rest of hydration (native language, conversationId) unchanged.

3. Rewrite `selectLearningLanguage()` (lines 127-135) — persist-before-navigate:
   ```dart
   Future<void> selectLearningLanguage(String code, {String? id}) async {
     await _langCtx.setActive(code, id);                     // authoritative write
     await _progress.setLearningLang(code, id: id);          // checkpoint
     _navigationTimer?.cancel();
     _navigationTimer = Timer(const Duration(milliseconds: 50), () {
       Get.toNamed(AppRoutes.chat);
     });
   }
   ```
   Note: the service mirror updates `selectedLearningLanguage.obs` via ever() — no manual mirror write here.

4. `selectNativeLanguage()` stays as-is (native language is separate concern; not part of this feature).

5. Run `flutter analyze` — expect no errors. Run existing onboarding tests if any.

6. Manual test: fresh install → pick learning language → confirm `/onboarding/chat` request carries `X-Learning-Language` header.

## Todo List

- [ ] Add `LanguageContextService` import + `_langCtx` getter
- [ ] Seed mirror observable in `onInit()` + `ever()` subscription
- [ ] Dispose worker in `onClose()`
- [ ] `_hydrateFromProgress()` writes to service when resuming
- [ ] `selectLearningLanguage()` awaits `setActive()` before navigation
- [ ] `flutter analyze` clean
- [ ] Smoke test: picker → chat → interceptor logs show header

## Success Criteria

- [ ] No UI regression in onboarding flow.
- [ ] `selectedLearningLanguage.value` still readable by existing `Obx()` callers.
- [ ] On cold resume mid-onboarding, service is hydrated from progress checkpoint.
- [ ] `/onboarding/chat` request always carries header after picker step.

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Existing callers write `.value =` directly and bypass service | Medium | Grep for `selectedLearningLanguage.value =`; should only exist inside this controller. Document as internal-only. |
| `_hydrateFromProgress` service write is async but not awaited → race with first API call | Low | `setActive()` is fast (single Hive put); if needed, make `_hydrateFromProgress` async and await. Chat screen is behind picker anyway, so `selectLearningLanguage()` overrides. |
| Mirror observable drift if service updated outside controller (phase 8 settings) | Low | `ever()` keeps mirror in sync — this is exactly why the mirror + listener pattern is used. |

## Security Considerations

- None beyond phase 1.

## Next Steps

- Unblocks phase 4 (chat controller can drop body `targetLanguage` field safely).
- Unblocks phase 8 (settings toggle writes directly to service; controller observes via ever()).
