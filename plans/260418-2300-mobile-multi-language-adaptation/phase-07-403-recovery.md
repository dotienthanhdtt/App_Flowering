# Phase 07 — 403 Recovery (Resync + Retry Once)

## Context Links

- Brainstorm: [brainstorm-summary.md](brainstorm-summary.md) §4 + §Implementation Risks "403 retry loop"
- Backend contract: [mobile-adaptation-requirements.md §3](../../../be_flowering/plans/260418-2238-multi-language-content-architecture/mobile-adaptation-requirements.md)
- Phase 01 provides `resyncFromServer()`. Phase 06 provides error detection.
- Referenced files: phase 02 interceptor, `lib/core/network/api_client.dart`

## Overview

- **Priority:** P1 (degrades gracefully if missing; not a launch blocker but ships in v1)
- **Status:** pending
- **Description:** Interceptor-level 403 recovery. On `ForbiddenException` with `Language not enrolled` pattern, call `LanguageContextService.resyncFromServer()`, retry the original request once with the updated header. Retry-count guarded via `Options.extra['_langRetry']`. If no enrollments exist, route to onboarding.

## Key Insights

- Brainstorm §4: drift should be rare; aggressive UX (modal) punishes user for server state. One-shot auto-recovery is correct.
- Must live in `onError` of an interceptor to access original `RequestOptions` and re-issue via `dio.fetch(options)`.
- Guard against infinite loops via `Options.extra['_langRetry'] == true` — set before re-issue, checked on entry.
- Separate from `ActiveLanguageInterceptor` (phase 2) for clarity — single responsibility. Same file is fine but new class.
- Route fallback: if `resyncFromServer()` returns null (no enrollments), surface `notEnrolled` error normally and — if user is authed — navigate to language picker / settings language screen (phase 8).

## Requirements

**Functional:**
- New `LanguageRecoveryInterceptor extends Interceptor`.
- `onError(err, handler)`:
  - If `err.response?.statusCode != 403` → passthrough.
  - If message does not match `notEnrolled` pattern → passthrough.
  - If `err.requestOptions.extra['_langRetry'] == true` → passthrough (single retry only).
  - Else: `await languageContext.resyncFromServer()`.
    - If returns non-null: set `extra['_langRetry'] = true`, re-fire via `dio.fetch(opts)`, resolve with response.
    - If returns null: passthrough (original error surfaces; phase 8 handles navigation).
- Registered in `ApiClient.init` AFTER `ActiveLanguageInterceptor` so retry re-fires pass through language header injection.

**Non-functional:**
- Target file ~80 lines; under 200.
- No state — stateless class; reads service at call time.

## Architecture

```
Request  ──► [Retry] ──► [Auth] ──► [Language] ──► [LanguageRecovery] ──► [Logger] ──► wire
                                                         │
                                    onError: 403 notEnrolled
                                                         │
                                          retry-flag set? yes → propagate error
                                                         │ no
                                                         ▼
                                         resyncFromServer()
                                          │             │
                                  returns null         returns 'es' (new code)
                                          │             │
                                 propagate error   extra._langRetry = true
                                                        dio.fetch(options)
                                                        │
                                                        ▼
                                          [Language] re-injects 'es' header
                                                        │
                                                        ▼
                                                    Success → resolve
```

## Related Code Files

**CREATE:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/network/language-recovery-interceptor.dart`

**MODIFY:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/network/api_client.dart` — add interceptor to list between `ActiveLanguageInterceptor` and `HttpLoggerInterceptor`.

## Implementation Steps

1. Create `language-recovery-interceptor.dart`:
   ```dart
   import 'package:dio/dio.dart';
   import 'package:get/get.dart' hide Response;
   import '../services/language-context-service.dart';
   import 'api_exceptions.dart';

   class LanguageRecoveryInterceptor extends Interceptor {
     static const _retryFlag = '_langRetry';
     final Dio _dio;
     LanguageRecoveryInterceptor(this._dio);

     @override
     Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
       final status = err.response?.statusCode;
       final serverMsg = (err.response?.data is Map)
           ? (err.response!.data as Map)['message']?.toString()
           : null;
       final detected = detectLanguageContextError(status, serverMsg);

       if (detected != LanguageContextError.notEnrolled) return handler.next(err);
       if (err.requestOptions.extra[_retryFlag] == true) return handler.next(err);
       if (!Get.isRegistered<LanguageContextService>()) return handler.next(err);

       try {
         final newCode = await Get.find<LanguageContextService>().resyncFromServer();
         if (newCode == null) return handler.next(err); // user has no enrollments
         final opts = err.requestOptions;
         opts.extra[_retryFlag] = true;
         final response = await _dio.fetch(opts);
         return handler.resolve(response);
       } catch (_) {
         return handler.next(err);
       }
     }
   }
   ```

2. In `api_client.dart` interceptor list, final order:
   ```dart
   _dio.interceptors.addAll([
     RetryInterceptor(dio: _dio, maxRetries: 3),
     AuthInterceptor(authStorage),
     ActiveLanguageInterceptor(),
     LanguageRecoveryInterceptor(_dio),
     HttpLoggerInterceptor(),
   ]);
   ```

3. Ensure `RetryInterceptor` does NOT already retry 403 — verify by reading its logic. If it does, exempt 403 in RetryInterceptor OR accept that RetryInterceptor's network-level retry (usually limited to 5xx/timeout) is orthogonal.

4. Manual test: force a 403 (temporarily set active code to a non-enrolled value via hot-reload dev hook), observe single resync + retry; second 403 passes through.

5. `flutter analyze` clean.

## Todo List

- [ ] Create `language-recovery-interceptor.dart`
- [ ] Insert into `ApiClient.init` interceptor chain in correct position
- [ ] Verify `RetryInterceptor` does not double-retry on 403
- [ ] Smoke test: force 403 → observe resync → retry → success
- [ ] Smoke test: force 403 with no enrollments → original error surfaces
- [ ] Guard prevents loop: second 403 after retry → passthrough, no re-resync
- [ ] `flutter analyze` clean

## Success Criteria

- [ ] Exactly one resync + one retry per 403 `notEnrolled` response.
- [ ] Loop guard: post-retry 403 is surfaced to caller, no second resync attempt.
- [ ] User unaware of recovery when enrollments exist — request resolves transparently.
- [ ] If no enrollments → original `ForbiddenException` propagates; phase 8 handles navigation.

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| `RetryInterceptor` also retries 403 → double-recovery | Medium | Audit `retry_interceptor.dart` during implementation; exempt 403 from its retry conditions. |
| `resyncFromServer()` fails mid-recovery (network flake) | Medium | Caught in try/catch; propagates original error. User sees generic error. |
| `dio.fetch(opts)` re-runs interceptor chain and re-injects header | Expected | That's the point — new code picked up. |
| User has enrollments but none is `isActive` server-side | Low | `resyncFromServer()` picks first entry as fallback (phase 1). |

## Security Considerations

- Retry re-uses same auth token via `AuthInterceptor` chain — no session risk.
- No sensitive data logged.

## Next Steps

- Unblocks phase 8 — settings toggle can trust service as SoT without local validation.
- Follow-up: phase 9 adds integration test that simulates 403 → resync → retry.
