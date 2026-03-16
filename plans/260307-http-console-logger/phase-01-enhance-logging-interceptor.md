# Phase 01: Enhance Logging Interceptor

## Overview
- **Priority:** Low
- **Status:** Pending
- **Description:** Update the existing `_loggingInterceptor()` in `ApiClient` to log status, curl, response time, and response JSON to console.

## Related Code Files

### Files to Modify
- `lib/core/network/api_client.dart` — `_loggingInterceptor()` method (lines 42-66)

### Files to Create
- None

### Files to Delete
- None

## Key Insights

- The interceptor already exists and logs basic `method + path` and `statusCode + path`
- Dio's `RequestOptions` has an `extra` map we can use to store request start time
- `dart:convert` `jsonEncode` can pretty-print response data
- Guard everything behind `EnvConfig.isDev` (already done)

## Implementation Steps

1. **In `onRequest`** — store `DateTime.now()` in `options.extra['_startTime']`
2. **In `onRequest`** — build and print a curl command from `options` (method, baseUrl+path, headers, data)
3. **In `onResponse`** — calculate elapsed time from `_startTime`
4. **In `onResponse`** — print status code, elapsed ms, path, and JSON body (truncated if too large)
5. **In `onError`** — same timing + status + error body logging

### Curl Builder Logic

```dart
String _buildCurl(RequestOptions options) {
  final parts = ['curl'];
  parts.add('-X ${options.method}');

  // URL
  final url = '${options.baseUrl}${options.path}';
  final queryString = options.queryParameters.isNotEmpty
      ? '?${options.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}'
      : '';
  parts.add("'$url$queryString'");

  // Headers (skip content-type for brevity, include auth)
  options.headers.forEach((key, value) {
    if (key.toLowerCase() == 'authorization') {
      parts.add("-H '$key: Bearer ***'");
    } else {
      parts.add("-H '$key: $value'");
    }
  });

  // Body
  if (options.data != null && options.data is! FormData) {
    final body = jsonEncode(options.data);
    parts.add("-d '$body'");
  }

  return parts.join(' \\\n  ');
}
```

### Log Format

**Request:**
```
══════════════════════════════════════
→ GET /api/v1/lessons
curl -X GET \
  'https://api.example.com/api/v1/lessons' \
  -H 'Authorization: Bearer ***'
══════════════════════════════════════
```

**Response:**
```
══════════════════════════════════════
← 200 /api/v1/lessons [234ms]
{
  "code": 1,
  "message": "Success",
  "data": { ... }
}
══════════════════════════════════════
```

**Error:**
```
══════════════════════════════════════
✗ 401 /api/v1/lessons [89ms]
{
  "code": 0,
  "message": "Unauthorized"
}
══════════════════════════════════════
```

## Todo List

- [ ] Add `import 'dart:convert';` at top of file
- [ ] Add `_buildCurl()` helper method to `ApiClient`
- [ ] Update `onRequest` to store start time + print curl
- [ ] Update `onResponse` to print status, time, JSON body
- [ ] Update `onError` to print status, time, error body
- [ ] Truncate response body if > 1000 chars to avoid flooding console
- [ ] Mask Authorization header in curl output
- [ ] Run `flutter analyze` to verify no issues

## Success Criteria

- All API calls in dev mode print: curl command, status, response time (ms), response JSON
- Auth tokens are masked in curl output
- Large responses are truncated
- No logging in production (`EnvConfig.isDev` guard)
- File stays under 200 lines (extract helper if needed)
- `flutter analyze` passes clean

## Risk Assessment

- **Console flooding** — mitigated by truncating large response bodies
- **Token leaks in logs** — mitigated by masking Authorization header
- **Performance** — negligible; only runs in dev, `jsonEncode` on already-parsed data

## Security Considerations

- Never log full auth tokens — mask with `***`
- Dev-only guard via `EnvConfig.isDev`
