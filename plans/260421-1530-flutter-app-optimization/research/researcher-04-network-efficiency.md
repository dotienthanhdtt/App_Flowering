# Researcher 04 — Network Efficiency Report

Scope: Dio interceptor overhead, request debouncing/caching, pagination, retry logic.

## Findings

### N1. Interceptor chain reads secure storage on every request
- `AuthInterceptor.onRequest` (line 27) awaits `flutter_secure_storage.read(access_token)` before every single request. Keychain/Keystore calls are 5-20ms on iOS, higher on Android cold-read.
- Compounding: `AuthStorage` already caches `_cachedToken` for `isLoggedIn` — but the getter `getAccessToken()` still goes to disk.
  - Fix: have `AuthInterceptor` read `_authStorage.cachedTokenSync ?? await _authStorage.getAccessToken()`. Expose a sync cached accessor.
  - Expected: saves ~5-20ms per request on iOS, ~10-40ms Android.

### N2. Retry Dio shares no interceptors → duplicates logic
- `ApiClient._retryDio` is a fresh `Dio` with no interceptors. Means refreshed tokens are manually injected via `err.requestOptions.headers['Authorization']`. OK design but log lines are missed on retries.
  - Keep as-is but doc clearly. Low priority.

### N3. `RetryInterceptor` runs for 5xx server errors — retries mutations unsafely
- Line 63: `if (statusCode >= 500) return true` — blanket retry on ALL verbs including POST/PUT/DELETE.
- Risk: double-charge, duplicate session create (onboarding chat creates new conversation on retry).
  - Fix: only retry idempotent methods (GET/HEAD/OPTIONS) by default; require explicit `options.extra['retry'] = true` for non-idempotent retries. Also exclude `onboarding/chat` POST when it creates a session (no conversationId).

### N4. No client-side caching for repeated GETs
- Feed endpoints (`/scenarios/default`, `/scenarios/personal`) are called on tab entry + pull-to-refresh + language change. No ETag/If-None-Match support wired.
- Language list is fetched twice during onboarding (native + learning) via `Future.wait` — no memoization across controller recreation.
  - Fix: add lightweight in-memory cache keyed by endpoint+lang+page with TTL (e.g., 60s) for GETs. Store in `ApiClient` or a `ResponseCacheService`.
  - Caution: don't cache auth-sensitive or user-mutable writes.

### N5. Grammar correction + chat send fire in parallel but unthrottled
- `ai_chat_controller.sendMessage` invokes `_checkGrammar` concurrently. Good UX. But if user types 5 fast messages, 5 grammar requests race and may arrive out of order; controller doesn't cancel older requests.
  - Fix: single-flight grammar checks — cancel previous `CancelToken` when a new one starts.

### N6. No request deduplication
- If user double-taps "Send" quickly, two identical POSTs race. `sendMessage` guards with `isTyping` indirectly but not explicitly debounced.
- Vocabulary search `onChanged` pipes straight into controller without debounce — each keystroke triggers a filter-only op (cheap for in-memory list), but if wired to an API later it would need debounce.
  - Fix: add 300ms debounce on vocabulary search (future-proof) using `debounce(searchQuery, fn, time: Duration(milliseconds: 300))` worker.

### N7. Pagination uses client-side `_page * limit < total` heuristic
- `FloweringFeedController._hasMore` computed from `_page * limit < total`. If backend returns `total` as a snapshot and new items are inserted between pages, pagination can skip/repeat items.
  - Fix: use backend `hasMore` or cursor-based pagination when available. Not blocking — acceptable for current UX.

### N8. SSE stream parsing allocates string per chunk
- `api_client.postStream` builds `buffer += String.fromCharCodes(chunk)` — O(N²) for long streams.
  - Fix: use `StringBuffer` OR stream-transform with `utf8.decoder.bind(byteStream).transform(LineSplitter())`. Not currently hot (SSE not used in main flows?) — verify before investing.

### N9. HTTP logger prints full curl + full body on every dev request
- `http_logger_interceptor.dart` adds ~1-5ms per request on DEBUG builds (JSON pretty-print). Fine for dev. Ensure it's skipped in release (already gated on `EnvConfig.isDev`).

### N10. Timeouts may be too long for chat send
- Chat endpoints: `connectTimeout: 15s, receiveTimeout: 30s`. AI responses can take 10+ seconds so 30s receive is reasonable. Keep.

### N11. Token refresh race handled correctly
- `AuthInterceptor` uses `QueuedInterceptor` + `Completer` gate. Good implementation.

### N12. No exponential backoff jitter
- `RetryInterceptor` uses `initialDelay * (1 << retryCount)` — pure exponential. Under thundering-herd conditions (server recovering) all clients retry simultaneously.
  - Fix: add jitter: `delay = base * 2^n * random(0.5..1.5)`. Low priority.

## Summary of priorities
1. N1 — reuse cached token → per-request speedup (trivial change, big cumulative win)
2. N3 — restrict retry to idempotent methods → correctness fix (prevents duplicate writes)
3. N5 — single-flight grammar check → correctness + UX
4. N4 — GET response cache with TTL → bandwidth + UX (moderate effort, moderate win)
5. N12 — add jitter (cheap)
6. N8 — SSE optimization (only if SSE is used in hot path)

## Unresolved questions
- Is `api_client.postStream` actually used anywhere in active flows?
- Does the backend emit ETag headers? Without it, the cache plan is local-TTL only.
