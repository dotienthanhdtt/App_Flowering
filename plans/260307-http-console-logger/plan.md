# HTTP Console Logger

## Status: Ready
## Priority: Low
## Effort: ~15 min

## Overview

Enhance the existing `_loggingInterceptor()` in `ApiClient` to log richer HTTP debug info to console: status code, curl command, response time, and response JSON body.

## Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | Enhance logging interceptor | [x] Complete |

## Key Decisions

- **Single file change** — only `lib/core/network/api_client.dart`
- **Console only** — use `print()` (already used), dev-only via `EnvConfig.isDev`
- **No new dependencies** — use Dio's built-in `DateTime` for timing via `requestOptions.extra`
- **No separate file** — the interceptor stays inline since it's under 200 lines total

## Dependencies

- None. Self-contained change.