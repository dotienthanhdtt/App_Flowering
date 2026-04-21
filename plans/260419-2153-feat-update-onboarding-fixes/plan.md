---
title: "feat/update-onboarding critical fixes"
description: "Fix 7 critical issues from code review: auth race, payload casing, interceptor retry, cache blast radius, controller lifecycle, Firebase leak."
status: completed
priority: P1
effort: 18h
branch: feat/update-onboarding
tags: [bugfix, auth, interceptors, onboarding, cache, security]
created: 2026-04-19
---

# feat/update-onboarding Critical Fixes

## Context

Source reviews:
- `plans/reports/code-review-260419-2021-feat-update-onboarding-summary.md`
- `plans/reports/code-reviewer-260419-2022-feat-update-onboarding-5-commits.md`
- `plans/reports/code-reviewer-260419-2021-adversarial-feat-update-onboarding.md`

## Locked Decisions (do not re-debate)

1. `/onboarding/complete` payload = **snake_case** (callers convert).
2. `/users/me` does NOT carry `X-Learning-Language` (keep exclusion).
3. `X-Learning-Language` validated server-side → C7/C8 out of scope.
4. `OnboardingController` becomes **route-scoped**; shared state → `OnboardingProgressService`.
5. Pref-key prefix rework deferred → I4 / I9 out of scope.

## Phases

| # | Phase | File | Status | Effort | Depends |
|---|-------|------|--------|--------|---------|
| 1 | C6 AuthInterceptor double-refresh race | [phase-01-auth-refresh-race.md](phase-01-auth-refresh-race.md) | completed | 2h | — |
| 2 | C1 Payload casing (snake_case) | [phase-02-payload-casing.md](phase-02-payload-casing.md) | completed | 2h | — |
| 3 | C2 LanguageRecoveryInterceptor retryDio | [phase-03-recovery-retry-dio.md](phase-03-recovery-retry-dio.md) | completed | 2h | — |
| 4 | C3 Convert LanguageRecovery to QueuedInterceptor | [phase-04-recovery-queued-interceptor.md](phase-04-recovery-queued-interceptor.md) | completed | 2h | Phase 3 |
| 5 | C4+C5a Scoped cache invalidation + seeded race | [phase-05-scoped-cache-invalidation.md](phase-05-scoped-cache-invalidation.md) | completed | 3h | — |
| 6 | C5 OnboardingController route-scoped | [phase-06-onboarding-controller-scope.md](phase-06-onboarding-controller-scope.md) | completed | 3h | — |
| 7 | C9 Firebase error message leak | [phase-07-firebase-error-leak.md](phase-07-firebase-error-leak.md) | completed | 2h | — |
| 8 | Tests + verification pass | [phase-08-tests-and-verification.md](phase-08-tests-and-verification.md) | completed | 2h | 1-7 |

## Dependency Graph

- Phase 4 requires Phase 3 (shares retryDio infra).
- Phase 6 independent but touches same feature area as Phase 2 (`_finalizeOnboarding`); land Phase 2 first to avoid merge noise.
- Phases 1, 3, 5, 7 independent — can be parallelized.
- Phase 8 runs after all implementation phases.

## Success Criteria (global)

- `flutter analyze` clean.
- `flutter test` green including new tests per phase.
- No regression in onboarding happy-path manual smoke.
- Concurrent 401 and 403 scenarios covered by unit tests.

## Out of Scope

- I4 cache over-flush (prefix rework deferred).
- I9 shared-device leak (prefix rework deferred).
- C7/C8 `X-Learning-Language` trust (server validates).
