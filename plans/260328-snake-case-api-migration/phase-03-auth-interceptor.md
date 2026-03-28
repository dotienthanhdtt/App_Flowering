# Phase 3: Auth Interceptor - Response Parsing

## Overview
- **Priority:** P1
- **Status:** pending
- The auth interceptor already uses snake_case for some keys but needs verification.

---

## File: `lib/core/network/auth_interceptor.dart`

### Current state (already correct)

Lines 97-103 already use snake_case:
```dart
data: {'refresh_token': refreshToken},
// ...
accessToken: response.data['data']['access_token'],
refreshToken: response.data['data']['refresh_token'],
```

**No changes needed** -- this file was already migrated or written against the snake_case contract.

---

## Also verify: `lib/core/network/api_response.dart`

Keys `code`, `message`, `data` -- these are unchanged in the new API. **No changes needed.**

## Also verify: `lib/shared/models/api_error_model.dart`

Keys `code`, `message`, `errors` -- unchanged. **No changes needed.**

---

## Todo

- [ ] Verify auth_interceptor.dart is correct (already snake_case) -- DONE, no changes
- [ ] Verify api_response.dart -- DONE, no changes
- [ ] Verify api_error_model.dart -- DONE, no changes
