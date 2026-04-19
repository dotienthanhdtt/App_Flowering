# Phase 07 — C9 Firebase Error Message Leak

## Context Links

- Report: `plans/reports/code-reviewer-260419-2022-feat-update-onboarding-5-commits.md` (C9)
- Code: `lib/features/auth/controllers/auth_controller.dart:168-172`

## Overview

- Priority: Critical
- Status: pending
- `errorMessage.value = e.message` on `FirebaseAuthException` can surface OAuth token fragments / internal details to UI + Crashlytics logs.

## Key Insights

- FirebaseAuth error messages are not localized; may contain PII or token fragments depending on code path.
- Must map `e.code` → translation key; do NOT forward `e.message`.
- Both English + Vietnamese translation files must carry the new keys.

## Requirements

Functional
- Each known FirebaseAuth error code maps to a stable translation key.
- Unknown codes fall back to generic `auth_error_generic`.
- `e.message` never assigned to `errorMessage.value`.
- Crashlytics receives `e.code` (stable) not `e.message` (potentially sensitive).

Non-functional
- Translations present in both locale files.
- Mapping table single source of truth (helper function).

## Related Code Files

Modify
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/features/auth/controllers/auth_controller.dart`
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/l10n/english-translations-en-us.dart`
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/l10n/vietnamese-translations-vi-vn.dart`

Create
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/features/auth/utils/firebase_auth_error_mapper.dart` (pure function, <80 lines)
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/test/features/auth/firebase_auth_error_mapper_test.dart`

## Implementation Steps

1. Create `mapFirebaseAuthErrorCode(String code) -> String translationKey` mapping:
   - `invalid-credential` → `auth_error_invalid_credential`
   - `user-disabled` → `auth_error_user_disabled`
   - `user-not-found` → `auth_error_user_not_found`
   - `wrong-password` → `auth_error_wrong_password`
   - `network-request-failed` → `auth_error_network`
   - `too-many-requests` → `auth_error_too_many_requests`
   - `account-exists-with-different-credential` → `auth_error_account_exists_different_credential`
   - `operation-not-allowed` → `auth_error_operation_not_allowed`
   - default → `auth_error_generic`
2. Replace `errorMessage.value = e.message` with `errorMessage.value = mapFirebaseAuthErrorCode(e.code).tr`.
3. Log to Crashlytics using `e.code` only (and sanitized context); never `e.message`.
4. Add every key to both `english-translations-en-us.dart` and `vietnamese-translations-vi-vn.dart`.

## Todo List

- [ ] Create `firebase_auth_error_mapper.dart`
- [ ] Add mapping for all known codes + default
- [ ] Replace `e.message` assignment in `auth_controller.dart`
- [ ] Remove any logging of `e.message`
- [ ] Add keys to en-us translations
- [ ] Add keys to vi-vn translations
- [ ] Unit test: each known code → expected key
- [ ] Unit test: unknown code → `auth_error_generic`
- [ ] Unit test: `e.message` absent from final error surface
- [ ] `flutter analyze` clean

## Success Criteria

- Grep `e\.message` in auth_controller returns zero matches.
- Unit test coverage: all mapped codes + fallback.
- Translation parity: every key present in both locale files (automated test via key-set diff).

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Missing translation key at runtime → raw key shown | Med | Low (cosmetic) | Parity test between locale files |
| New Firebase code not in mapper | Med | Low | Fallback to generic; log code to Crashlytics |
| Double-translation of already-`.tr`d strings | Low | Low | Helper returns key, caller applies `.tr` once |

## Security Considerations

- **Primary driver**: stop leaking OAuth fragments / internal error payloads via UI or crash logs.
- Sanitize Crashlytics payload: code + stack only.
- Do not include email or UID in error messages.

## Next Steps / Dependencies

- Independent — can land in parallel with any other phase.
