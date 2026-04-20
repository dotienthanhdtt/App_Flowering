# Phase 02 — Integration (ChatHomeScreen + Controller)

## Context Links

- Phase 01 widgets: `home-language-button.dart`, `language-picker-sheet.dart`.
- Screen: `lib/features/chat/views/chat-home-screen.dart` (lines 34–82 = header to replace).
- Controller: `lib/features/chat/controllers/chat-home-controller.dart`.
- Service: `lib/core/services/language-context-service.dart` (methods: `activeCode`, `activeId`, `setActive`, `resyncFromServer`).
- Network: `lib/core/network/active-language-interceptor.dart` (auto-attaches header — **no change needed**).
- Endpoint: `/languages/user` (via `ApiEndpoints.userLanguages`).

## Overview

- **Priority:** High.
- **Status:** Pending.
- **Brief:** Swap the current header in `ChatHomeScreen`, introduce a small header row matching the design. Wire the controller to fetch enrolled languages on demand, handle switches, and refetch lessons.

## Key Insights

- `ActiveLanguageInterceptor` already reads `LanguageContextService.activeCode` and attaches the `X-Learning-Language` header on every non-meta request. Switching languages just needs `setActive(...)` → subsequent API calls will carry the new header automatically.
- `ChatHomeController.fetchLessons` already reads the active code at call time; calling `fetchLessons(refresh: true)` after the switch is enough to repopulate the list.
- Cache invalidator (`CacheInvalidatorService`) may need a ping on language switch — check at integration time; if it already hooks off `LanguageContextService`, no action needed.

## Requirements

### Functional

- Header row (replaces lines 34–82 of `chat-home-screen.dart`): left = `HomeLanguageButton`, right = `SizedBox(width: 40)` placeholder (or keep the search button, see Open Questions).
- Controller:
  - `Rx<OnboardingLanguage?> activeLanguage` computed from the enrolled list + `LanguageContextService.activeCode`.
  - `RxList<OnboardingLanguage> enrolledLanguages`.
  - `Future<void> loadEnrolledLanguages()` — GETs `/languages/user`, hydrates `enrolledLanguages` and derives `activeLanguage`.
  - `Future<void> switchActiveLanguage(OnboardingLanguage next)` — calls `LanguageContextService.setActive(next.code, next.id)`, then `fetchLessons(refresh: true)`.
- Screen wires the button's `onTap` to:
  1. Ensure enrolled languages are loaded (lazy on first open).
  2. Show `LanguagePickerSheet` with the current list and active code.
  3. On select → `controller.switchActiveLanguage(lang)`.

### Non-Functional

- No regression of existing scenario grid, pull-to-refresh, or pagination.
- All user-facing strings go through `.tr`.
- Header height ≤ 56 (matches design `TJOsb` height).

## Architecture

```
ChatHomeScreen
├── Header (new)
│   └── HomeLanguageButton(active: controller.activeLanguage.value)
│         onTap → controller.ensureLanguagesLoaded()
│                 → showLanguagePickerSheet(...)
│                   onSelect: controller.switchActiveLanguage(lang)
└── Body (unchanged) — category list / scenario grid
```

Data flow on switch:
```
User taps language
  → controller.switchActiveLanguage
      → LanguageContextService.setActive(code, id)   // persists + updates Rx
      → fetchLessons(refresh: true)                   // interceptor attaches new X-Learning-Language
```

## Related Code Files

**Modify:**
- `lib/features/chat/views/chat-home-screen.dart` — replace `_buildHeader`, `_buildCountBadge`, `_buildSearchButton` with header row using `HomeLanguageButton`.
- `lib/features/chat/controllers/chat-home-controller.dart` — add `enrolledLanguages`, `activeLanguage`, `loadEnrolledLanguages`, `switchActiveLanguage`.

**No change:**
- `lib/core/services/language-context-service.dart`.
- `lib/core/network/active-language-interceptor.dart`.
- `lib/features/lessons/widgets/scenario-card.dart`.
- `lib/features/home/views/main-shell-screen.dart`, `lib/features/home/widgets/bottom-nav-bar.dart`.

## Implementation Steps

1. **Controller additions** (keep file ≤200 lines; if exceeded, extract language helpers to a small service class).
   ```dart
   final enrolledLanguages = <OnboardingLanguage>[].obs;
   final Rx<OnboardingLanguage?> activeLanguage = Rx<OnboardingLanguage?>(null);
   bool _enrolledLoaded = false;

   Future<void> loadEnrolledLanguages({bool force = false}) async {
     if (_enrolledLoaded && !force) return;
     // GET /languages/user → parse via OnboardingLanguage.fromJson()
     // hydrate enrolledLanguages + derive activeLanguage from _langCtx.activeCode
     _enrolledLoaded = true;
   }

   Future<void> switchActiveLanguage(OnboardingLanguage next) async {
     if (next.code == _langCtx.activeCode.value) return;
     await _langCtx.setActive(next.code, next.id);
     activeLanguage.value = next;
     await fetchLessons(refresh: true);
   }
   ```
2. **onInit**: after `fetchLessons()`, fire-and-forget `loadEnrolledLanguages()` so the flag flips to the real one when the response lands.
3. **Listen** to `_langCtx.activeCode` via `ever(_langCtx.activeCode, (code) => _syncActiveLanguage(code))` so external changes (e.g. from settings) stay in sync.
4. **Screen edits**:
   - Replace current `_buildHeader` with a new `_buildHeader(controller)` that returns the 56px row with horizontal padding 20.
   - Wrap left side with `Obx(() => HomeLanguageButton(active: controller.activeLanguage.value, onTap: ...))`.
   - Right side: placeholder 40×40 (for future streak); revisit later.
   - On tap: `await controller.loadEnrolledLanguages(); showLanguagePickerSheet(context, languages: controller.enrolledLanguages.toList(), activeCode: controller.activeLanguage.value?.code, onSelect: controller.switchActiveLanguage);`.
5. **Delete** unused helpers (`_buildCountBadge`, `_buildSearchButton`) and their imports if nothing else references them.
6. **Run**: `flutter analyze` on both files; fix any warnings.

## Todo List

- [ ] Add `enrolledLanguages`, `activeLanguage`, `loadEnrolledLanguages`, `switchActiveLanguage` to controller.
- [ ] Hook `ever(_langCtx.activeCode, ...)` for external sync.
- [ ] Replace `_buildHeader` in `chat-home-screen.dart`.
- [ ] Remove now-dead helpers (`_buildCountBadge`, `_buildSearchButton`, unused imports).
- [ ] Verify `flutter analyze` clean.
- [ ] Manual device test: switch language → lessons refetch → logger shows new `X-Learning-Language`.

## Success Criteria

- Header matches `get_screenshot('4xVNl')` left-aligned flag+chevron (streak omitted per scope).
- Tapping the flag opens picker; selecting a different language:
  1. Updates `LanguageContextService.activeCode` (verify via another observer if needed).
  2. Triggers `fetchLessons(refresh: true)`.
  3. Next `/lessons` request carries the new `X-Learning-Language` header (check `HttpLoggerInterceptor` output).
- Existing scenario grid, pull-to-refresh, and pagination continue to work.

## Risk Assessment

- **Empty enrollments** (new user shouldn't hit Home, but defensive): picker shows a single-line empty state `'no_languages_enrolled'.tr`.
- **Controller file > 200 lines** after additions: if so, extract helpers into `chat_home_language_controller_ext.dart` as a mixin to stay within project file-size rule.
- **Cache invalidation**: if switching language leaves stale cached lessons visible briefly, this is acceptable — `fetchLessons(refresh: true)` will atomically replace via `assignAll`.

## Security Considerations

- Language code is already sanitized by the server on enrollment; trust the ID/code pair from `/languages/user`.
- No PII added to logs.

## Next Steps

- Phase-03: translations, widget tests, and final validation.
