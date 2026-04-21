---
title: "Mobile Scenarios API v2 Migration"
description: "Swap /lessons → /scenarios/default, add /scenarios/personal (For You feed), restructure Home into two top tabs, adopt new access_tier/status/type fields. V1 excludes redeem UI and roles[]."
status: completed
completed: 2026-04-20
priority: P0
effort: 16h
branch: feat/scenarios-api-v2
tags: [mobile, scenarios, api-migration, home, getx]
created: 2026-04-20
brainstorm: ../reports/brainstorm-260420-1100-mobile-api-v2-migration.md
blockedBy: []
blocks: []
supersedes: [260420-1440-home-language-switcher]
---

# Mobile Scenarios API v2 Migration

## Summary

Backend shipped breaking contract changes on lessons/scenarios (see brainstorm report). Mobile adopts new fields (`access_tier`, computed `status`, `type`), swaps `/lessons` → `/scenarios/default`, wires `/scenarios/personal`, and restructures the Home first tab into two top tabs ("For You" | "Flowering"). Existing language flag switcher stays in header above the tabs. V1 explicitly excludes `/scenarios/redeem` UI, `roles[]` on UserModel, and the 403 interceptor is left untouched (still defensive for strict endpoints).

Decision log: see brainstorm §9. All architectural choices already locked.

## Phases

| # | Phase | Status | Effort | File |
|---|-------|--------|--------|------|
| 1 | Models + API endpoints (additive) | completed | 2h | [phase-01](phase-01-models-and-endpoints.md) |
| 2 | ScenariosService + feed DTOs | completed | 1.5h | [phase-02-service-layer.md](phase-02-service-layer.md) |
| 3 | Feed controllers (Flowering + For You) | completed | 2h | [phase-03-feed-controllers.md](phase-03-feed-controllers.md) |
| 4 | Home top-tabs restructure | completed | 3h | [phase-04-home-top-tabs.md](phase-04-home-top-tabs.md) |
| 5 | Card rendering (access_tier badges, drop trial) | completed | 2h | [phase-05-card-rendering.md](phase-05-card-rendering.md) |
| 6 | Cleanup — drop /lessons + dead fields | completed | 1.5h | [phase-06-legacy-cleanup.md](phase-06-legacy-cleanup.md) |
| 7 | Translations, tests, analyze | completed | 4h | [phase-07-tests-and-l10n.md](phase-07-tests-and-l10n.md) |

## Phase Dependency Graph

```
1 ──► 2 ──► 3 ──► 4 ──► 5 ──► 6 ──► 7
                  ▲             │
                  └── card tests ─┘
```

Phase 5 can start in parallel with phase 4 once phase 3 lands — both consume new models.

## Key Dependencies

- Backend `/scenarios/default`, `/scenarios/personal` deployed at least to dev/staging before phase 2 E2E.
- `LanguageContextService` + `ActiveLanguageInterceptor` — already present (attaches `X-Learning-Language` automatically).
- `HomeLanguageButton` + `LanguagePickerSheet` — already shipped via superseded plan `260420-1440-home-language-switcher`. Phase 4 integrates them into new top-tabs scaffold.
- No new packages. No Hive schema migration (scenarios not cached locally).

## Explicit Non-Goals (V1)

- **No gift-code redeem UI.** `/scenarios/redeem` not wired. `For You` still supports `source: "kol"` items (visibility via admin grant).
- **No `roles[]` field on `UserModel`.** Not exposed by mobile endpoints.
- **No changes to `language-recovery-interceptor`.** Still defensive for `/scenario/chat`, `/ai/*`, `/progress`.
- **No category grouping.** Flowering tab is flat infinite-scroll grid.
- **No `image_url` on `/scenarios/personal`.** For You cards are text-only by design.

## Success Criteria

- [x] Zero grep hits for `is_premium`, `is_trial`, `'trial'` status in `lib/` (scenarios-context). `is_active` retained only in subscription/auth models (unrelated).
- [x] `/lessons` endpoint constant removed; all call sites migrated.
- [x] Home first tab renders 2 top tabs; both paginate from `/scenarios/*`.
- [x] Scenario cards render correct badges across `available`/`locked`/`learned` × `free`/`premium`.
- [x] `scenario_gift_screen.dart` still parses onboarding payload without runtime error (new enum fields nullable).
- [x] `flutter analyze` clean on all touched files (only pre-existing kebab-case file-name infos remain).
- [x] `flutter test test/features/scenarios/` all green (27 new tests). Pre-existing failures in `widget_test.dart` + `ai_chat_binding_cold_resume_test.dart` confirmed unrelated to this migration.

## Risk Assessment

- **Controller file bloat** — `ChatHomeController` currently owns lessons + language. Split into `HomeShellController` (language/tabs) + `FloweringFeedController` + `ForYouFeedController` to stay under 200 lines each.
- **Tab state persistence** — switching bottom-nav tabs shouldn't reset For You/Flowering state. Use `AutomaticKeepAliveClientMixin` on tab widgets.
- **Backend personal-feed availability** — `/scenarios/personal` may return empty for users who never went through onboarding. Plan empty state: "Complete onboarding to unlock personalized scenarios."
- **Stale references to `trial`** — full grep before phase 6 cleanup to avoid runtime crashes on an unmatched switch branch.

## Docs Impact

Minor: update `docs/system-architecture.md` (new `scenarios` feature), `docs/project-changelog.md` (breaking API change + Home restructure).

## Next Steps

1. Execute phase 1 (models + endpoints) — non-breaking additive.
2. Phases 2 → 3 → 4 sequential.
3. Phase 5 parallel with 4.
4. Phase 6 cleanup after 4+5 land.
5. Phase 7 finalize with tests + translations.
