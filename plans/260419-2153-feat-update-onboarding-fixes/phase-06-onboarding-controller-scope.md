# Phase 06 — C5 OnboardingController Route-Scoped Lifecycle

## Context Links

- Report: `plans/reports/code-reviewer-260419-2022-feat-update-onboarding-5-commits.md` (C5)
- Report: `plans/reports/code-reviewer-260419-2021-adversarial-feat-update-onboarding.md` (I2 cross-user leak)
- Code: `lib/features/onboarding/bindings/onboarding_binding.dart:23-25`
- Existing: `lib/features/onboarding/services/onboarding_progress_service.dart`

## Overview

- Priority: Critical
- Status: pending
- `permanent: true` makes controller outlive onboarding session → leaks `ever()` workers, stale state across users (I2), ghost listeners.

## Key Insights

- Persistent state (resume progress, draft answers) belongs in `OnboardingProgressService` (already exists).
- Controller holds transient UI state only — lifecycle matches route.
- Splash cold-resume path must read progress from service, not controller.

## Requirements

Functional
- Controller disposed when onboarding route popped.
- `OnboardingProgressService` survives; holds fields previously on controller (e.g. current step, pending selections needed for resume).
- Splash / cold-resume reads progress from service.
- All `ever()` / stream subscriptions in controller cancelled in `onClose()`.

Non-functional
- No regression in resume-after-background scenario.
- No duplicate ever() workers on re-entry (Get.find vs Get.put).

## Architecture

```
Before:                           After:
OnboardingBinding.put(            OnboardingBinding.put(
  OnboardingController,             OnboardingController,
  permanent: true)                  // route-scoped, default)
                                  OnboardingProgressService registered
                                    at app bootstrap (permanent in main.dart)

Controller (transient) ─ reads/writes ─► ProgressService (persistent)
Splash/Resume ──────────── reads ──────► ProgressService
```

## Related Code Files

Modify
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/features/onboarding/bindings/onboarding_binding.dart`
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/features/onboarding/controllers/onboarding_controller.dart`
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/features/onboarding/services/onboarding_progress_service.dart`
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/features/onboarding/bindings/splash_binding.dart` (if it reads controller state)
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/app/bindings/global-dependency-injection-bindings.dart` (register progress service as permanent)

Create
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/test/features/onboarding/onboarding_controller_lifecycle_test.dart`

## Implementation Steps

1. Identify state on `OnboardingController` that must survive route pop (current step index, pending payload, resume token). Move each to `OnboardingProgressService` as `Rx` or plain fields.
2. Remove `permanent: true` from `OnboardingBinding.put(OnboardingController(...))`.
3. Register `OnboardingProgressService` as permanent in global bindings if not already.
4. In controller `onInit()` seed transient Rx from service values.
5. In controller `onClose()`: cancel every `ever()`/`debounce()` worker; close any `StreamSubscription`; dispose `TextEditingController`s.
6. Update splash / cold-resume code to read `OnboardingProgressService` directly (not via `Get.find<OnboardingController>()`).
7. Verify `_finalizeOnboarding` callers still work (coordinate with Phase 2 snake_case payload).

## Todo List

- [ ] Inventory controller fields → decide transient vs persistent
- [ ] Migrate persistent fields to `OnboardingProgressService`
- [ ] Remove `permanent: true`
- [ ] Audit `onClose()` cancels all workers/subs
- [ ] Splash/cold-resume reads service
- [ ] Unit test: controller disposed on route pop
- [ ] Unit test: workers cancelled (no callbacks fire post-dispose)
- [ ] Unit test: cold-resume reads progress from service
- [ ] Manual smoke: complete onboarding, re-enter flow fresh (no stale step)
- [ ] Manual smoke: user A logout → user B login → no A residue
- [ ] `flutter analyze` clean

## Success Criteria

- `Get.find<OnboardingController>()` throws after route pop (expected).
- No `ever()` callback fires after `onClose()` (verified via counter in test).
- Resume-after-background still restores user to correct step via service read.
- Cross-user test: logout clears ProgressService (audit logout flow).

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Missed field on controller causes resume regression | Med | High | Inventory step explicit; smoke test resume |
| Splash binding still references controller | Med | Med | Grep `Get.find<OnboardingController>`; migrate callers |
| Logout doesn't clear ProgressService | Med | High (I2 leak) | Add logout hook to reset service; test cross-user |
| Binding ordering: service must exist before controller | Low | Med | Register in global bindings; controller `Get.find`s it |

## Security Considerations

- Cross-user leak is security-adjacent — ensure logout explicitly clears `OnboardingProgressService` state (in-memory + any persisted progress keys).
- Audit any persisted progress key for PII.

## Next Steps / Dependencies

- Land after Phase 2 (payload casing) to avoid merge conflicts in finalize path.
- Independent of Phases 1, 3, 4, 5, 7.
