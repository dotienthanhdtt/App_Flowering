# Phase 01 — C6 AuthInterceptor Double-Refresh Race

## Context Links

- Report: `plans/reports/code-reviewer-260419-2022-feat-update-onboarding-5-commits.md` (C6)
- Report: `plans/reports/code-reviewer-260419-2021-adversarial-feat-update-onboarding.md` (race section)
- Code: `lib/core/network/auth_interceptor.dart:41-75`

## Overview

- Priority: Critical
- Status: pending
- Concurrent 401s each trigger independent `refreshTokens()`; a late-arriving refresh clears tokens just set by the winning refresh.

## Key Insights

- Existing `retryDio` pattern at `auth_interceptor.dart:56-60` is correct; only the refresh kickoff lacks serialization.
- `QueuedInterceptor` does not serialize across independent `onError` invocations for different requests — need explicit gate.

## Requirements

Functional
- Concurrent 401s within same refresh window result in a single `refreshTokens()` network call.
- All queued requests retry with the freshly obtained access token.
- Refresh failure clears tokens once; each queued request surfaces auth error.

Non-functional
- No deadlocks if refresh throws.
- No memory leak of completers (always completed in finally).

## Architecture

```
Request A ──┐
Request B ──┼─► onError(401) ─► gate.isInFlight?
Request C ──┘                    │
                      no ──► set Completer, call refresh(), complete()
                      yes ─► await Completer.future
                      after: retry via retryDio with new token
```

## Related Code Files

Modify
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/network/auth_interceptor.dart`

Create
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/test/core/network/auth_interceptor_race_test.dart`

## Implementation Steps

1. Add private `Completer<bool>? _refreshGate` field.
2. In `onError`, when status=401, wrap refresh logic:
   - If `_refreshGate != null` → await its future, use result to decide retry vs fail.
   - Else → create completer, assign to field, run refresh inside try/finally, complete with boolean result, null the field in finally.
3. Keep existing `retryDio` retry call post-refresh for the current request.
4. On refresh failure, call `clearTokens()` exactly once (inside completer branch only).
5. Preserve existing skip-paths (`/auth/refresh`, `/auth/login`).

## Todo List

- [ ] Add `_refreshGate` completer field
- [ ] Refactor 401 branch to await-or-initiate pattern
- [ ] Ensure completer always completes (finally)
- [ ] Guard `clearTokens()` inside initiator only
- [ ] Unit test: two concurrent 401s → one refresh call
- [ ] Unit test: refresh failure clears tokens once, both requests fail
- [ ] Unit test: refresh success → both retry with new token
- [ ] `flutter analyze` clean

## Success Criteria

- Mock Dio emitting two simultaneous 401s triggers exactly one `refreshTokens()` mock invocation.
- `AuthStorage.clearTokens` called ≤1 time across a failed-refresh scenario.
- No test flake across 20 repeated runs.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Completer leak on unexpected throw | Low | High (deadlock) | `try/finally` around completer completion |
| Retry uses stale token if gate timing skewed | Low | High | Read token from storage AFTER completer resolves, not before |
| Existing callers relying on error surface | Low | Med | Preserve `rejectError` shape; only change refresh flow |

## Security Considerations

- Token never logged.
- On refresh failure ensure stored refresh token cleared to prevent reuse of rotated tokens.
- Do not widen error payload — keep auth errors opaque.

## Next Steps / Dependencies

- Independent phase. Can land first.
- Pattern reused in Phase 3/4 (language recovery gate).
