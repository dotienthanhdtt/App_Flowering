# Phase 06 — Error Handling + Translations

## Context Links

- Brainstorm: [brainstorm-summary.md](brainstorm-summary.md) §Error Code → Translation Key Mapping
- Backend contract: [mobile-adaptation-requirements.md §3](../../../be_flowering/plans/260418-2238-multi-language-content-architecture/mobile-adaptation-requirements.md)
- Backend error sources: `be_flowering/src/common/guards/language-context.guard.ts` (lines 45, 64, 78, 86)
- Referenced files: `lib/core/network/api_exceptions.dart`, `lib/l10n/english-translations-en-us.dart`, `lib/l10n/vietnamese-translations-vi-vn.dart`

## Overview

- **Priority:** P0 (needed before phase 7 recovery can surface user-facing error copy)
- **Status:** pending
- **Description:** Add `LanguageContextError` enum to `api_exceptions.dart`, map backend message patterns → enum → translation keys. Add 4 keys to both l10n files. Never surface backend English to users.

## Key Insights

- Backend throws `BadRequestException` (400) for missing/unknown/required-active-language and `ForbiddenException` (403) for not-enrolled — so `statusCode` alone isn't enough to distinguish cases. Discriminate via server message substring.
- Backend message literals (from guard):
  - `Unknown or inactive language code: "<code>"` → 400 → `unknownCode`
  - `Active learning language required. Send X-Learning-Language header.` → 400 → `headerMissing` (authed)
  - `X-Learning-Language header required for anonymous requests` → 400 → `activeRequired`
  - `Language "<code>" not enrolled for this user` → 403 → `notEnrolled`
- Keep mapping in one place (`api_exceptions.dart`) so phase 7 interceptor + phase 4 chat controller share.
- Translation loader is `lib/l10n/app-translations-loader.dart` — assumes keys exist in both maps; missing key falls back to key literal (ugly in prod).

## Requirements

**Functional:**
- New enum `LanguageContextError { headerMissing, unknownCode, notEnrolled, activeRequired }`.
- New helper `LanguageContextError? detectLanguageContextError(int? statusCode, String? serverMessage)` returning one of the four variants or null.
- New keys in BOTH `english-translations-en-us.dart` and `vietnamese-translations-vi-vn.dart`:
  - `err_language_header_missing`
  - `err_language_unknown`
  - `err_language_not_enrolled`
  - `err_language_required`
- Add `LanguageContextError.translationKey` getter so callers do `e.translationKey.tr`.

**Non-functional:**
- `api_exceptions.dart` stays focused; no other refactor. File currently 173 lines; target < 200.
- Copy reviewed with copy owner before merge (out-of-code coordination).

## Architecture

```
Dio error (DioException)
   │
   ▼
mapDioException(e)  ──► ApiErrorException (status + serverMessage)
   │
   ▼
Caller (interceptor phase 7 or chat controller)
   │
   ▼
detectLanguageContextError(status, serverMessage)
   │
   ├─► headerMissing  → 'err_language_header_missing'.tr
   ├─► unknownCode    → 'err_language_unknown'.tr
   ├─► notEnrolled    → 'err_language_not_enrolled'.tr
   └─► activeRequired → 'err_language_required'.tr
```

## Related Code Files

**MODIFY:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/network/api_exceptions.dart`
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/l10n/english-translations-en-us.dart`
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/l10n/vietnamese-translations-vi-vn.dart`

**CREATE:** none. **DELETE:** none.

## Implementation Steps

1. In `api_exceptions.dart`, append (after existing classes, before `mapDioException`):
   ```dart
   enum LanguageContextError {
     headerMissing,
     unknownCode,
     notEnrolled,
     activeRequired;

     String get translationKey {
       switch (this) {
         case LanguageContextError.headerMissing:  return 'err_language_header_missing';
         case LanguageContextError.unknownCode:    return 'err_language_unknown';
         case LanguageContextError.notEnrolled:    return 'err_language_not_enrolled';
         case LanguageContextError.activeRequired: return 'err_language_required';
       }
     }
   }

   LanguageContextError? detectLanguageContextError(int? statusCode, String? message) {
     if (message == null) return null;
     final m = message.toLowerCase();
     if (statusCode == 403 && m.contains('not enrolled')) return LanguageContextError.notEnrolled;
     if (statusCode == 400) {
       if (m.contains('unknown or inactive language code')) return LanguageContextError.unknownCode;
       if (m.contains('anonymous'))                        return LanguageContextError.activeRequired;
       if (m.contains('active learning language required')) return LanguageContextError.headerMissing;
     }
     return null;
   }
   ```

2. In `english-translations-en-us.dart`, add keys near existing `'unknown_error'`:
   ```dart
   'err_language_header_missing': 'Missing learning language. Please reopen the app.',
   'err_language_unknown':        'That language is no longer supported.',
   'err_language_not_enrolled':   "You haven't enrolled in this language yet.",
   'err_language_required':       'Please pick a learning language to continue.',
   ```

3. In `vietnamese-translations-vi-vn.dart`, add parallel keys (placeholder copy — coordinate with copy owner):
   ```dart
   'err_language_header_missing': 'Thiếu ngôn ngữ học. Vui lòng mở lại ứng dụng.',
   'err_language_unknown':        'Ngôn ngữ này không còn được hỗ trợ.',
   'err_language_not_enrolled':   'Bạn chưa đăng ký ngôn ngữ này.',
   'err_language_required':       'Vui lòng chọn một ngôn ngữ để tiếp tục.',
   ```

4. Ensure loader picks them up — `app-translations-loader.dart` is just a map merge, so no change needed.

5. `flutter analyze` clean.

## Todo List

- [ ] Add `LanguageContextError` enum + `translationKey` getter
- [ ] Add `detectLanguageContextError()` helper
- [ ] Add 4 EN keys
- [ ] Add 4 VI keys (coordinate final copy)
- [ ] Unit test: each backend message literal maps to correct enum variant (phase 9)
- [ ] `flutter analyze` clean

## Success Criteria

- [ ] `detectLanguageContextError(400, 'Unknown or inactive language code: "xy"')` → `unknownCode`.
- [ ] `detectLanguageContextError(403, 'Language "en" not enrolled for this user')` → `notEnrolled`.
- [ ] All 4 keys render localized copy (no fallback to key literal).

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Backend changes error message wording post-deploy | Medium | Brittle substring match; mitigate by defining patterns in one place + adding unit tests tied to the guard's message literals. Re-verify after backend deploy. |
| VI copy incorrect before review | Low | Placeholder copy flagged in PR description for translator review. |

## Security Considerations

- No PII in error messages (language codes only).

## Next Steps

- Unblocks phase 7 interceptor (uses enum for 403 recovery routing + surfacing user-facing copy).
- Unblocks phase 4 defensive pre-check copy.
