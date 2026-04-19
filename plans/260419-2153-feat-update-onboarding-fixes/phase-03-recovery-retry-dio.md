# Phase 03 — C2 LanguageRecoveryInterceptor Uses retryDio

## Context Links

- Report: `plans/reports/code-reviewer-260419-2022-feat-update-onboarding-5-commits.md` (C2)
- Code: `lib/core/network/language-recovery-interceptor.dart:44`
- Reference pattern: `lib/core/network/auth_interceptor.dart:56-60`
- Wiring: `lib/core/network/api_client.dart:37-41`

## Overview

- Priority: Critical
- Status: pending
- `_dio.fetch(requestOptions)` re-enters full interceptor chain → retry counters cross-contaminate, `ActiveLanguageInterceptor` re-runs, potential infinite loop on persistent 403.

## Key Insights

- `retryDio` = standalone `Dio` with empty interceptors, used only for replays after recovery.
- `auth_interceptor.dart` already uses this pattern — mirror it exactly.

## Requirements

Functional
- Retried request bypasses all interceptors.
- `X-Learning-Language` header value for retry uses freshly-resolved code (post-resync), set manually on requestOptions.
- Retry-counter field (if any) not re-incremented by interceptor chain.

Non-functional
- Single shared `retryDio` instance across interceptors (reuse AuthInterceptor's or share via ApiClient).

## Architecture

```
ActiveLangInterceptor ─► adds X-Learning-Language
  ▼
Request ─► 403 ─► LanguageRecoveryInterceptor.onError
                   ├── resyncActiveLanguage()
                   ├── update requestOptions.headers[X-Learning-Language]
                   └── retryDio.fetch(requestOptions)  ← empty chain
```

## Related Code Files

Modify
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/network/language-recovery-interceptor.dart`
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/network/api_client.dart` (inject shared retryDio)

Create
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/test/core/network/language_recovery_retry_test.dart`

## Implementation Steps

1. In `ApiClient`, expose a shared `Dio _retryDio` (empty interceptors) — reuse existing one if already built for `AuthInterceptor`.
2. Pass `retryDio` into `LanguageRecoveryInterceptor` constructor.
3. Replace `_dio.fetch(requestOptions)` with `retryDio.fetch(requestOptions)`.
4. Before retry, re-resolve active language and set header on `requestOptions.headers['X-Learning-Language']`.
5. Ensure same baseUrl/auth headers still propagate (copy Authorization from original requestOptions).

## Todo List

- [ ] Add/ reuse shared `retryDio` in `ApiClient`
- [ ] Thread `retryDio` into `LanguageRecoveryInterceptor` ctor
- [ ] Replace `_dio.fetch` with `retryDio.fetch`
- [ ] Preserve Authorization + other required headers
- [ ] Refresh `X-Learning-Language` after resync
- [ ] Unit test: 403 triggers resync + retry on retryDio
- [ ] Unit test: retry path does NOT re-enter ActiveLanguageInterceptor (observable via counter or mock)
- [ ] `flutter analyze` clean

## Success Criteria

- Retry request observed bypassing `ActiveLanguageInterceptor` (mock spy records 1 invocation for original, 0 for retry).
- No infinite-loop scenario on repeated 403 (bounded by explicit retry count, not chain recursion).

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| retryDio missing Authorization → spurious 401 | Med | High | Copy `Authorization` from original requestOptions |
| Two interceptors sharing retryDio cause coupling | Low | Low | Single instance owned by `ApiClient` |
| Different baseUrl config | Low | Med | Build retryDio from same `BaseOptions` as main Dio |

## Security Considerations

- Ensure Authorization header propagates on retry — absence would leak protected endpoint call as anonymous.
- Do not log full requestOptions (PII risk).

## Next Steps / Dependencies

- Blocks Phase 4 (Phase 4 layers QueuedInterceptor semantics on top of this retry fix).
