# Phase 01 — Quick Wins: Token Cache, Image Caching, Retry Safety

## Context Links
- `research/researcher-01-performance.md` H3
- `research/researcher-04-network-efficiency.md` N1, N3

## Overview
- **Priority:** P1 (high impact, low risk, trivial diffs)
- **Status:** pending
- **Effort:** ~2h

Three independent low-risk fixes grouped together because each is <30 LOC and they touch separate files.

## Key Insights
- `AuthInterceptor` awaits flutter_secure_storage on every request even though `AuthStorage` already has `_cachedToken` for sync access.
- `scenario_card.dart` and `feed_scenario_card.dart` use `Image.network` with no cache; `CachedNetworkImage` already used elsewhere in project (`language-picker-sheet.dart`).
- `RetryInterceptor` retries POST/PUT/DELETE on 5xx — risks duplicate mutations (e.g., creating two onboarding conversations).

## Requirements

**Functional**
- Reduce per-request auth overhead.
- Cache network images used in scenario lists.
- Prevent duplicate writes on server-error retry.

**Non-functional**
- No behavior change for happy path.
- Backward compatible with existing call sites.

## Architecture

```
AuthInterceptor.onRequest
   ├─ read AuthStorage.cachedAccessToken (SYNC)
   └─ fallback → getAccessToken() (async) if cache null

RetryInterceptor._shouldRetry
   ├─ method is GET/HEAD/OPTIONS → retry allowed
   └─ method is POST/PUT/DELETE/PATCH → only if options.extra['retry_safe'] == true

CachedScenarioImage (new shared widget)
   └─ used by scenario_card.dart + feed_scenario_card.dart
```

## Related Code Files

**Modify**
- `lib/core/services/auth_storage.dart` — expose sync `cachedAccessToken` getter
- `lib/core/network/auth_interceptor.dart` — use sync cache first
- `lib/core/network/retry_interceptor.dart` — restrict retry by HTTP verb
- `lib/features/onboarding/widgets/scenario_card.dart` — switch to CachedNetworkImage
- `lib/features/scenarios/widgets/feed_scenario_card.dart` — switch to CachedNetworkImage

**Create** (optional — skip if only 2 call sites)
- `lib/shared/widgets/cached-scenario-image.dart` — wraps CachedNetworkImage with app-standard placeholder/error

## Implementation Steps

1. **AuthStorage**: add `String? get cachedAccessToken => _cachedToken;`. Update `_cachedToken` in `saveTokens` (already done) and in `refreshLoginState()` to also cache. Confirm no `null`/`empty` drift.
2. **AuthInterceptor.onRequest**: replace `await _authStorage.getAccessToken()` with `_authStorage.cachedAccessToken ?? await _authStorage.getAccessToken()`. Measure no regression.
3. **RetryInterceptor._shouldRetry**: add method check — only retry if `err.requestOptions.method` is GET/HEAD/OPTIONS, unless `err.requestOptions.extra['retry_safe'] == true` is explicitly set.
4. **Scenario cards**: replace `Image.network(url, fit: BoxFit.cover, errorBuilder: ...)` with `CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: ..., errorWidget: ...)`. Use existing placeholders (`_PlaceholderBg`, `_buildPlaceholder`).
5. If the placeholder/error pattern ends up identical in both cards, extract `CachedScenarioImage` — else inline both.
6. Run `flutter analyze` and manual smoke on auth + feed.

## Todo List
- [ ] Add `cachedAccessToken` getter to `AuthStorage`
- [ ] Wire sync cache into `AuthInterceptor.onRequest`
- [ ] Restrict `RetryInterceptor` to idempotent methods
- [ ] Add opt-in `retry_safe` extra flag for POSTs that are explicitly safe to retry (document none currently)
- [ ] Replace `Image.network` with `CachedNetworkImage` in `scenario_card.dart`
- [ ] Replace `Image.network` with `CachedNetworkImage` in `feed_scenario_card.dart`
- [ ] Extract `CachedScenarioImage` shared widget if placeholder logic repeats
- [ ] Run `flutter analyze` — no new warnings
- [ ] Manual smoke: login → feed scrolls without flicker, images persist across tab switch

## Success Criteria
- Auth interceptor logs show no disk read per request (verify in dev mode).
- Feed scroll reuses cached images on second render (visible lack of flicker).
- No POST retries observed in dev logs on induced 500 error.
- `flutter test` still green.

## Risk Assessment
- **Risk**: `_cachedToken` could stale after logout — mitigated by `clearTokens()` already nulls it.
- **Risk**: Users with stale cached images after backend image rotation — default `CachedNetworkImage` TTL is acceptable; add `cacheKey` if needed later.
- **Risk**: Disabling 5xx retry on POST may surface transient failures. Acceptable trade-off; user sees error and retries manually (chat send already does).

## Security Considerations
- Cached token is in-memory only (not persisted elsewhere) — same trust boundary as `_cachedToken` today.
- Logout path already clears `_cachedToken`.

## Next Steps
- Phase 02 picks up rebuild optimizations now that image caching is in place.
