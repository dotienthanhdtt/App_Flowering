# Phase 04 — C3 LanguageRecoveryInterceptor QueuedInterceptor

## Context Links

- Report: `plans/reports/code-reviewer-260419-2022-feat-update-onboarding-5-commits.md` (C3)
- Code: `lib/core/network/language-recovery-interceptor.dart:16`
- Sibling: `lib/core/network/auth_interceptor.dart` (Completer gate pattern from Phase 1)

## Overview

- Priority: Critical
- Status: pending
- Concurrent 403s each flip `_recovering` bool non-atomically → multiple resyncs, redundant server calls, possible stale token/code use on retry.

## Key Insights

- Either (a) extend `QueuedInterceptor` for natural serialization of `onError`, or (b) apply the Phase 1 Completer-gate pattern.
- Prefer `QueuedInterceptor` — symmetry with Auth, no bespoke plumbing.

## Requirements

Functional
- Two concurrent 403s trigger exactly one `resyncActiveLanguage()`.
- Both requests retry after resync completes, using new language code.
- If resync fails, both surface original 403 (do not retry indefinitely).

Non-functional
- No deadlock if resync throws.
- Works with Phase 3's `retryDio`.

## Architecture

```
Request A (403) ─┐
Request B (403) ─┤─► QueuedInterceptor.onError (serialized)
Request C (403) ─┘      ├── gate.inFlight? await : initiate resync
                         └── retryDio.fetch(req) per-request
```

## Related Code Files

Modify
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/network/language-recovery-interceptor.dart`

Create
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/test/core/network/language_recovery_concurrency_test.dart`

## Implementation Steps

1. Change class to extend `QueuedInterceptor` (from `package:dio/dio.dart`).
2. Add `Completer<bool>? _resyncGate` field.
3. In `onError`:
   - If not 403 or already on skip path → `handler.next(err)`.
   - If gate in-flight → await its future; on success retry; on fail pass error.
   - Else set completer, call `resyncActiveLanguage()` inside try/finally, complete boolean, null field in finally.
4. Remove `_recovering` bool.
5. Use `retryDio` from Phase 3.

## Todo List

- [ ] Extend `QueuedInterceptor`
- [ ] Add `_resyncGate` completer
- [ ] Remove legacy `_recovering` bool
- [ ] Wire retryDio (from Phase 3)
- [ ] Unit test: two concurrent 403s → one resync call
- [ ] Unit test: both retry after resync with new header value
- [ ] Unit test: resync failure → both requests fail; gate cleared for next cycle
- [ ] `flutter analyze` clean

## Success Criteria

- `resyncActiveLanguage` mock invoked exactly once for 3 concurrent 403s.
- Gate field null after each cycle (verified via test hook or repeated runs).
- No regression on single-403 happy path.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| QueuedInterceptor ordering differs from current | Low | Med | Tests cover retry order indifference |
| Completer not completed on exception | Low | High | `try/finally` with default `false` completion |
| Interaction with AuthInterceptor refresh | Low | High | Order interceptors: Auth before LanguageRecovery; tests exercise both |

## Security Considerations

- Ensure retried request uses updated language code (avoid authz bypass where user switched languages).
- Do not expose internal resync error details; fall through with original 403.

## Next Steps / Dependencies

- Depends on Phase 3 (`retryDio`).
- Independent of Phases 1/2/5/6/7.
