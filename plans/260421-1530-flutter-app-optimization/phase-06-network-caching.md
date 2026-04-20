# Phase 06 — Network Caching & Debouncing

## Context Links
- `research/researcher-04-network-efficiency.md` N4, N5, N6, N12

## Overview
- **Priority:** P3 (moderate win, moderate effort)
- **Status:** pending
- **Effort:** ~3h

Add minimal GET response caching with TTL, single-flight grammar check, jittered retry backoff, optional vocabulary search debounce.

## Key Insights
- Feed tabs re-fetch on every entry + lang change. Lightweight 60s TTL on GET responses would cut that.
- Grammar check races when user sends multiple messages quickly. Single-flight cancel-prev is the idiom.
- Retry thundering-herd: exponential without jitter compounds server recovery pain — easy fix.
- Vocabulary search is in-memory today; debouncing is defensive for when it becomes API-backed.

## Requirements

**Functional**
- GET responses for selected endpoints cached for TTL (default 60s).
- Grammar check only holds one in-flight call per chat session.
- Retry delays spread with ±50% jitter.

**Non-functional**
- Cache uses in-memory Map (YAGNI — no disk persistence; app restart clears).
- Cache is opt-in per call (`options.extra['cache_ttl_ms'] = 60000`) or opt-out (default).
- **Design choice**: opt-in to keep change surface minimal. Only wire into feed controllers.

## Architecture

```
ApiClient:
  final _cache = <String, _CacheEntry>{};
  _cacheKey(method, path, query) = 'METHOD path?sorted_query'
  
  get<T>(... , Duration? cacheTtl) {
    if (cacheTtl != null) {
      final entry = _cache[key];
      if (entry != null && !entry.expired) return entry.response as ApiResponse<T>;
    }
    final resp = await _dio.get(...);
    if (cacheTtl != null && resp.isSuccess) _cache[key] = _CacheEntry(resp, DateTime.now().add(cacheTtl));
    return resp;
  }

AiChatController:
  CancelToken? _grammarCancelToken;
  
  _checkGrammar(...) {
    _grammarCancelToken?.cancel('superseded');
    _grammarCancelToken = CancelToken();
    await _apiClient.post(..., cancelToken: _grammarCancelToken);
  }

RetryInterceptor:
  delay = base * 2^n * (0.5 + random * 1.0)  // 50% jitter
```

## Related Code Files

**Modify**
- `lib/core/network/api_client.dart` — add in-memory cache
- `lib/features/scenarios/controllers/flowering_feed_controller.dart` — use cacheTtl on default feed
- `lib/features/scenarios/controllers/for_you_feed_controller.dart` — same
- `lib/features/onboarding/services/onboarding_language_service.dart` — memoize language lists for session
- `lib/features/chat/controllers/ai_chat_controller.dart` — single-flight grammar check
- `lib/core/network/retry_interceptor.dart` — add jitter
- `lib/features/vocabulary/controllers/vocabulary-controller.dart` — optional debounce worker (YAGNI — skip unless API-backed)

## Implementation Steps

1. **ApiClient cache**:
   - Add private `_cache` Map + `_CacheEntry` class (response + expiresAt).
   - In `get<T>`, check cache before request; store on success.
   - Add method `invalidateCacheForPath(String path)` for post-write invalidation.
   - Don't cache requests with `fromJson` that returns DateTimes if they were parsed already — caching only the raw `ApiResponse<T>` means T is already parsed; OK but memory-proportional to payload. Limit to 20 entries.
2. **Wire cache in feed controllers**: pass `cacheTtl: Duration(seconds: 60)` to feed GETs. On language switch, call `apiClient.invalidateCacheForPath('/scenarios/')` via `CacheInvalidatorService`.
3. **Single-flight grammar check**:
   - Add `CancelToken? _grammarCancelToken` in AiChatController.
   - On new `_checkGrammar`, cancel previous, create new, pass to apiCall.
   - Handle cancel gracefully (silent drop).
4. **Jittered retry**:
   - In `RetryInterceptor`, compute `final jitter = 0.5 + Random().nextDouble();` and multiply delay.
5. **Vocabulary search debounce** — skip (YAGNI, list is in-memory).

## Todo List
- [ ] Add `_CacheEntry` + in-memory cache map to `ApiClient`
- [ ] Add `cacheTtl` param to `get<T>` method
- [ ] Add `invalidateCacheForPath` method + wire into `CacheInvalidatorService`
- [ ] Cap cache size at 20 entries (LRU evict)
- [ ] Wire `cacheTtl: 60s` into feed controllers
- [ ] Single-flight `_grammarCancelToken` in chat controller
- [ ] Add jitter to `RetryInterceptor` delay
- [ ] Manual smoke: feed tab switch is instant from cache
- [ ] Manual smoke: fast-send test → only one grammar result applied
- [ ] `flutter test` green

## Success Criteria
- Switching from "For You" to "Flowering" tab within 60s serves from cache (verify in dev logs).
- Sending 3 messages in 2s applies only the last grammar correction.
- Retry delays visibly vary in dev logs.

## Risk Assessment
- **Risk**: stale cache after backend mutation. Mitigation: invalidate on known writes; 60s TTL is the safety net.
- **Risk**: cache grows unbounded — LRU cap of 20 entries.
- **Risk**: cancelled grammar check leaves old correction shown. Mitigation: current code only writes correction on success; cancelled futures never set state. Safe.

## Security Considerations
- Cache keys include query params — verify no PII leaks into cache keys.
- Do not cache auth endpoints (enforced by opt-in model).

## Next Steps
- Phase 07 for shared widgets and dead code.
