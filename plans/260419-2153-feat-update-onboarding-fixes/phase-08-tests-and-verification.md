# Phase 08 — Tests & Verification Pass

## Context Links

- Per-phase tests enumerated in phase files 01-07
- Reports: see plan.md

## Overview

- Priority: Critical (gate for merge)
- Status: pending
- Consolidated run of all added tests + end-to-end smoke after phases 1-7 land.

## Key Insights

- Each phase adds its own tests (unit). This phase = integration smoke + full-suite green + analyze.
- Manual smoke sequences validate cross-phase interactions (e.g. auth refresh during language switch).

## Requirements

Functional
- All new unit tests pass.
- Full `flutter test` green.
- Manual smoke matrix completes without regression.

Non-functional
- No flake >1/20 runs for concurrency tests.
- `flutter analyze` returns zero issues.

## Related Code Files

Modify
- None (verification phase).

Create
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/test/integration/onboarding_fixes_smoke_test.dart` (optional integration test if harness permits)

## Implementation Steps

1. Run `flutter pub get` fresh.
2. Run `flutter analyze` — expect clean.
3. Run `flutter test` — expect green.
4. Execute concurrency tests (auth refresh + language recovery) 20 iterations each; no flake.
5. Manual smoke matrix:
   - Login A → logout → login B → no stale onboarding state (Phase 6).
   - Toggle language en→vi→en; chat history cached per lang (Phase 5).
   - Force 401 while 3 chat requests in flight → single refresh (Phase 1).
   - Force 403 during language switch → single resync, requests retry (Phase 3/4).
   - `/onboarding/complete` hits backend successfully from both call sites (Phase 2).
   - Trigger `invalid-credential` auth error → UI shows translated message, no token fragment (Phase 7).
6. Capture results in report file under `plans/reports/`.

## Todo List

- [ ] `flutter pub get`
- [ ] `flutter analyze` clean
- [ ] `flutter test` full suite green
- [ ] Concurrency tests x20 no flake
- [ ] Manual smoke matrix executed
- [ ] Smoke report filed to `plans/reports/`

## Success Criteria

- Analyze: 0 issues.
- Tests: 0 failures, 0 flakes in 20-run concurrency loop.
- Smoke matrix: all 6 scenarios pass.
- No regression logged against existing features.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Cross-phase interaction bug (e.g. interceptor ordering) | Med | High | Smoke matrix explicitly exercises ordering |
| Flaky concurrency test | Med | Med | 20-iter loop; add explicit awaits over `Future.delayed` |
| Missing regression coverage for I-tier issues | Low | Low | Documented out of scope; future work |

## Security Considerations

- Verify no token, email, or OAuth fragment appears in any captured log (Crashlytics, console, smoke notes).

## Next Steps / Dependencies

- Depends on Phases 1-7 landed.
- On green: PR merge-ready.
