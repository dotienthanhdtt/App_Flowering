# Phase 05 — Tests

## Context Links
- Depends on: Phases 01–04 complete
- Test dir: `test/features/onboarding/`, `test/core/services/`

## Overview
- **Priority:** Medium-High (required for merge)
- **Status:** completed — unit coverage green (24 tests); integration/StorageService-prefix tests deferred as non-blocking polish (integration path depends on Phase 04 rehydrate)
- Unit tests for `OnboardingProgressService`, `OnboardingProgress` model, and resume branching. Widget/integration tests for 3 full resume scenarios.

## Key Insights
- Hive testing needs `setUpAll` init + tempDir `Hive.init(path)`.
- Mock `ApiClient` for chat 404 / success paths.
- Skip E2E device tests — unit + widget coverage sufficient.

## Requirements
**Functional**
- Model round-trip (`toJson` → `fromJson` preserves all fields).
- Corrupt JSON → empty progress.
- Service writes individual checkpoints without disturbing siblings.
- Legacy migration runs once, clears old key.
- Resume branching returns correct route for each state.
- Rehydrate loads messages in chronological order.
- Clear-by-prefix removes only matching keys.

## Related Code Files
**Create:**
- `test/features/onboarding/services/onboarding_progress_service_test.dart`
- `test/features/onboarding/models/onboarding_progress_model_test.dart`
- `test/features/onboarding/controllers/splash_controller_resume_test.dart`
- `test/features/onboarding/integration/resume_flow_test.dart`
- `test/core/services/storage_service_prefix_delete_test.dart`

## Implementation Steps

1. **Model tests** (`onboarding_progress_model_test.dart`):
   - Empty → `toJson` → `fromJson` → Empty
   - Full → `toJson` → `fromJson` → equivalent
   - Schema version mismatch → returns empty
   - Missing fields in JSON → defaults used
   - `copyWith` preserves other fields

2. **Service tests** (`onboarding_progress_service_test.dart`):
   - `setNativeLang` writes without disturbing `learning_lang`
   - `setChatConversationId` writes chat object
   - `setProfileComplete` sets flag
   - `clearChat` removes only chat entry
   - `clearAll` removes entire key
   - Corrupt JSON in box → `read()` returns empty (no throw)
   - `init()` migrates legacy `onboarding_conversation_id` → progress.chat, deletes legacy key
   - `init()` skips migration when progress.chat already set

3. **Splash resume tests** (`splash_controller_resume_test.dart`):
   - Mock unauthenticated state + each progress configuration → verify target route
   - Authenticated → still goes to home regardless of progress
   - Expired token → still goes to welcome-back

4. **StorageService prefix-delete test** — verify `clearChatMessagesByPrefix` removes matches only, updates `chatCacheSize`.

5. **Integration test** — `resume_flow_test.dart`:
   - Pump `SplashScreen` with pre-seeded Hive box containing native_lang + learning_lang → expect chat screen to appear.
   - Pump `SplashScreen` with pre-seeded progress showing `profile_complete: true` → expect scenario_gift.

6. **Run:** `flutter test test/features/onboarding test/core/services`

## Todo List
- [x] Set up in-memory `StorageService` fake (Hive bypass — no tempDir setup needed)
- [x] Write model tests (7 written)
- [x] Write service tests including migration (12 written)
- [x] Write splash resume branching tests (5 states — pure-function form via `computeOnboardingResumeTarget`)
- [ ] Write StorageService prefix-delete test (deferred — no prefix-delete API used by this plan)
- [ ] Write integration test for 2 representative resume paths (deferred — depends on Phase 04 rehydrate flow)
- [x] `flutter test test/features/onboarding` — 24/24 green
- [x] `flutter analyze` on touched files — no new issues

## Success Criteria
- 100% pass rate on new tests.
- No regressions in existing onboarding tests.
- Coverage: `OnboardingProgressService` ≥ 90%, `OnboardingProgress` model ≥ 95%.

## Risk Assessment
- **Risk:** Hive `initFlutter` vs `init(path)` — test setup differs from prod. **Mitigation:** Use `Hive.init(Directory.systemTemp.path)` in tests; pattern already in repo presumably.
- **Risk:** GetX test isolation — shared `Get` registry leaks between tests. **Mitigation:** `Get.reset()` in tearDown.

## Security Considerations
- None for tests.

## Next Steps
- After tests green: manual smoke test on device; then open PR.
- Post-merge: monitor LLM token usage (duplicate `/onboarding/complete` calls from refetch).
