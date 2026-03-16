# QA Report — Foundation: Routes, Models, Translations
**Date:** 2026-02-28
**Branch:** feat/onboarding-first-half
**Plan task:** #1 — Setup foundation

---

## Test Results Overview

| Suite | Total | Pass | Fail | Skip |
|---|---|---|---|---|
| widget_test.dart | 5 | 5 | 0 | 0 |
| app-route-constants-validation-test.dart | 3 | 3 | 0 | 0 |
| app-page-definitions-configuration-test.dart | 11 | 11 | 0 | 0 |
| navigation-between-placeholder-screens-test.dart | 11 | **10** | **1** | 0 |
| app-translations-structure-test.dart | 16 | 16 | 0 | 0 |
| getx-translations-runtime-loading-test.dart | 7 | 7 | 0 | 0 |
| global-dependency-injection-registration-test.dart | 4 | 4 | 0 | 0 |
| **TOTAL** | **57** | **56** | **1** | **0** |

**Overall: 56/57 — 1 FAILURE**

---

## Failed Tests — Detail

### `navigation-between-placeholder-screens-test.dart`

**Test:** `Navigation Between Placeholder Screens > can navigate to chat screen`
**File:** `test/app/routes/navigation-between-placeholder-screens-test.dart:53`

**Error:**
```
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Chat - Coming Soon": []>
```

**Root cause:**
The `/chat` route in `app-page-definitions-with-transitions.dart` was upgraded from `_PlaceholderScreen('Chat')` to the real `AiChatScreen()` widget (part of this task's implementation). The test still expects placeholder text `"Chat - Coming Soon"`.

The test is not broken — it accurately reflects reality: the `chat` route now renders real UI, not a placeholder.

**What changed:**
- Before: `page: () => const _PlaceholderScreen('Chat')`
- After: `page: () => const AiChatScreen()` with `binding: AiChatBinding()`

---

## Static Analysis (`flutter analyze`)

- **Errors:** 0
- **Warnings:** 3 (all `unused_import` in test files — cosmetic)
- **Info:** 13 (all `file_names` — project uses kebab-case by convention, accepted)

No blocking issues.

---

## Build Status

No compilation errors. `flutter analyze` exits cleanly on lib/ sources. The `objective_c` native hook write-timeout encountered on first run was transient (resolved by clearing `.dart_tool/hooks_runner/` cache).

---

## Test Discovery Issue (Pre-existing)

`flutter test` without arguments only discovers `test/widget_test.dart` (the only file with `_test.dart` suffix). All other test files use kebab-case `-test.dart` suffix per project conventions, which Flutter's default test runner does not auto-discover.

**Impact:** Running bare `flutter test` gives a false "all pass" signal since 52 of 57 tests are silently skipped.
**Workaround used:** Explicit file paths passed to `flutter test`.

---

## Route Constants — Verified New Routes

All 5 new constants are present and unique in `app-route-constants.dart`:
- `onboardingScenarioGift = '/onboarding/scenario-gift'` ✓
- `signup = '/signup'` ✓
- `forgotPassword = '/forgot-password'` ✓
- `otpVerification = '/otp-verification'` ✓
- `newPassword = '/new-password'` ✓

All 5 have corresponding `GetPage` entries in `app-page-definitions-with-transitions.dart`.
No duplicate route names (confirmed by test + manual review).

---

## Translation Coverage — Verified

- `both locales have same keys` test: **PASS**
- `no empty translation values` test: **PASS**
- EN/VI key counts: EN=122, VI=122 (after accounting for nested map structure)
- All category key tests passed: common, auth, validation, navigation, error

---

## Recommendations

1. **Fix failing test** (blocking): Update `navigation-between-placeholder-screens-test.dart:42-54` — the `can navigate to chat screen` test should check for something present in `AiChatScreen` (e.g., `ChatTopBar`) instead of placeholder text. The placeholder is gone by design.

2. **Test discovery** (non-blocking, pre-existing): Add a `dart_test.yaml` at project root or rename test files to `_test.dart` suffix so `flutter test` discovers all tests. Currently CI would miss 52 tests unless run with explicit paths.

3. **Unused imports in test files** (cosmetic):
   - `test/app/routes/navigation-between-placeholder-screens-test.dart:1` — `package:flutter/material.dart` unused
   - `test/l10n/getx-translations-runtime-loading-test.dart:5,6` — `english-translations-en-us.dart` and `vietnamese-translations-vi-vn.dart` unused (tests use `AppTranslations()` directly)

---

## Unresolved Questions

- Should `dart_test.yaml` be added to enable auto-discovery of all test files? Or is explicit path invocation the intended CI command?
- The `OnboardingBinding` change from `lazyPut` to `permanent: true` with guard: no test currently validates binding permanence — acceptable for now, but worth noting for future.
