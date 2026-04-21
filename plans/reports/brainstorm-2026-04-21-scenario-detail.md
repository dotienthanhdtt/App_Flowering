# Brainstorm — Scenario Detail Screen + Navigation

**Date:** 2026-04-21
**Scope:** Tap a scenario card → detail screen (design `10_scenario_detail`) → start scenario chat.

---

## Problem Statement

1. Feed cards on the Flowering tab are currently **not tappable** (`FeedScenarioCard.onTap` isn't wired in `flowering_tab.dart:88`).
2. `GET /scenarios/:id` endpoint **does not exist** on the backend (only `/default`, `/personal`, `/redeem`).
3. No scenario detail screen in the Flutter app.
4. No scenario chat screen in the Flutter app (BE has `/scenario/chat` + conversation endpoints, FE never wired).

Design `10_scenario_detail` is minimal: top bar (back + title), 300px hero image, title + description, full-width "Start Conversation" CTA in a bottom bar.

---

## Requirements

### Functional
- Tap feed card → navigate to detail screen with scenario ID.
- Detail screen calls `GET /scenarios/:id` with `Authorization` + `X-Learning-Language`.
- Render: hero image, title, description, CTA.
- CTA state:
  - `isLocked = true` → "Upgrade to Unlock" → paywall / subscription flow.
  - `userStatus = learned` → "Practice Again".
  - Otherwise → "Start Conversation".
- CTA (when not locked) navigates to a new Scenario Chat screen.
- Back button returns to feed.
- 404 / language-mismatch → inline error state with retry.

### Non-functional
- **No cache** on detail (user explicit). Fresh fetch every open.
- Reuse existing chat widgets (`ai_message_bubble`, `user_message_bubble`, `chat_input_bar`, `chat_top_bar`, `ai_typing_bubble`) for the new scenario chat.
- Translations via `.tr`, base widgets (`AppText`, `AppButton`), base classes (`BaseController`, `BaseScreen`).
- File size ≤ 200 lines, kebab-case file names.

---

## Approaches Considered

### A. FE-only, reuse feed payload (rejected)
Pass `ScenarioFeedItem` via nav args, no API call. Fast. Rejected: user wants detail API + richer fields, and feed payload lacks `isLocked` / `lockReason`.

### B. Full bundle: detail + chat in one plan (accepted, phased)
Build `GET /scenarios/:id`, detail screen, navigation, and scenario chat screen. Larger but avoids a broken CTA that routes nowhere.

### C. Detail-only, stub chat (rejected)
Detail ships before chat. Rejected because CTA has no destination — placeholder TODO in production is a rough UX.

**Winner: B**, but split into independent phases so detail can be reviewed/tested before chat is complete.

---

## Recommended Solution

### Backend (`be_flowering`)

**New endpoint:** `GET /scenarios/:id`
- Controller: add to `scenarios.controller.ts` (beside `listDefault`/`listPersonal`).
- Service method: add `getById(userId, scenarioId, languageId)` to `ScenariosListingService`.
- Guards: `JwtAuthGuard` (global), `AutoEnrollLanguage` like list endpoints.
- Validation: `ParseUUIDPipe` on `:id`.
- DTO: new `ScenarioDetailDto` (final field set below).
- Logic:
  - Load scenario where `id = :id AND status = PUBLISHED AND language_id = activeLang`. Miss → `404 { code: 0, message: "Scenario not found" }` (matches user contract).
  - Lock check: `accessTier === PREMIUM` → query subscription/`UserScenarioAccess` → `isLocked = true/false`, `lockReason = 'premium_required'` when locked.
  - Compute `userStatus`: `locked` if `isLocked`, else `learned` if user has a completed `user_ai_scenario` / chat-session row for this scenario, else `available`.
  - Include `imageUrl` and `category: { id, name }`.

**Detail DTO (agreed shape + two additions):**
```json
{
  "id": "uuid",
  "title": "...",
  "description": "...",
  "imageUrl": "...",           // added (design needs hero)
  "difficulty": "beginner",
  "languageId": "uuid",
  "orderIndex": 1,
  "category": { "id": "uuid", "name": "..." },
  "accessTier": "free|premium",
  "isLocked": false,
  "lockReason": "premium_required",  // only when isLocked
  "userStatus": "available|learned|locked"  // added for CTA copy
}
```

**Tests:** spec for `getById` — found/not-found, language mismatch, free vs premium-locked vs premium-unlocked, learned state.

### Flutter (`app_flowering/flowering`)

**Feature path:** `lib/features/scenarios/` (already exists) + new `lib/features/scenario-chat/`.

**New files (detail):**
- `scenarios/models/scenario_detail.dart` — detail model + `fromJson`.
- `scenarios/services/scenarios_service.dart` — add `getScenarioDetail(String id)` (no cache).
- `scenarios/controllers/scenario_detail_controller.dart` — `BaseController`; loads detail on init; owns `detail` obs + error.
- `scenarios/bindings/scenario_detail_binding.dart` — registers controller with scenario ID from `Get.arguments`.
- `scenarios/views/scenario_detail_screen.dart` — `BaseScreen<ScenarioDetailController>`.
- `scenarios/widgets/scenario_detail_cta.dart` — CTA that maps `userStatus` / `isLocked` → button label + action.

**Routing:**
- `app-route-constants.dart`: `scenarioDetail = '/scenarios/detail'`.
- `app-page-definitions-with-transitions.dart`: register with binding + default transition.
- `FloweringTab` + `ForYouTab`: wire `onTap: () => Get.toNamed(Routes.scenarioDetail, arguments: {'id': items[i].id})`.

**New files (scenario chat, minimal):**
- `scenario-chat/models/` — request / response / turn models mirroring `ScenarioChatRequestDto`, `ScenarioChatResponseDto`.
- `scenario-chat/services/scenario_chat_service.dart` — `POST /scenario/chat`, `GET /scenario/conversations/:id`, `GET /scenario/:scenarioId/conversations`.
- `scenario-chat/controllers/scenario_chat_controller.dart` — derives from `BaseController`; owns message list + send flow; model after `ai_chat_controller.dart` but simpler (one scenario, no multi-session picker).
- `scenario-chat/bindings/scenario_chat_binding.dart`.
- `scenario-chat/views/scenario_chat_screen.dart` — reuses `ai_message_bubble`, `user_message_bubble`, `ai_typing_bubble`, `chat_input_bar`, `chat_top_bar`.
- Route `/scenario-chat`, argument: `{ 'scenarioId': ..., 'scenarioTitle': ... }`.

**Paywall routing (locked CTA):** route to existing subscription / upgrade screen. If none exists yet, log + toast + leave TODO — separate scope.

**Translations added (both en-us + vi-vn):**
- `scenario_detail_title`, `scenario_detail_start`, `scenario_detail_practice_again`, `scenario_detail_upgrade_to_unlock`, `scenario_detail_not_found`, `scenario_detail_error_generic`.

---

## Implementation Phases

1. **BE: detail endpoint** — controller + service + DTO + specs. (Small, isolated.)
2. **FE: detail screen** — model/service/controller/view + wire `onTap` in feed tabs + route. Exercises the new endpoint end-to-end. Locked CTA stubs to a toast until paywall is defined.
3. **FE: scenario chat screen** — models/service/controller/view, reusing chat widgets. Wire CTA from detail.
4. **Paywall hookup** (if/when upgrade flow exists) — replace toast with real navigation.
5. **Tests** — BE service spec, FE controller test with mock service, widget smoke test on detail.

Phases 1-2 can ship behind a feature flag-free gate (low risk: read-only endpoint). Phase 3 is the bulk of the work; plan separately if scope balloons.

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| `userStatus = learned` requires joining chat/session table — slow query | Add index on `(user_id, scenario_id)` in `user_ai_scenario`; left-join with limit 1; profile before ship. |
| Feed item `status` enum (locked/learned/available) vs detail `isLocked + userStatus` drift | Document detail as source of truth; feed eventually adopts same shape (follow-up). Don't "fix" feed in this plan. |
| No cache → back-nav from chat refetches detail | User accepted. Monitor; revisit if it feels sluggish. |
| Paywall doesn't exist yet | Toast + route TODO; don't block detail ship on paywall. |
| Scenario chat scope creep (voice, grammar correction, translation sheets) | Phase 3 ships *text-only* MVP reusing bubbles + input. Voice / grammar parity = separate plan. |
| 404 when language switches mid-view | Controller listens to `LanguageContextService.activeCode` like `FloweringFeedController`; on change, pop back to feed. |

---

## Security

- JWT required (global guard already covers).
- `ParseUUIDPipe` blocks injection via path param.
- Lock check server-authoritative — FE never trusts `isLocked = false` without roundtrip.
- Throttle on detail endpoint unnecessary (cheap read); rely on default rate limiter.

---

## Success Criteria

- [ ] `curl GET /scenarios/$ID -H "Authorization: Bearer $JWT" -H "X-Learning-Language: $LANG"` returns the four documented shapes (free, premium-locked, premium-unlocked, 404).
- [ ] Tap any feed card → detail screen renders with hero image + title + description + CTA.
- [ ] CTA copy switches correctly: available → Start, learned → Practice Again, locked → Upgrade.
- [ ] CTA (unlocked) routes to scenario chat; first AI turn streams in; user can send a reply.
- [ ] Language switch on detail pops back to feed.
- [ ] `flutter analyze` clean; new files ≤ 200 lines; all user-facing strings use `.tr`.
- [ ] BE unit tests pass; FE controller tests pass.

---

## Open Questions

- Paywall screen — does it already exist under a different name? If yes, wire directly; if no, separate scope.
- Scenario chat MVP: text-only, or must it match `ai_chat_screen` parity (voice input, grammar correction, word translation sheet)? Assumed text-only.
- Should detail show `difficulty` pill and `category` label even though design doesn't? Assumed NO (YAGNI; design wins).
- Should "learned" be computed from `user_ai_scenario.completed_at` or chat-session completion? Needs BE schema confirmation before phase 1.

---

## Next Steps

If approved → delegate to `planner` agent (`/ck:plan`) with this report as context. Planner produces phase files:
- `phase-01-backend-detail-endpoint.md`
- `phase-02-flutter-detail-screen.md`
- `phase-03-flutter-scenario-chat-mvp.md`
- `phase-04-tests-and-polish.md`
