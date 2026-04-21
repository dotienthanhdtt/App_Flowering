---
title: "Onboarding Progress Resume"
created: 2026-04-14
updated: 2026-04-15
status: completed
branch: feat/update-onboarding
brainstorm: plans/reports/brainstorm-260414-2327-onboarding-progress-resume.md
blockedBy: []
blocks: []
---

# Onboarding Progress Resume

## Summary

Persist user onboarding progress locally so drop-outs resume at first incomplete checkpoint. Pre-auth, device-local, 3 checkpoints: `native_lang`, `learning_lang`, `chat`.

## Key Findings (from backend verification)

- `POST /onboarding/chat` — accepts existing `conversationId` to continue; backend keeps full history.
- `POST /onboarding/complete` — NOT idempotent; re-runs LLM extraction and generates new scenario UUIDs per call. **Must be made idempotent** (see `backend-requirements.md`).
- **No `GET /onboarding/conversations/:id/messages` endpoint.** **Must be added** (see `backend-requirements.md`).
- No server-side TTL on anonymous conversations; `findValidSession` only 404s on missing rows.
- Existing code persists `onboarding_conversation_id` as a standalone preference — subsumed by unified progress map.

## Backend Dependency

Phase 04 is BLOCKED until backend ships two changes per `backend-requirements.md`:
1. `GET /onboarding/conversations/:id/messages` (chat rehydration)
2. `POST /onboarding/complete` idempotent (stable scenario UUIDs, no duplicate LLM cost)

Phases 01–03 + 05 (non-chat parts) can ship independently of backend.

## Phases

| # | File | Focus | Status |
|---|------|-------|--------|
| 1 | [phase-01-progress-service-and-model.md](./phase-01-progress-service-and-model.md) | Create `OnboardingProgressService` + JSON model | completed |
| 2 | [phase-02-splash-resume-branching.md](./phase-02-splash-resume-branching.md) | Resume logic in `SplashController` | completed |
| 3 | [phase-03-checkpoint-writes.md](./phase-03-checkpoint-writes.md) | Wire writes in language screens + chat controller | completed |
| 4 | [phase-04-chat-message-rehydration.md](./phase-04-chat-message-rehydration.md) | Consume backend GET-messages + idempotent complete | completed |
| 5 | [phase-05-tests.md](./phase-05-tests.md) | Unit + integration tests | completed (unit; integration deferred) |

## Dependencies

Phase 1 → 2 → 3 → 4 → 5 (sequential; each phase depends on prior).

## Files

**Create:**
- `lib/features/onboarding/services/onboarding_progress_service.dart`
- `lib/features/onboarding/models/onboarding_progress_model.dart`

**Modify:**
- `lib/features/onboarding/controllers/splash_controller.dart`
- `lib/features/onboarding/controllers/onboarding_controller.dart`
- `lib/features/chat/controllers/ai_chat_controller.dart`
- `lib/features/onboarding/bindings/splash_binding.dart`
- `lib/features/onboarding/bindings/onboarding_binding.dart`
- `lib/app/global-dependency-injection-bindings.dart`

**Deprecate (migration):**
- Standalone `onboarding_conversation_id` preference → migrate into `onboarding_progress.chat.conversation_id`.

## Success Criteria

- User closes app on language screen → reopens → resumes on that screen with selection preserved.
- User closes app mid-chat → reopens → lands on chat with previous messages visible, conversation continues.
- User closes app between complete() and scenario_gift → reopens → scenario_gift with refetched scenarios.
- `flutter analyze` clean; unit tests pass; integration test for resume flow passes.

## Risks

- Shared device inheriting progress (accepted; no auto-clear).
- `POST /onboarding/complete` called twice → duplicate LLM cost; scenarios mismatch between sessions.
- Hive box corruption on progress (falls back to fresh onboarding — safe default).
