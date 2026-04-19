# Critical Bug Fixes: Concurrency, Caching, and API Contract Violations

**Date:** 2026-04-19 14:30
**Severity:** Critical
**Component:** Network layer, state management, storage, auth
**Status:** Resolved

## What Happened

Implemented 7 critical fixes from code review on `feat/update-onboarding` branch addressing concurrency races, cache invalidation logic, API contract mismatches, and security leaks. All phases completed, code compiles cleanly, pre-existing test failures confirmed unrelated.

## The Brutal Truth

These weren't typos or style issues — they were architectural bugs that would cause race conditions in production, cache poisoning, and silent authentication failures. The concurrency problems (double-refresh, serialization deadlock) would manifest intermittently under real network load, making them nightmarish to debug post-release. Caught before shipping, which matters.

## Technical Details

- **AuthInterceptor race**: `bool _isRefreshing` → `Completer<bool>? _refreshGate`. Concurrent 401s now await shared gate instead of triggering independent refresh cycles. Prevents token clobbering.
- **LanguageRecoveryInterceptor**: Extended `QueuedInterceptor` (not `Interceptor`), uses shared `_retryDio` (empty interceptors) to break re-entry cycle. Added Completer gate for concurrent 403 serialization.
- **API contract**: 9 snake_case payload keys normalized across `ai_chat_controller`, `auth_controller`. Backend expects `native_language`, not `nativeLanguage`.
- **Cache scoping**: Per-language Hive sub-boxes (`lessons_cache_$langCode`) replace flat structure. `_baselineCode` captured synchronously before `ever()` registration closes seeded-emission race.
- **Route scoping**: `OnboardingController` removed `permanent: true`, relies on `OnboardingProgressService` for persistent state. Prevents memory leaks on route transitions.
- **Security leak**: `mapFirebaseAuthErrorCode()` mapper added. Stops `e.message` (contains OAuth fragments) from leaking to UI. 9 new l10n keys added to both EN/VI.

## Lessons Learned

1. **Concurrency logic belongs in Completers, not booleans** — Flags can't express "wait for the operation to finish." Use Completer gates for shared resources.
2. **Interceptor chains must respect queue semantics** — `QueuedInterceptor` + isolated request client prevents re-entry surprises.
3. **Cache invalidation scope matters** — Global caches without entity keys (lessons_cache flat) guarantee poisoning. Language-scoped boxes are non-negotiable.
4. **Lifecycle permanence is context-dependent** — Controllers tied to routes shouldn't claim `permanent: true` if their state lives elsewhere. Explicit ownership rules prevent double-management bugs.
5. **Third-party error messages are PII vectors** — Firebase SDKs return raw OAuth tokens in `.message`. Always map to safe enum + translations.

## Next Steps

- Monitor production deploys for crash spikes (concurrency fixes should show instant reduction in auth failures)
- Add integration tests for concurrent 401 scenarios and cross-language cache isolation
- Document interceptor ordering assumptions in `lib/core/network/README.md`

**Commit:** f8a8daa
