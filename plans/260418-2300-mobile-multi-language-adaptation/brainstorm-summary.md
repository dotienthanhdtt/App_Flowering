---
title: Mobile Multi-Language Adaptation — Brainstorm Summary
date: 2026-04-18
status: pending
backend_plan: ../../../be_flowering/plans/260418-2238-multi-language-content-architecture
target: app_flowering/flowering
---

# Mobile Multi-Language Adaptation — Brainstorm Summary

## Problem Statement

Backend (plan `260418-2238-multi-language-content-architecture`) partitions all learning content by target learning language. Mobile must adapt before backend hits production:

- Send `X-Learning-Language: <code>` on every content-scoped request
- Maintain single source of truth for active language across controller disposal
- Drop `targetLanguage` from AI chat body (header supersedes)
- Gracefully handle new 400/403 error codes
- Invalidate language-scoped caches on switch

Constraint: must work for both authenticated users (header + DB fallback) and anonymous onboarding (header only — no fallback).

---

## Codebase Findings (Scouted)

| Area | Current state | Relevance |
|---|---|---|
| `lib/core/network/api_client.dart` | Dio singleton, Retry → Auth → Logger interceptors | Insertion point for language interceptor |
| `lib/core/services/storage_service.dart` | Hive: `lessons_cache`, `chat_cache`, `preferences` boxes | `preferences` box used for persistence |
| `lib/features/onboarding/controllers/onboarding_controller.dart` | `selectedLearningLanguage.obs` (code), `selectedLearningLanguageId` | Currently the de-facto active language; must migrate to service |
| `lib/features/chat/controllers/ai_chat_controller.dart:159` | Sends `targetLanguage` in body from onboarding ctrl | Direct edit site |
| `lib/features/` | auth, chat, home, lessons, onboarding, profile, settings, subscription, vocabulary | `HomeLessonsController`/`ProgressController`/`VocabularyController` named in spec **do not exist** — spec's `.clear()` list is aspirational |
| Offline queue | Not found during scout | Offline-switch language-drift concern likely N/A (verify in plan phase) |

---

## Evaluated Approaches & Decisions

### 1. Source of Truth — Active Language
**Options considered:** LanguageContextService / extend StorageService / promote OnboardingController.
**Decision:** New **`LanguageContextService extends GetxService`**.
**Rationale:**
- Onboarding controller disposes post-onboarding; can't own long-lived state
- StorageService should stay domain-agnostic (no mixed concerns)
- Service exposes `activeCode: RxnString` + `activeId: RxnString`, persisted to Hive `preferences` box on every write
- Registered in global DI bindings, init order: after `StorageService`, before `ApiClient`

### 2. Cache Partitioning Strategy
**Options:** Flush on switch / keyed boxes per language / namespace keys.
**Decision:** **Flush affected boxes on switch.**
**Rationale:**
- Keyed boxes require Hive migration for existing installs — complexity not worth it
- Flush is simple; user already expects a brief loading state when switching
- Backend is authoritative; refetch is cheap

### 3. AI Chat Body `targetLanguage` Field
**Options:** Remove immediately / send both during transition.
**Decision:** **Remove immediately.**
**Rationale:**
- Backend prefers header over body; dual-send creates inconsistency risk
- Backend DB fallback still protects old app versions during rollout
- Cleaner code path — one less field to reason about

### 4. 403 "Language not enrolled" Recovery
**Options:** Auto-pick first enrolled / picker modal / hard route to onboarding.
**Decision:** **Resync via `GET /languages/user`, auto-pick first enrolled, retry once.**
**Rationale:**
- Drift should be rare; aggressive UX (modal) punishes user for a server-side condition
- If no enrollments exist → only then route to onboarding (degenerate case)
- One-shot retry prevents infinite loop; failures surface as normal errors

### 5. Reactive State Propagation
**Options:** Reactive via `ever()` / event bus / explicit controller `.clear()` list.
**Decision:** **Reactive via `ever(activeCode, handler)` on LanguageContextService.**
**Rationale:**
- Spec's enumerated `.clear()` list (HomeLessonsController etc.) is brittle — those controllers don't even exist yet
- Any controller that cares subscribes via `ever()` in `onInit`; auto-cleanup on `onClose`
- Future features inherit automatically; no central switch handler to maintain
- Controllers self-clear their own RxList/RxMap state, not global

### 6. Anonymous Onboarding Ordering
**Options:** Block until persist / interceptor default fallback / block + retry UI.
**Decision:** **Block `/onboarding/start` until language persist completes.**
**Rationale:**
- Interceptor default ('en') silently gives wrong-language experience — bad UX
- Picker → `await service.setActive(code)` → navigate to chat — strict sequence
- `AiChatController._createSession()` asserts `service.activeCode.value != null`; if missing, route back to picker (defensive double-check)

### 7. Offline Queue
**Decision:** **Verify non-existence in planning phase; assume N/A.**
- If scout confirms no queue, interceptor's read-at-send-time is correct
- If queue found, revisit: capture header at enqueue time

---

## Final Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  LanguageContextService (GetxService, permanent)             │
│  - activeCode: RxnString   (persisted: preferences.active_language_code)
│  - activeId:   RxnString   (persisted: preferences.active_language_id)
│  - setActive(code, id) → persists + emits
│  - clear()             → wipe + emits null
│  - resyncFromServer()  → GET /languages/user, pick isActive or first
└────────────┬─────────────────────────────────────┬───────────┘
             │ read (interceptor)                 │ ever() subscribers
             ▼                                     ▼
┌─────────────────────────────┐     ┌───────────────────────────────┐
│ ActiveLanguageInterceptor   │     │ Feature controllers           │
│ (after Auth, before Logger) │     │ - clear own RxState on change │
│ - path allowlist check      │     │ - trigger refetch if visible  │
│ - sets X-Learning-Language  │     └───────────────────────────────┘
└─────────────────────────────┘
             │
             ▼
     ┌───────────────┐
     │   Dio / API   │
     └───────┬───────┘
             │ 403 Language not enrolled
             ▼
┌─────────────────────────────────────────────────────────────┐
│ 403 Recovery: resyncFromServer → retry original request 1x │
└─────────────────────────────────────────────────────────────┘
```

### Interceptor Path Rules
- **Attach header** (allowlist): `/lessons`, `/scenarios`, `/ai`, `/vocabulary`, `/onboarding`, `/progress`
- **Skip**: `/auth`, `/languages`, `/users/me`, `/subscription`, `/admin`
- Match by `path.startsWith(prefix)` — keep logic minimal

### Cache Flush on Switch
Triggered by `ever(activeCode)` in a dedicated `CacheInvalidator` service (registered in global bindings):
1. `storageService.clearBox('lessons_cache')`
2. `storageService.clearBox('lessons_access')` (LRU index)
3. `storageService.clearBox('chat_cache')` (authenticated chat only — not onboarding chat checkpoint)
4. Clear `preferences` keys: any `progress_*`, `attempt_*` entries
5. Preserve: `active_language_*`, `has_completed_login`, auth tokens

### Error Code → Translation Key Mapping
In `api_exceptions.dart`, map backend message patterns to enum:

```dart
enum LanguageContextError {
  headerMissing,      // → 'err_language_header_missing'
  unknownCode,        // → 'err_language_unknown'
  notEnrolled,        // → 'err_language_not_enrolled'
  activeRequired,     // → 'err_language_required'
}
```

Translation keys added to both l10n files. Never surface raw backend English to users.

---

## Implementation Risks & Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| `OnboardingController` state drift during migration | High | Single atomic PR: move `selectedLearningLanguage` read/write to `LanguageContextService`; onboarding ctrl delegates |
| Interceptor fires before service initialized (race) | High | Ensure service init **before** ApiClient.init in `global-dependency-injection-bindings.dart`; assert in interceptor with graceful log-and-skip |
| Existing users upgrade with stale cache (wrong-language lessons) | Medium | First-launch of new version: detect `active_language_code` missing, resync from server, flush all content caches once |
| Anonymous session ID cached from pre-cutover | Low | Backend backfills to 'en'; mobile: if session ID exists but no active code, resync or clear session |
| Forced update flow | Medium | Use existing `/users/min-version` or RevenueCat remote config; anonymous users see upgrade wall before onboarding |
| 403 retry loop | Medium | Single retry only; track retry count per-request via Dio Options.extra |
| TTS/STT still uses old `_targetLanguage` getter in chat | Low | Replace `_onboardingCtrl.selectedLearningLanguage.value` with `Get.find<LanguageContextService>().activeCode.value` |

---

## Answers to Unresolved Questions

1. **Hive migration for keyed-box rename** → N/A. Flush strategy avoids rename. One-time flush on first launch of new version for existing installs.
2. **Localization of error messages** → Map backend error codes/HTTP status to local translation keys; ignore backend English.
3. **Per-request header override** → Dio supports via `Options(headers: {...})`. Global interceptor sets default; per-request override wins. No action needed unless edge case emerges.
4. **Anonymous onboarding ordering** → Language picker BEFORE chat. Chat controller asserts active code present; routes back to picker if missing.

---

## Success Criteria

- [ ] Fresh install → picker → onboarding: every request carries header
- [ ] Authenticated language switch: home refetches, old in-memory state cleared via `ever()`
- [ ] Switch between 2 languages multiple times: progress preserved server-side per language
- [ ] 403 "not enrolled": single auto-resync + retry succeeds, user unaware
- [ ] AI chat body no longer contains `targetLanguage` field (verify via logger)
- [ ] Force-quit during switch: on relaunch, active language matches last successful `PATCH /languages/user/:id`
- [ ] Offline mode: header present on any requests that do fire (cache hits); graceful error on uncached

---

## Phase Outline (for plan agent)

1. **LanguageContextService** — new service, persistence, ever() hooks, init order
2. **ActiveLanguageInterceptor** — path allowlist, Dio registration, 403 retry
3. **OnboardingController migration** — delegate language state to service
4. **AI chat body cleanup** — drop `targetLanguage` field; update TTS/STT callers
5. **Cache invalidation** — CacheInvalidator service, ever() subscriber, first-launch-after-upgrade flush
6. **Error handling** — new exception mappings, translation keys (en + vi)
7. **403 recovery** — interceptor-level resync + retry (with retry-count guard)
8. **Language switch UX** — settings screen toggle, first-switch explanatory modal ("Progress in X saved separately")
9. **QA matrix** — execute spec's 8-point checklist + platform regression
10. **Version gating** — min-version check for anonymous users; coordinate with backend rollout

---

## Out of Scope (Deferred)

- Keyed Hive boxes per language (revisit if users complain about switch latency)
- Offline write queue (doesn't exist; revisit only if added later)
- Multi-language UI strings (separate concern — UI locale ≠ learning language)
- Parallel learning (user actively using 2 languages concurrently) — backend doesn't support it anyway

---

## Dependencies

- Backend `260418-2238` deployed to staging — required for E2E testing
- No new Flutter packages needed (Dio, Hive, GetX already present)
- Translation strings added to `lib/l10n/*` — coordinate with copy owner

---

## Unresolved (for plan phase)

- Exact list of controllers needing `ever()` hooks — enumerate during phase planning
- First-switch modal copy — coordinate with design
- Force-update threshold — coordinate with backend rollout timeline
- Verify: does `chat_cache` Hive box hold authenticated chat messages or onboarding chat? If onboarding-only, don't flush on language switch post-onboarding
