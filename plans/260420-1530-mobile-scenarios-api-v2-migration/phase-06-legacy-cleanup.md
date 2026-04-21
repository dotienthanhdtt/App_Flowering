# Phase 06 — Legacy Cleanup

## Context Links

- Old endpoint constant: `lib/core/constants/api_endpoints.dart:40`
- Old models: `lib/features/lessons/models/lesson-models.dart`
- Old card: `lib/features/lessons/widgets/scenario-card.dart`
- Old controller fields: `lib/features/chat/controllers/chat-home-controller.dart` (categories, fetchLessons, _mergeCategories, _currentPage, _hasMore, refreshLessons, totalScenarios)
- Old screen helpers: `lib/features/chat/views/chat-home-screen.dart` (_buildEmptyState, _buildCategorySection, _buildCategoryHeader, etc. — any dead after phase 4)

## Overview

- **Priority:** P1
- **Status:** completed
- **Brief:** Delete everything dead after phases 4/5 land. No functional change — purely subtractive. Verify via grep + analyzer.

## Key Insights

- Safer to delete in one focused phase than trickle-clean during feature phases. Easier to review diff, easier to revert if something breaks.
- `ChatHomeController` loses its body responsibility but keeps language/tab-level state. Rename for clarity if file feels misleading — **decision: leave name; renames are expensive to review**.
- The `lessons` feature dir still contains `read-binding.dart`, `bindings/`, and a nested structure. Check if anything else uses `/lessons` endpoint before wholesale deletion.

## Requirements

### Functional

- Remove from `api_endpoints.dart`:
  - `static const String lessons = '/lessons';`
  - `static String lessonDetail(String id) => '/lessons/$id';` — IF unused anywhere.
- Delete files:
  - `lib/features/lessons/models/lesson-models.dart` (all classes: LessonScenario, LessonCategory, LessonPagination, GetLessonsResponse)
  - `lib/features/lessons/widgets/scenario-card.dart`
- Verify + delete (if unused):
  - `lib/features/lessons/bindings/read-binding.dart` — investigate usage
  - `lib/features/lessons/controllers/`, `views/` if now empty
- Remove from `chat-home-controller.dart`:
  - `categories` RxList, `_currentPage`, `_hasMore`, `isRefreshing`, `totalScenarios` getter
  - `fetchLessons()`, `_mergeCategories()`, `refreshLessons()`
  - Imports of `lesson-models.dart`
- Remove from `chat-home-screen.dart`:
  - `_buildBody(controller)` old implementation
  - `_buildEmptyState`, `_buildCategorySection`, any `_buildCategoryHeader` etc.
  - Imports of `LessonCategory`, `LessonScenario`, `ScenarioCard` (from lessons/)
- Grep-verify zero hits for:
  - `is_premium` in `lib/`
  - `is_trial` in `lib/`
  - `is_active` in `lib/`
  - `'trial'` in `lib/features/` (scenario context only — unrelated `trial` matches in subscription code OK, audit manually)
  - `GetLessonsResponse` in `lib/` + `test/`
  - `ApiEndpoints.lessons` in `lib/` + `test/`

### Non-Functional

- No behavior change. Users see same Home tabs as after phase 4.
- `flutter analyze` must be clean post-cleanup.
- `flutter test` all green (phase 7 writes new tests; this phase doesn't break existing ones).

## Related Code Files

**Delete:**
- `lib/features/lessons/models/lesson-models.dart`
- `lib/features/lessons/widgets/scenario-card.dart`
- Any other files in `lib/features/lessons/` confirmed dead (investigate case-by-case).

**Modify:**
- `lib/core/constants/api_endpoints.dart` — remove `lessons` + `lessonDetail`.
- `lib/features/chat/controllers/chat-home-controller.dart` — strip lessons-related fields + methods.
- `lib/features/chat/views/chat-home-screen.dart` — strip dead helpers + unused imports.
- `lib/features/chat/bindings/chat-home-binding.dart` — drop `LessonsBinding` if referenced.

## Implementation Steps

1. Grep for all usages before deleting:
   ```bash
   grep -rn "ApiEndpoints.lessons" lib/ test/
   grep -rn "GetLessonsResponse" lib/ test/
   grep -rn "LessonCategory\|LessonScenario\|LessonPagination" lib/ test/
   grep -rn "lessons/widgets/scenario-card" lib/
   grep -rn "is_premium\|is_trial\|is_active" lib/
   grep -rn "'trial'" lib/features/
   ```
2. For each hit, either migrate to new feature or remove alongside.
3. Delete dead files via `rm` (preserve git history; file-level deletes are easy to revert).
4. Strip dead methods from `chat-home-controller.dart` and `chat-home-screen.dart`.
5. Remove endpoint constants.
6. Run `flutter analyze` — must be clean.
7. Run `flutter test` — must pass (may skip tests that referenced deleted types; phase 7 adds replacements).

## Todo List

- [x] Grep audit for all 6 dead patterns
- [x] Delete `lesson-models.dart`
- [x] Delete old `lessons/widgets/scenario-card.dart`
- [x] Strip dead methods/fields from `chat-home-controller.dart`
- [x] Strip dead helpers from `chat-home-screen.dart` (full rewrite to TabBar layout)
- [x] Remove `lessons` + `lessonDetail` from `api_endpoints.dart`
- [x] Investigate `lib/features/lessons/bindings/read-binding.dart` — **retained**: still used by Read tab (`ReadController` is an active placeholder registered in `MainShellBinding`; not lessons-related)
- [x] `flutter analyze` clean
- [x] `flutter test` green on scenario tests; pre-existing `widget_test.dart` + `ai_chat_binding_cold_resume_test.dart` failures verified unrelated

## Success Criteria

- Zero grep hits for `is_premium`, `is_trial`, `is_active`, `'trial'` (outside subscription context), `GetLessonsResponse`, `ApiEndpoints.lessons` in `lib/` and `test/`.
- `lib/features/lessons/` either gone or contains only files still legitimately used (e.g. if a `read-binding.dart` serves another purpose).
- `flutter analyze` clean.
- `flutter test` all green.
- Home behavior unchanged from post-phase-4 state.

## Risk Assessment

- **Hidden callers** — `ApiEndpoints.lessons` may be referenced in places grep misses (string concatenation, reflection — unlikely in Flutter but possible). Trust the analyzer.
- **Test file breakage** — any test importing deleted types fails at compile. Delete/rewrite those tests; don't comment out.
- **`ChatHomeController` rename temptation** — resist. Renames produce churn; keep name.

## Security Considerations

- None — deletion only.

## Next Steps

- Phase 7 adds new tests + translation keys.
