---
title: "Mobile Multi-Language Adaptation"
description: "Adapt Flutter app to backend multi-language content partition: X-Learning-Language header, active language service, cache flush, 403 recovery."
status: in_progress
priority: P0
effort: 18h
branch: feat/mobile-multi-language
tags: [mobile, multi-language, getx, dio, hive]
created: 2026-04-19
brainstorm: brainstorm-summary.md
blockedBy: []
blocks: []
---

# Mobile Multi-Language Adaptation

## Summary

Backend plan `260418-2238-multi-language-content-architecture` partitions lessons/exercises/scenarios/progress/AI by target learning language and requires an `X-Learning-Language` header on all content-scoped requests. Mobile adapts via a new `LanguageContextService` (single source of truth, Hive-persisted), a Dio interceptor with path allowlist, cache invalidation on switch, and 403 recovery via one-shot resync+retry.

Based on: [brainstorm-summary.md](brainstorm-summary.md). Backend contract: [mobile-adaptation-requirements.md](../../../be_flowering/plans/260418-2238-multi-language-content-architecture/mobile-adaptation-requirements.md).

## Phases

| # | Phase | Status | Effort | File |
|---|-------|--------|--------|------|
| 1 | LanguageContextService (GetxService + Hive persistence) | done | 2h | [phase-01](phase-01-language-context-service.md) |
| 2 | ActiveLanguageInterceptor (Dio, path allowlist) | done | 2h | [phase-02](phase-02-active-language-interceptor.md) |
| 3 | OnboardingController migration (delegate to service) | done | 2h | [phase-03](phase-03-onboarding-controller-migration.md) |
| 4 | AI chat body cleanup + TTS/STT getter update | done | 1h | [phase-04](phase-04-ai-chat-body-cleanup.md) |
| 5 | CacheInvalidator (ever() subscriber + first-launch flush) | done | 2h | [phase-05](phase-05-cache-invalidation.md) |
| 6 | Error handling + translation keys (en + vi) | done | 1h | [phase-06](phase-06-error-handling-and-translations.md) |
| 7 | 403 recovery (resync + retry once) | done | 2h | [phase-07](phase-07-403-recovery.md) |
| 8 | Language switch UX (settings toggle + first-switch modal) | pending | 3h | [phase-08](phase-08-language-switch-ux.md) |
| 9 | QA matrix + unit/integration tests | pending | 2h | [phase-09](phase-09-qa-testing.md) |
| 10 | Version gating (min-version + anonymous upgrade wall) | pending | 1h | [phase-10](phase-10-version-gating.md) |

## Key Dependencies

- Backend plan `260418-2238` deployed at least to staging (for E2E from phase 2 onward)
- Hive, Dio, GetX already present — no new packages
- Translation keys coordinated with copy owner (phase 6)
- First-switch modal copy coordinated with design (phase 8)

## Phase Dependency Graph

```
1 ──► 2 ──► 3 ──► 4
           └──► 5 ──► 7 ──► 8 ──► 9
  └──► 6 ──────────────────┘
                            10 (parallel; coord with backend rollout)
```

## Success Criteria (from brainstorm)

- [ ] Fresh install → picker → onboarding: every content request carries `X-Learning-Language`
- [ ] Authenticated language switch: home refetches, old in-memory state cleared via `ever()`
- [ ] Switch between 2 languages multiple times: progress preserved server-side per language
- [ ] 403 "not enrolled": single auto-resync + retry succeeds, user unaware
- [ ] AI chat body no longer contains `targetLanguage` field (verify via HTTP logger)
- [ ] Force-quit during switch: on relaunch, active language matches last `PATCH /languages/user/:id`
- [ ] Offline mode: header present on any requests that do fire; graceful error on uncached

## Risk Assessment (high-level)

- **Service init race** — `ApiClient.init` must run after `LanguageContextService.init`; enforced in phase 1.
- **Stale cache on upgrade** — existing users' local content is pre-partitioned; phase 5 adds one-time flush.
- **403 retry loop** — guarded by single-retry flag in `Options.extra`; phase 7.
- **Anonymous onboarding before backend deploy** — backend DB fallback + backfill; header-gate at phase 2.

## Docs Impact

After completion: update `docs/system-architecture.md` (new service + interceptor), `docs/code-standards.md` (optional note), `docs/codebase-summary.md` (DI order).

## Next Steps

1. Execute phase 1 (service) → phase 2 (interceptor) sequentially — both prerequisites for 3-7.
2. Phase 6 (translations) can be drafted in parallel with phase 1.
3. Phase 8 UX work blocked until 1-7 land on `feat/mobile-multi-language`.
