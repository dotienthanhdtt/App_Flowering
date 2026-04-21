---
title: "Scenario Detail Screen + Chat MVP"
description: "Tap feed card → GET /scenarios/:id → detail view (design 10_scenario_detail) → Start Conversation opens new scenario chat MVP reusing existing chat widgets. Adds backend GET /scenarios/:id with imageUrl + userStatus, wires PaywallBottomSheet for locked premium CTA."
status: complete
priority: P1
effort: 14h
branch: feat/scenario-detail-and-chat
tags: [scenarios, scenario-chat, mobile, backend, nestjs, flutter, getx]
created: 2026-04-21
brainstorm: ../reports/brainstorm-2026-04-21-scenario-detail.md
blockedBy: []
blocks: []
supersedes: []
---

# Scenario Detail + Chat MVP

## Summary

Users tap a scenario card on the Flowering / For-You feed → navigate to a detail screen matching Pencil design `10_scenario_detail` (top bar, 300px hero, title + description, bottom CTA). CTA copy derives from server-authoritative state (`isLocked`, `userStatus`). Tapping an unlocked CTA opens a new scenario chat MVP reusing existing `features/chat/` widgets. Locked premium scenarios surface the existing `PaywallBottomSheet.show()`.

Drives a new backend endpoint `GET /scenarios/:id` (returns agreed contract + `imageUrl` + `userStatus`). No FE cache — detail refetches every entry (user decision).

## Phases

| # | Phase | Status | Effort | File |
|---|-------|--------|--------|------|
| 1 | Backend: `GET /scenarios/:id` endpoint | skipped | 3h | [phase-01](phase-01-backend-detail-endpoint.md) |
| 2 | Flutter: scenario detail screen + nav | complete | 4h | [phase-02](phase-02-flutter-detail-screen.md) |
| 3 | Flutter: scenario chat MVP (text-only) | complete | 5h | [phase-03](phase-03-flutter-scenario-chat-mvp.md) |
| 4 | Tests + translations + analyze polish | in_progress | 2h | [phase-04](phase-04-tests-translations-polish.md) |

## Phase Dependency Graph

```
1 ──► 2 ──► 3 ──► 4
```

Phase 1 must ship to dev before phase 2 integration tests. Phase 2 ships independently of phase 3 (CTA routes to placeholder toast until phase 3 lands). Phase 4 bundles cross-cutting QA at the end.

## Key Dependencies

- `ScenariosController` — extend (not replace) with new route (`be_flowering/src/modules/scenario/scenarios.controller.ts`).
- `ScenariosListingService` — new `getById(userId, scenarioId, languageId)` method (`be_flowering/src/modules/scenario/services/scenarios-listing.service.ts`).
- `ai_conversations.metadata->>'completed'` — authoritative `learned` signal (source confirmed via `scenario-chat.service.ts:78`).
- `UserScenarioAccess` + subscription check for lock resolution (reuse `ScenarioAccessService.checkAccess`).
- Flutter: `features/scenarios/` (new detail files) + new `features/scenario-chat/` directory.
- `PaywallBottomSheet.show()` — existing, imported from `features/subscription/widgets/paywall-bottom-sheet.dart`.
- Reused chat widgets: `ai_message_bubble`, `user_message_bubble`, `chat_input_bar`, `chat_top_bar`, `ai_typing_bubble`.
- Existing backend chat routes: `POST /scenario/chat`, `GET /scenario/conversations/:id`, `GET /scenario/:scenarioId/conversations` (no BE changes for phase 3).

## Explicit Non-Goals (MVP)

- **No voice input / STT / TTS** in scenario chat. Text only.
- **No grammar correction panel, no word-translation sheet** — feature parity with `AiChatScreen` is out of scope.
- **No conversation history picker** (list past conversations). MVP always resumes the active one or starts new via `forceNew: true`.
- **No detail screen cache.** User explicit decision.
- **No feed item shape changes.** `ScenarioFeedItem.status` enum stays; detail is authoritative source of truth.
- **No new translations beyond detail + chat surface.** Existing `scenarios_*` keys unchanged.
- **No paywall redesign.** Reuse `PaywallBottomSheet.show()` as-is.

## Success Criteria

- [ ] `curl GET $API/scenarios/$ID -H "Authorization: Bearer $JWT" -H "X-Learning-Language: $LANG"` returns the four documented shapes (free unlocked, premium unlocked, premium locked w/ `lockReason`, 404).
- [ ] Response includes `imageUrl`, `category: { id, name }`, `isLocked`, `userStatus ∈ {available, learned, locked}`.
- [ ] Tap any `FeedScenarioCard` or `PersonalFeedCard` → navigates to detail; hero image, title, description render.
- [ ] CTA copy switches correctly: `available` → "Start Conversation"; `learned` → "Practice Again"; `locked` → "Upgrade to Unlock".
- [ ] Locked CTA opens `PaywallBottomSheet`. Successful purchase → detail refetches → CTA becomes unlocked.
- [ ] Unlocked CTA routes to scenario chat; first AI turn appears; user sends text, AI replies; `completed: true` gracefully disables input.
- [ ] Language switch on detail pops back to feed (mirrors `FloweringFeedController._langWorker`).
- [ ] 404 → inline error + retry button.
- [ ] `flutter analyze` clean; new files ≤ 200 lines; all user-facing strings via `.tr`.
- [ ] BE specs for `getById` (5 cases) all green; FE controller tests green.

## Risk Assessment

- **Learned-state query cost** — joins on `ai_conversations` filtered by `scenario_id + user_id + metadata->>'completed'`. Mitigate with partial index on `(scenario_id, user_id) WHERE metadata->>'completed' = 'true'` if p95 > 30ms.
- **Feed `status` drift** — `ScenarioFeedItem.status` uses enum `{available, learned, locked}` while new detail uses `isLocked + userStatus`. Kept independent this round. Follow-up plan unifies.
- **No cache → back-nav refetches** — accepted. Monitor; revisit if p95 entry > 600ms.
- **Chat scope creep** — MVP text-only. Voice / grammar / translation sheet = separate plan.
- **Paywall mismatch** — `PaywallBottomSheet.show()` returns `bool` (purchased). Detail must refetch on `true` to flip `isLocked`. Failure to refetch = ghost-locked CTA.

## Security Considerations

- JWT required (global guard). `X-Learning-Language` required (via `AutoEnrollLanguage`).
- `ParseUUIDPipe` on `:id` blocks injection via path param.
- Lock verification server-side only. FE never trusts `isLocked = false` without roundtrip.
- Scenario chat endpoints already enforce premium gate via `UserScenarioAccess` check — phase 3 relies on existing 403 handling.

## Docs Impact

Minor: update `docs/system-architecture.md` (new scenario detail endpoint, new scenario-chat feature), `docs/project-changelog.md` (new API surface + screens).

## Next Steps

1. Phase 1 — BE endpoint (unblock FE integration).
2. Phase 2 — FE detail screen (can ship to dev w/ toast CTA).
3. Phase 3 — FE scenario chat MVP + wire real CTA.
4. Phase 4 — tests, translations, `flutter analyze`, docs updates.
