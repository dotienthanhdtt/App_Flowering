# Brainstorm — Mobile API v2 Migration (Scenarios/Lessons Refactor)

**Date:** 2026-04-20
**Project:** `app_flowering/flowering` (Flutter)
**Context:** Backend shipping breaking changes to lessons/scenarios contracts + new `/scenarios/*` endpoints + role model refactor. Mobile must migrate.

---

## 1. Problem Statement

Backend is dropping `is_premium`/`is_trial`/`is_active` from scenario/lesson payloads, introducing:
- New gating field `access_tier: "free" | "premium"`
- New per-user computed `status: "available" | "locked" | "learned"` (trial removed)
- New scenario `type: "default" | "kol"` discriminator
- New `/scenarios/default` (flat paginated) and `/scenarios/personal` (merged personalized + KOL) endpoints
- New `POST /scenarios/redeem` gift-code endpoint
- Auto-enroll on `X-Learning-Language` for `/lessons` + `/scenarios/*` (was `403`)
- `users.is_admin` → `users.roles[]` (no mobile exposure)

Mobile must adapt models, swap endpoints, restructure Home UX, preserve backward-compatible error flows.

---

## 2. Current Mobile State (Scout Findings)

| Area | Current | Impact |
|---|---|---|
| `LessonScenario.status` | `trial\|available\|locked\|learned` | Drop `trial` branch |
| `Scenario` model | No `access_tier`/`status`/`type` | Add all three |
| `/lessons` call | `ChatHomeController:60-85`, category-grouped | Replace with `/scenarios/default` |
| Hive caching | None for scenario/lesson fields | No local migration needed |
| `is_admin` reads | None found | No change |
| Gift-code UI | None exists | Skipped in V1 (per user) |
| `scenario_gift_screen.dart` | Post-onboarding AI reveal | Keep as first-run celebration |
| `language-recovery-interceptor` | Catches 403 globally | Keep as-is (still needed for `/scenario/chat`, `/ai/*`, `/progress`) |

---

## 3. Evaluated Approaches

### 3.1 Feed strategy (decided)
- **Option A** Keep `/lessons`, patch fields only — rejected (tech-debt, divergent from backend long-term)
- **Option B** Full migration to `/scenarios/default` — **CHOSEN**
- **Option C** Dual-endpoint — rejected (maintenance doubled)

**Why B:** Backend committed to `/scenarios/*` as canonical. Single source of truth. `/lessons` becomes dead weight on mobile.

**Trade-off:** Lose server-driven category grouping. Accept flat-grid UX as intentional simplification.

### 3.2 Home UX (decided)
Two top tabs on Home screen, mirroring existing top-tab pattern:
- **"For You"** — `/scenarios/personal` (personalized + KOL merged by `source`)
- **"Flowering"** — `/scenarios/default` (flat infinite-scroll grid)

Replaces current category-scroll layout powered by `/lessons`.

### 3.3 Gift-code redeem (decided: V1 skip)
Not implemented in V1. `/scenarios/personal` still surfaces KOL scenarios for users who redeem via future channel (admin-granted, deep-link, etc.). Model must support `source: "kol"` rendering even without redeem UI.

### 3.4 Card visuals (decided)
- **Flowering tab:** thumbnail + title + difficulty + tier badge (uses `image_url` from `/scenarios/default`)
- **For You tab:** text-only — icon + title + difficulty + `source` indicator. No `image_url` request to backend.

Deliberate visual differentiation = curated (rich) vs personal (lean).

### 3.5 403 interceptor (decided: keep)
Auto-enroll kills 403 on `/lessons` + `/scenarios/*`, so interceptor simply stops firing there. Still active for strict endpoints (`/scenario/chat`, `/ai/*`, `/progress`). No code change needed — toast already scoped to specific 403 message.

---

## 4. Recommended Solution

### 4.1 Scope (V1)
**IN:**
1. Model updates — add `access_tier`, `type`, new `status` enum on `Scenario` + `LessonScenario`
2. Drop reads of `is_premium`/`is_trial`/`is_active`
3. Drop `trial` status branch from `ScenarioCard`
4. Wire `/scenarios/default` — new API method + paginated list controller
5. Wire `/scenarios/personal` — new API method + `source`-aware card widget
6. Restructure Home: add top-tab scaffold (`For You` / `Flowering`)
7. Delete `/lessons` call path + `GetLessonsResponse` DTO (or mark deprecated then delete)
8. Validate `scenario_gift_screen.dart` still works against new `Scenario` model

**OUT (V1):**
- Gift-code redeem UI + endpoint wiring
- `/scenarios/redeem` API client method
- Admin/KOL management screens
- `roles[]` field on `UserModel` (not exposed to mobile)

### 4.2 Proposed File Changes

```
lib/features/
├── lessons/
│   ├── models/lesson-models.dart          [UPDATE] — status enum; add access_tier, type; drop is_active
│   ├── models/scenario_model.dart         [UPDATE same dir as onboarding? consolidate]
│   └── widgets/scenario-card.dart         [UPDATE] — handle locked/learned, drop trial, render access_tier badge
├── chat/
│   └── controllers/chat-home-controller.dart  [REWRITE] — swap /lessons → /scenarios/default; paginated
├── home/  (new or existing)
│   ├── views/home-view.dart               [UPDATE] — top-tab scaffold
│   ├── controllers/home-controller.dart   [UPDATE] — tab state
│   └── tabs/
│       ├── for-you-tab.dart               [NEW] — /scenarios/personal consumer
│       └── flowering-tab.dart             [NEW] — /scenarios/default consumer (extract from ChatHome)
├── scenarios/  (new feature dir)
│   ├── models/scenario-feed-item.dart     [NEW] — shared model for feed items
│   ├── models/personal-scenario.dart      [NEW] — adds source discriminator
│   ├── services/scenarios-service.dart    [NEW] — /scenarios/default, /scenarios/personal API methods
│   ├── controllers/default-feed-controller.dart  [NEW]
│   └── controllers/personal-feed-controller.dart [NEW]
└── onboarding/
    └── views/scenario_gift_screen.dart    [VERIFY] — confirm parses new Scenario fields
lib/core/constants/api_endpoints.dart      [UPDATE] — add scenarios endpoints
```

### 4.3 Migration Sequence
1. **Models + endpoints first** — non-breaking additive changes to DTOs
2. **Services layer** — new `ScenariosService` + methods
3. **Controllers** — new feed controllers; keep old `ChatHomeController` wired until UI swap
4. **UI: Home tabs** — add tab scaffold + two tab widgets
5. **UI: cards** — update `ScenarioCard` for new `status`/`access_tier` fields
6. **Cut-over** — replace `ChatHomeController` routing to new Home
7. **Cleanup** — delete `/lessons` endpoint constant, `GetLessonsResponse`, dead code

### 4.4 Testing Strategy
- Unit tests: model `fromJson` for new fields (happy + missing-field defaults)
- Widget tests: `ScenarioCard` renders correct badge per `status` × `access_tier`
- Controller tests: pagination logic on both feed controllers
- Integration: `X-Learning-Language` flow (verify no 403 toast on unenrolled language)

---

## 5. Risks & Mitigation

| Risk | Mitigation |
|---|---|
| **Backend `/scenarios/personal` shape drift** — if backend later adds `image_url`, text-only UI may regress vs. design expectation | Keep `PersonalScenario` model extensible; easy to add image later |
| **Category-grouped UX loss** — users accustomed to Greetings/Travel sections may feel lost | If feedback negative post-launch, add client-side difficulty grouping as fast follow |
| **First-run `scenario_gift_screen` drift** — still reads `Scenario` model; field rename can silently break | Add widget test asserting gift screen parses new payload shape |
| **Redeem endpoint unwired** — if a KOL ships a promo before V2 mobile ships redeem, confusion | Document as known-limitation. KOL scenarios still unlockable via backend admin grant; appear in `For You` once granted |
| **403 interceptor stale logic** — the "not enrolled" branch becomes dead for `/lessons`/`/scenarios/*` but still fires for other endpoints | Leave untouched in V1; document that auto-enroll means fewer 403s overall. Revisit if telemetry shows no firings |
| **`type: "kol"` card in Flowering tab** — backend filters `type='default'` server-side, but what if a `kol` leaks? | Client-side guard: `assert item.type == 'default'` in Flowering tab; render gracefully if mismatch |

---

## 6. Open Questions for Backend (non-blocking)

1. **`/scenarios/default` — does `order_index` apply across languages, or per-language?** Affects whether paginating across language switches is stable.
2. **`/scenarios/personal` — `added_at` tiebreaker when `source: personalized` and `source: kol` share timestamps?** Spec orders by `added_at DESC`; need deterministic secondary sort.
3. **KOL grant flow (non-redeem path)** — confirm backend admin can grant `user_scenario_access` manually so `For You` has test data pre-redeem-UI.
4. **Deprecation timeline for `/lessons`** — when does backend remove it? Mobile V2 ships independent of backend removal but we want a sunset date.

---

## 7. Success Metrics

- All references to `is_premium`, `is_trial`, `is_active` removed from mobile codebase (grep check: 0 hits)
- All references to `trial` status value removed (grep check: 0 hits)
- `/lessons` endpoint removed from `api_endpoints.dart` and call sites
- Home screen renders two tabs; both populate from `/scenarios/*` with pagination
- No `403` toast surfaces when switching `X-Learning-Language` in browse flow
- `scenario_gift_screen` continues to parse onboarding payload correctly
- Widget test coverage on `ScenarioCard` across 6 states: `available`/`locked`/`learned` × `free`/`premium`

---

## 8. Next Steps

1. Decision: run `/ck:plan` with this report as context to generate phase-by-phase implementation plan
2. Confirm open backend questions (§6) async — non-blocking for planning
3. Review existing Home view / top-tab pattern in codebase before drafting phase 4 (UI scaffold) to reuse conventions

---

## 9. Decision Log

| Decision | Choice | Rationale |
|---|---|---|
| Feed endpoint | Full migration to `/scenarios/default` | Single source of truth; reduce drift |
| Home structure | Two top tabs (For You / Flowering) | Clean separation; familiar pattern |
| Flowering tab UX | Flat infinite-scroll grid | Matches backend shape; simplest |
| For You thumbnails | Text-only, no `image_url` | Lean payload; visual differentiation |
| Gift-code redeem | Skip in V1 | Descoped per user; model still supports `source: "kol"` |
| 403 interceptor | Keep as-is | Still defensive for strict endpoints |
| Onboarding gift screen | Keep | Preserves first-run reveal moment |
| `roles[]` on UserModel | Skip | Not exposed to mobile; no client break |
