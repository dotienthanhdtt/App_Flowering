# Phase 05 — C4 Scoped Cache Invalidation + C5a Seeded Race

## Context Links

- Report: `plans/reports/code-reviewer-260419-2022-feat-update-onboarding-5-commits.md` (C4, C5)
- Code: `lib/core/services/cache-invalidator-service.dart:39-43`

## Overview

- Priority: Critical
- Status: pending
- `box.clear()` nukes ≤100MB on every language toggle (C4).
- `ever()` watcher races on initial emission producing spurious invalidations (C5 seeded-flag fragment).

## Key Insights

- Pref-key prefix rework deferred (decision 5) → scoped deletion requires alternative tracking.
- Options considered:
  - (A) Per-language Hive sub-box (`lessons_cache_en`, `lessons_cache_vi`). Clear whole sub-box for switched-from language. Simple, atomic, KISS.
  - (B) Sidecar index box mapping `lang → Set<key>`. More flexible but two-box consistency risk.
- Pick (A): smaller blast radius, transactional single-box clear, no index drift.
- C5a seeded fix: capture baseline code synchronously BEFORE `ever()` registration; watcher only acts when code changes from captured baseline.

## Requirements

Functional
- Switching language A→B deletes only A's cached entries; C's cache untouched.
- First emission of `activeLanguageCode` after service init does NOT trigger invalidation.
- Large sub-box deletion does not freeze UI (offload or measure to confirm not needed).

Non-functional
- No regression on cold start warming (no unintended deletions).
- Works with current Hive LRU capping (100MB across all sub-boxes acceptable; or allocate proportionally — doc tradeoff).

## Architecture

```
LanguageContextService.activeLanguageCode (Rx)
   │ baseline = read synchronously at service init
   ▼
ever(activeLanguageCode) ─► if current != baseline
                              ├── invalidate(baseline)  ← clear sub-box for prev lang
                              └── baseline = current
```

Sub-box layout
```
Hive:
  lessons_cache_en   (per-lang)
  lessons_cache_vi
  lessons_cache_<code>
```

## Related Code Files

Modify
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/services/cache-invalidator-service.dart`
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/core/services/storage_service.dart` (sub-box open/routing)
- Any caller that reads/writes lessons cache by key (ensure routes to correct sub-box by active lang at call time).

Create
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/test/core/services/cache_invalidator_scoped_test.dart`

## Implementation Steps

1. In `StorageService`, add `Box getLessonsBoxFor(String langCode)` lazy-opening `lessons_cache_$langCode`.
2. Update lesson-cache read/write call sites to route via active lang code (grep for existing `lessons_cache` usage).
3. In `CacheInvalidatorService` constructor: read current `activeLanguageCode` into `_baselineCode` BEFORE registering `ever()`.
4. Replace `box.clear()` with `getLessonsBoxFor(prevCode).clear()`.
5. In `ever()` handler: skip if new == `_baselineCode`; else invalidate `_baselineCode` and assign new to `_baselineCode`.
6. If clear() duration measured >16ms on representative device, wrap in `Future.microtask` or `compute`. Add measurement hook (debug log only).

## Todo List

- [ ] Add per-lang sub-box helper in `StorageService`
- [ ] Migrate lesson-cache callers to per-lang sub-box
- [ ] Capture baseline before `ever()` registration
- [ ] Replace global `box.clear()` with scoped sub-box clear
- [ ] Ensure watcher skips initial no-op emissions
- [ ] Unit test: switch A→B clears A only; C intact
- [ ] Unit test: seeded flag — no invalidation on initial service init
- [ ] Manual smoke: toggle language twice, verify UI cache persists per lang
- [ ] `flutter analyze` clean

## Success Criteria

- Test with 3 seeded sub-boxes (en, vi, fr): switch en→vi clears only en; fr + vi entries intact.
- Test with mock RxString: assigning current value to itself triggers no invalidation.
- No regression in existing cache read path (measured via existing cache tests).

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Miss caller reading wrong sub-box → cache miss storm | Med | Med | Grep coverage; route through single helper |
| Hive multi-box aggregate >100MB | Med | Med | Document proportional split; add dev-mode size log |
| Migration of pre-existing flat cache | Low | Low | On first boot post-upgrade, leave old box; best-effort fall-back read, eventual eviction. Doc tradeoff. |
| Clear() still blocks main thread | Low | Low | Measure; offload only if observed |

## Security Considerations

- No direct. Ensure invalidation on logout still clears ALL sub-boxes (audit logout hook).

## Next Steps / Dependencies

- Phase 6 uses `OnboardingProgressService` which reads progress storage — unrelated box, no conflict.
- Independent of Phases 1-4, 7.
