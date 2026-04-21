# Phase 03 — Translations, Tests, Analyze

## Context Links

- `lib/l10n/english-translations-en-us.dart`
- `lib/l10n/vietnamese-translations-vi-vn.dart`
- Existing test patterns: any `test/features/chat/*` tests.

## Overview

- **Priority:** Medium.
- **Status:** Pending.
- **Brief:** Finalize with localizations, widget tests, and static-analysis / test-suite verification.

## Requirements

### Translations (both en-us + vi-vn)

- `language_picker_title` → "Learning language" / "Ngôn ngữ học"
- `language_picker_empty` → "No languages yet. Add one from settings." / "Chưa có ngôn ngữ. Thêm trong phần cài đặt."
- `language_picker_close` → "Close" / "Đóng" (for accessibility label)

### Tests

- `test/features/chat/widgets/home-language-button_test.dart`:
  - Renders placeholder icon when `active` is null.
  - Renders `LanguageFlag` when `active` is non-null.
  - Emits `onTap` callback on tap.
- `test/features/chat/widgets/language-picker-sheet_test.dart`:
  - Renders a row per language.
  - Active row shows check icon; others show chevron.
  - Taps emit `onSelect` with correct language and dismiss the sheet.
- `test/features/chat/controllers/chat-home-controller_test.dart` (extend if exists, else create):
  - `switchActiveLanguage` calls `LanguageContextService.setActive` then `fetchLessons(refresh: true)`.
  - `loadEnrolledLanguages` hydrates list only once unless `force: true`.

Use `Get.put` with mocks for `ApiClient`, `LanguageContextService`, and `StorageService`. No real HTTP.

## Implementation Steps

1. Add the three translation keys to both l10n maps.
2. Write widget tests in `flowering/test/features/chat/widgets/` using `flutter_test` + `get`.
3. Write / extend controller test using `mockito` (already a dev dep per pubspec).
4. Run:
   ```bash
   cd app_flowering/flowering
   flutter analyze
   flutter test test/features/chat/
   ```
5. Only mark phase complete when analyze is clean AND new tests pass AND full `flutter test` suite passes (do not ignore unrelated failures — triage).

## Todo List

- [ ] Add translation keys (en + vi).
- [ ] Widget test: `home-language-button_test.dart`.
- [ ] Widget test: `language-picker-sheet_test.dart`.
- [ ] Controller test: extend `chat-home-controller_test.dart` (or create).
- [ ] `flutter analyze` clean.
- [ ] `flutter test` all green.

## Success Criteria

- All tests green.
- Static analysis clean on all modified / created files.
- Translation keys present in both l10n files (no missing-key fallback at runtime).

## Risk Assessment

- **Controller tests flaky around Get singletons:** use `Get.testMode = true` + `Get.reset()` in `setUp`/`tearDown`.

## Security Considerations

- None.

## Next Steps

- Hand off to `code-reviewer` agent per primary-workflow.md.
- If review passes, update `docs/project-changelog.md` with a brief entry: *"feat(home): language switcher in header — picks X-Learning-Language."*.
