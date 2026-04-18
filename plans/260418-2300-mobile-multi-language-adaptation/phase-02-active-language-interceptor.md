# Phase 02 — ActiveLanguageInterceptor

## Context Links

- Brainstorm: [brainstorm-summary.md](brainstorm-summary.md) §Interceptor Path Rules
- Backend contract: [mobile-adaptation-requirements.md §1](../../../be_flowering/plans/260418-2238-multi-language-content-architecture/mobile-adaptation-requirements.md)
- Phase 01: service provides `activeCode`
- Referenced files: `lib/core/network/api_client.dart` (lines 33-37), `lib/core/network/auth_interceptor.dart`, `lib/core/network/retry_interceptor.dart`

## Overview

- **Priority:** P0 (blocks phases 3, 4, 7)
- **Status:** pending
- **Description:** New Dio interceptor that reads active code from `LanguageContextService` and sets `X-Learning-Language` header on content-scoped requests. Path allowlist via `startsWith`. Registration order: Retry → Auth → **Language** → Logger.

## Key Insights

- Header MUST be attached AFTER auth (so no risk of auth refresh clobbering) and BEFORE logger (so logs show final outgoing headers).
- Path skip list: `/auth`, `/languages`, `/users/me`, `/subscription`, `/admin` — anything that should NOT carry a learning-language scope.
- Interceptor must be defensive: if service is uninitialized (shouldn't happen after phase 1 fix), log once and proceed without header — server may still serve via DB fallback.
- Per-request override via `Options(headers: {...})` naturally wins because it reaches Dio headers map after interceptors run — no code needed to support it.

## Requirements

**Functional:**
- `onRequest(options, handler)`: if `_needsLanguageHeader(options.path)` and `activeCode.value != null`, set `options.headers['X-Learning-Language'] = activeCode.value`.
- `_needsLanguageHeader(path)`: return `!skip.any(path.startsWith)`.
- Do NOT set header when path is in skip list, even if service has a code.
- Do NOT overwrite an explicit `X-Learning-Language` already on the options (per-request override).

**Non-functional:**
- File under 200 lines (target ~60).
- Zero exceptions out of `onRequest`; any failure logged via `debugPrint` and `handler.next(options)` called.

## Architecture

```
    Dio request  ─► RetryInterceptor
                    │
                    ▼
                   AuthInterceptor (attaches Bearer)
                    │
                    ▼
                   ActiveLanguageInterceptor
                    │  path in allowlist?
                    │    yes → headers['X-Learning-Language'] = service.activeCode
                    │    no  → passthrough
                    ▼
                   HttpLoggerInterceptor (logs final headers)
                    │
                    ▼
                   Network
```

### Path Rules

**Skip (no header):**
- `/auth`
- `/languages`
- `/users/me`
- `/subscription`
- `/admin`

**Attach (header required):** everything else — effectively `/lessons`, `/scenarios`, `/ai`, `/vocabulary`, `/onboarding`, `/progress`, `/chat`.

Rationale for skip-list (not allowlist): new content endpoints auto-get the header; only auth/ownership/admin paths opt out.

## Related Code Files

**CREATE:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/network/active-language-interceptor.dart`

**MODIFY:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/network/api_client.dart` — insert interceptor into `_dio.interceptors.addAll([...])` (lines 33-37). New order: `RetryInterceptor`, `AuthInterceptor`, `ActiveLanguageInterceptor`, `HttpLoggerInterceptor`.

**DELETE:** none.

## Implementation Steps

1. Create `lib/core/network/active-language-interceptor.dart`:
   ```dart
   import 'package:dio/dio.dart';
   import 'package:get/get.dart' hide Response;
   import '../services/language-context-service.dart';

   class ActiveLanguageInterceptor extends Interceptor {
     static const List<String> _skipPrefixes = [
       '/auth', '/languages', '/users/me', '/subscription', '/admin',
     ];
     static const String _headerName = 'X-Learning-Language';

     @override
     void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
       try {
         if (options.headers.containsKey(_headerName)) {
           return handler.next(options); // per-request override wins
         }
         if (!_needsHeader(options.path)) return handler.next(options);
         if (!Get.isRegistered<LanguageContextService>()) return handler.next(options);

         final code = Get.find<LanguageContextService>().activeCode.value;
         if (code != null && code.isNotEmpty) {
           options.headers[_headerName] = code;
         }
       } catch (_) {
         // Never block request on interceptor error
       }
       handler.next(options);
     }

     bool _needsHeader(String path) => !_skipPrefixes.any(path.startsWith);
   }
   ```

2. Modify `lib/core/network/api_client.dart` interceptor list (lines 33-37):
   ```dart
   _dio.interceptors.addAll([
     RetryInterceptor(dio: _dio, maxRetries: 3),
     AuthInterceptor(authStorage),
     ActiveLanguageInterceptor(),
     HttpLoggerInterceptor(),
   ]);
   ```
   Import the new file at top of `api_client.dart`.

3. Run `flutter analyze`.

4. Manual smoke: log a request to `/lessons` — header present. Log `/auth/login` — header absent.

## Todo List

- [ ] Create `active-language-interceptor.dart`
- [ ] Insert into `ApiClient.init` interceptor list in correct order
- [ ] Verify path allowlist via unit test (phase 9)
- [ ] Smoke test: `/lessons` GET shows `X-Learning-Language`; `/auth/login` POST does not
- [ ] Smoke test: per-request `Options(headers: {'X-Learning-Language': 'es'})` overrides default

## Success Criteria

- [ ] Header attached on all paths outside skip list when `activeCode` non-null.
- [ ] Header absent on skip-list paths.
- [ ] Per-request override preserved.
- [ ] No exceptions surfacing from interceptor under any input.

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Service not registered yet (test env, hot reload) | Medium | `Get.isRegistered` guard; log and skip. |
| Path prefix collision (e.g. `/users/me-else` exists) | Low | `startsWith('/users/me')` is intentional — covers `/users/me/anything`; document. |
| Header set on non-content endpoint | Low | Skip list is explicit; review yearly. |

## Security Considerations

- Header value is a language code (e.g. `en`) — not sensitive.
- No PII; safe to log in `HttpLoggerInterceptor`.

## Next Steps

- Unblocks phase 3 (onboarding ctrl can now fire `/onboarding/chat` with header).
- Unblocks phase 7 (403 recovery lives in a separate interceptor or the same file — phase 7 will decide).
