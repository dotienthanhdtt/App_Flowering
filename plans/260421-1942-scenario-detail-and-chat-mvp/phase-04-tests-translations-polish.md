# Phase 4 — Tests, Translations, Analyze, Docs

## Context Links

- Phase 1: [phase-01-backend-detail-endpoint.md](phase-01-backend-detail-endpoint.md)
- Phase 2: [phase-02-flutter-detail-screen.md](phase-02-flutter-detail-screen.md)
- Phase 3: [phase-03-flutter-scenario-chat-mvp.md](phase-03-flutter-scenario-chat-mvp.md)
- BE spec pattern: `be_flowering/src/modules/scenario/services/scenarios-listing.service.spec.ts`
- FE controller test pattern: existing `test/features/scenarios/*` (per v2 migration plan)

## Overview

**Priority:** P1
**Status:** pending
**Blocked by:** Phases 1-3
**Effort:** 2h

Harden the feature: BE unit tests for `getById`, FE controller tests for detail + chat, translation coverage audit, `flutter analyze` / `npm run lint` clean, docs updates.

## Requirements

### Backend Tests (`scenarios-listing.service.spec.ts`)
New `describe('getById', …)` block with cases:
1. Returns detail for FREE scenario → `isLocked: false`, `userStatus: 'available'`.
2. Returns detail for PREMIUM + access granted → `isLocked: false`.
3. Returns detail for PREMIUM + no access → `isLocked: true, lockReason: 'premium_required', userStatus: 'locked'`.
4. `userStatus: 'learned'` when `ai_conversations` has `metadata.completed = true` for user + scenario.
5. Throws `NotFoundException` when scenario missing.
6. Throws `NotFoundException` when `languageId` mismatch (cross-language request).
7. Throws `NotFoundException` when `status != PUBLISHED` (draft scenario).

Mocks: `scenarioRepo.findOne`, `accessService.checkAccess`, `conversationRepo.createQueryBuilder()...getExists()`.

### Frontend Tests

**`test/features/scenarios/scenario_detail_controller_test.dart`:**
- `fetch` success → `detail` populated, no error.
- `fetch` 404 → `notFound == true`.
- Language switch while on detail route → `Get.back` invoked.
- `openPaywall` returning `true` → `fetch` called a second time.

**`test/features/scenarios/scenario_detail_cta_test.dart` (widget test):**
- `isLocked: true` → shows "Upgrade" label.
- `userStatus: learned` → shows "Practice Again".
- Default → shows "Start Conversation".

**`test/features/scenario-chat/scenario_chat_controller_test.dart`:**
- `sendText` pushes user message + receives AI reply → list contains 2 messages.
- Response `completed: true` → `completed.value == true`, further sends are blocked.
- 403 response → snackbar called + `Get.back` + paywall invocation.

Use existing test helpers and fake `ApiClient` stubs (mirror pattern from v2 migration tests).

### Translations Audit

Run `scripts/verify-translations.sh` (or equivalent). Ensure the 9 new keys (6 from Phase 2, 3 from Phase 3) exist in BOTH `english-translations-en-us.dart` and `vietnamese-translations-vi-vn.dart`. Zero missing keys.

### Analyze / Lint

- `flutter analyze` in `app_flowering/flowering/` — zero new infos/warnings on touched files.
- `npm run lint` in `be_flowering/` — clean.
- `npm run build` (BE) + `flutter build apk --dart-define=ENV=dev` (FE) — both succeed.

### Docs Updates

- `docs/system-architecture.md`:
  - Under Scenarios: add `GET /scenarios/:id` to endpoint list; note `userStatus` derivation.
  - Under Mobile features: add "Scenario Detail", "Scenario Chat (text MVP)".
- `docs/project-changelog.md`:
  - New entry under current week: "feat: scenario detail screen + text-only scenario chat MVP".
- `docs/development-roadmap.md`: mark scenario detail + scenario chat MVP as shipped once merged.

## Implementation Steps

1. Write BE spec cases (7 total) in new `describe('getById', …)` block.
2. Run `npm test -- scenarios-listing.service.spec`; fix any gaps in service implementation that the test surfaces.
3. Write FE controller tests (detail + chat).
4. Write `ScenarioDetailCta` widget test.
5. Run `flutter test test/features/scenarios/` + `test/features/scenario-chat/`. All green.
6. Run translation audit. Fix gaps.
7. Run `flutter analyze` + `npm run lint` + `npm run build`. Fix all new issues.
8. Update 3 docs files with concrete entries.
9. Git commit per phase following conventional commits.

## Todo List

- [ ] BE spec: 7 cases in `scenarios-listing.service.spec.ts`
- [ ] FE test: `scenario_detail_controller_test.dart` (4 cases)
- [ ] FE test: `scenario_detail_cta_test.dart` (3 cases)
- [ ] FE test: `scenario_chat_controller_test.dart` (3 cases)
- [ ] Translation audit; verify 9 keys in both locale files
- [ ] `flutter analyze` + `npm run lint` + `npm run build` clean
- [ ] Update `system-architecture.md`, `project-changelog.md`, `development-roadmap.md`
- [ ] Run full `flutter test` — confirm no regressions

## Success Criteria

- [ ] All new tests pass; no flakes on 3 consecutive runs.
- [ ] `flutter analyze` delta = 0 new issues on touched paths.
- [ ] Translation count parity: `grep -c "' => '" en-us` == `grep -c "' => '" vi-vn` (or equivalent key count).
- [ ] Docs updated — `git diff docs/` shows only the 3 intended files with relevant additions.

## Risk Assessment

- **Flaky language-switch test** — `GetX` routing in tests can be brittle. Use `Get.testMode = true` + direct `Get.offNamed` stubs.
- **Widget test env** — `BaseScreen` depends on `.tr` — ensure `Get.put(GetMaterialController())` + translations initialized in `setUpAll`.
- **Translation drift** — if a key is added to en-us but forgotten in vi-vn, app crashes on Vietnamese locale. Audit script or manual grep is required — don't skip.

## Security Considerations

- BE tests must include the language-mismatch case to prevent cross-language data leakage (regression guard).
- No secrets or tokens in test fixtures. Use constants, not real JWTs.

## Next Steps

After this phase merges:
1. Follow-up plan: unify feed `ScenarioFeedItem.status` with new `isLocked + userStatus` shape.
2. Follow-up plan: scenario chat parity with `AiChatScreen` (voice, grammar, translation sheet).
3. Monitor detail endpoint p95 latency; add partial index if `metadata->>'completed'` query degrades.
