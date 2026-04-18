---
type: brainstorm
date: 2026-04-14 23:27
slug: onboarding-progress-resume
branch: feat/update-onboarding
status: design-approved
---

# Onboarding Progress Resume — Design Summary

## Problem

Onboarding is multi-step + AI chat (longest step). If user drops out mid-flow, they currently restart from welcome screen. Need local persistence so user resumes at first incomplete checkpoint.

**Context:** Onboarding runs **pre-auth** (before login) → device-local storage only. No server sync.

## Flow Recap

```
splash → welcome (x3 intro) → native_lang → learning_lang → chat (AI) → scenario_gift → auth/home
```

Resumable checkpoints (user input only): `native_lang`, `learning_lang`, `chat`, `profile_complete`.
Intro screens (1-3) are NOT tracked — resume always re-shows intros if first two checkpoints empty.

## Decision — Final Shape

### Storage

- **Location:** existing `preferences` Hive box (`StorageService`).
- **Key:** `onboarding_progress`
- **Value:** JSON string of `Map<String, dynamic>`

### Data Model

```json
{
  "native_lang": { "code": "vi", "id": "uuid-or-null" },
  "learning_lang": { "code": "en", "id": "uuid-or-null" },
  "chat": { "conversation_id": "uuid" },
  "profile_complete": true,
  "updated_at": "2026-04-14T23:27:00Z"
}
```

- Generic map per user preference (no typed model).
- Each key only exists after that checkpoint is reached.
- No chat `turn_number` persisted — backend is source of truth.
- No scenarios cached — refetched on resume.

### Resume Algorithm (SplashController)

```
1. auth.isValid  → home
2. hasExpiredToken → welcome-back (existing branch)
3. else load onboarding_progress:
   a. null / empty                   → onboardingWelcome
   b. profile_complete == true       → scenario_gift (refetch scenarios from backend)
   c. chat.conversation_id present   → validate conversation via backend
                                       alive → chat (rehydrate messages)
                                       dead  → clear chat entry, go to chat fresh
   d. learning_lang set              → chat (fresh session)
   e. native_lang set                → learning_lang
```

### Write Points

| Screen | Write |
|---|---|
| `native_language_screen` (on select) | `progress['native_lang'] = {code, id}` |
| `learning_language_screen` (on select) | `progress['learning_lang'] = {code, id}` |
| `ai_chat_controller` (on session start) | `progress['chat'] = {conversation_id}` |
| `ai_chat_controller` (on `/onboarding/complete` success) | `progress['profile_complete'] = true` |

All writes go through a single `OnboardingProgressService` (thin wrapper on `StorageService.setPreference`).

### Clear Policy

**Never auto-clear.** Overwrites only. Progress persists across logout until app uninstall. Accepted trade-off.

## Approaches Considered

| Approach | Pros | Cons | Verdict |
|---|---|---|---|
| Generic map (chosen) | Flexible, no model churn, fits 3 checkpoints | No compile-time safety | ✅ Picked |
| Typed `OnboardingProgress` model | Type-safe, IDE autocomplete | Migration pain on field changes | ❌ |
| Ordered step list (true stack) | Supports non-linear flows | Over-engineered for linear flow | ❌ |

## Architecture

```
SplashController ──reads──┐
                          │
                          ▼
         OnboardingProgressService
                          │
                          ▼
            StorageService.preferences (Hive)
                          ▲
                          │
     ┌─── writes ──────────┼─────── writes ───┐
     │                                         │
NativeLanguage    LearningLanguage     AiChatController
  Screen             Screen           (session start + complete)
```

## Files to Touch

**Create:**
- `lib/features/onboarding/services/onboarding_progress_service.dart` — read/write wrapper
- `lib/features/onboarding/models/onboarding_progress_model.dart` — optional JSON parser helpers

**Modify:**
- `lib/features/onboarding/controllers/splash_controller.dart` — resume branching
- `lib/features/onboarding/controllers/onboarding_controller.dart` — write on language select
- `lib/features/chat/controllers/ai_chat_controller.dart` — write conversation_id + profile_complete
- `lib/features/onboarding/bindings/onboarding_binding.dart` / `splash_binding.dart` — register service
- `lib/app/global-dependency-injection-bindings.dart` — if service needs global scope

**Backend dependency (verify exists):**
- Endpoint to rehydrate chat messages for a given `conversation_id`
- Endpoint to refetch scenarios (or re-call `/onboarding/complete` idempotently)

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Shared device — user B inherits A's progress | Accepted. Add "Start over" escape hatch post-MVP if reported. |
| `conversation_id` expired server-side on resume | Validate on entry to chat step; clear + restart if dead. |
| Scenarios refetch endpoint doesn't exist | Unresolved — see open questions. |
| Chat message rehydration endpoint doesn't exist | Unresolved — see open questions. |
| Hive box corruption | `StorageService.init()` already recovers via `Hive.deleteFromDisk()` + retry. |
| Concurrent writes race | Onboarding is single-controller single-threaded; no lock needed. |

## Success Criteria

- User closes app on `learning_language_screen` → reopens → lands on `learning_language_screen`.
- User closes app mid-chat (turn 3 of 10) → reopens → lands on `chat` with previous messages visible and conversation continuing at turn 4 (assuming backend conversation alive).
- User closes app between `/onboarding/complete` return and `scenario_gift` → reopens → lands on `scenario_gift` with scenarios refetched.
- Logged-in user reopening app → still goes straight to `home` (existing path unchanged).

## Non-Goals (Out of Scope)

- Multi-user device support (single progress slot per install).
- Intro screen (1-3) checkpointing.
- Server-side sync of onboarding progress.
- Chat turn-by-turn local persistence (rehydrate from backend).

## Unresolved Questions

1. Does backend expose `GET /conversations/:id/messages` (or equivalent) for chat rehydration?
2. Is `POST /onboarding/complete` idempotent given same `conversation_id`, or do we need a separate `GET /onboarding/profile?conversation_id=...`?
3. Should we tombstone `onboarding_progress` with a schema version field for future migrations? (Leaning yes — one-line addition.)
