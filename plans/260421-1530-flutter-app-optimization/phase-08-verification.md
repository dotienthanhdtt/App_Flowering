# Phase 08 — Verification & Sign-Off

## Overview
- **Priority:** P1 (gate)
- **Status:** pending
- **Effort:** ~2h

End-to-end verification across analyze, tests, manual smoke. Document results and update project docs.

## Requirements
- All phases merged sequentially onto the branch.
- `flutter analyze` clean.
- `flutter test` green.
- Manual smoke on critical paths.

## Related Code Files

**Modify (docs)**
- `docs/project-changelog.md` — add entry summarizing optimizations
- `docs/development-roadmap.md` — mark optimization milestone
- `docs/system-architecture.md` — only if Phase 05 deferred-init changed service init story materially

## Implementation Steps

### A. Static analysis
1. `cd app_flowering/flowering && flutter analyze` — must be 0 issues.
2. `find lib -name "*.dart" -exec wc -l {} + | awk '$1 > 200 {print $1, $2}'` — only l10n files allowed.

### B. Unit tests
1. `flutter test` — all green.
2. If any test expected a behavior changed by this plan (e.g., retry on POST), update the test to reflect new expectation (NOT loosen).

### C. Manual smoke (in order)
1. Cold start on real device or simulator — measure time-to-first-frame (stopwatch is fine).
2. Splash routes correctly (logged in → home; logged out → onboarding welcome).
3. Onboarding: select native, select learning, chat session starts, send 2 messages, receive AI + grammar correction, translate a word.
4. Back-nav mid-chat-request: ensure no crash, no stale state.
5. Home: tap Flowering tab — feed loads. Tap For You tab — feed loads. Swipe back → feed restores from cache (< 60s).
6. Switch active language from settings/picker → feeds refresh.
7. Open paywall → offerings appear → close.
8. Login/logout cycle: sign in with email → logout → sign back in → state resets cleanly.
9. Airplane mode: verify connectivity banner surfaces; re-enable → feeds refresh.
10. Background/foreground: backgrounds app during chat → foreground → chat still functional.

### D. Docs sync
1. Append to `project-changelog.md`:
   - Quick wins: token cache, image cache, retry safety
   - Rebuild optimizations
   - File splits (list of files)
   - Memory: cancellation + Hive box LRU
   - Startup: deferred init
   - Network: cache + jitter + single-flight grammar
2. Update `development-roadmap.md` with the optimization milestone marked complete.

## Todo List
- [ ] `flutter analyze` — 0 issues
- [ ] All files under 200 lines (except l10n)
- [ ] `flutter test` green
- [ ] Cold start manual timing recorded (before/after)
- [ ] Auth flow smoke
- [ ] Onboarding → chat flow smoke
- [ ] Feed + language switch smoke
- [ ] Paywall smoke
- [ ] Offline/online transition smoke
- [ ] Background/foreground smoke
- [ ] `project-changelog.md` updated
- [ ] `development-roadmap.md` updated
- [ ] PR opened with summary linking all phases

## Success Criteria
- All checks pass.
- Cold start subjectively faster than baseline.
- No user-visible behavior regressions.
- Docs reflect changes.

## Risk Assessment
- **Risk**: a regression slips past smoke. Mitigation: each phase should have been smoke-tested individually before reaching this phase.
- **Risk**: test suite lacks coverage for retry/cancellation paths. Mitigation: add minimal tests for cancellation + retry-method-filter; skip if they require extensive mocking.

## Security Considerations
- Re-verify no token is logged (http_logger redaction still in place).
- Re-verify auth storage cache does not leak across users (logout clears).

## Next Steps
- Merge to main; open follow-up issues for:
  - Empirical startup timing profiler (flutter devtools).
  - Optional: migrate `messages.refresh()` to per-message observables (Phase 02 Option B, not included).
  - Optional: extend `AppButton` with icon slot if not done in Phase 07.
