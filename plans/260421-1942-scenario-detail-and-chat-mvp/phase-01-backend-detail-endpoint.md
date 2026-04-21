# Phase 1 — Backend: `GET /scenarios/:id`

## Context Links

- Brainstorm: [../reports/brainstorm-2026-04-21-scenario-detail.md](../reports/brainstorm-2026-04-21-scenario-detail.md)
- Existing controller: `be_flowering/src/modules/scenario/scenarios.controller.ts`
- Listing service: `be_flowering/src/modules/scenario/services/scenarios-listing.service.ts`
- Access service (reuse): `be_flowering/src/modules/scenario/services/scenario-access.service.ts`
- Scenario entity: `be_flowering/src/database/entities/scenario.entity.ts`
- Completion source: `be_flowering/src/modules/scenario/services/scenario-chat.service.ts:78` (`metadata->>'completed' = 'true'` on `ai_conversations`)

## Overview

**Priority:** P1 (blocks FE detail)
**Status:** pending
**Effort:** 3h

Add a single READ endpoint `GET /scenarios/:id` that returns scenario detail for the active learning language with server-authoritative access + completion state.

## Key Insights

- Frontend contract already agreed in brainstorm. Two server additions: `imageUrl` (design needs hero) + `userStatus ∈ {available, learned, locked}` (so FE chooses CTA copy without extra calls).
- `ScenarioAccessService.checkAccess(userId, scenario)` already resolves premium lock — reuse it.
- `learned` = exists any `ai_conversations` where `user_id = :uid AND scenario_id = :sid AND metadata->>'completed' = 'true'`. Do NOT use `user_ai_scenarios` — that table has no completion column.
- Language mismatch (scenario exists but `language_id != activeLang`) returns `404` — must NOT leak cross-language existence.
- Response wrapped in global `{code, message, data}` shape.

## Requirements

### Functional
- `GET /scenarios/:id` → 200 with `ScenarioDetailDto` on match.
- 404 `{code: 0, message: "Scenario not found"}` when not found OR `status != PUBLISHED` OR `language_id != activeLang`.
- Premium + no access → `isLocked: true, lockReason: "premium_required"`. Premium + has access OR free → `isLocked: false` and `lockReason` omitted.
- `userStatus`: `locked` if `isLocked`, else `learned` if any completed conversation, else `available`.

### Non-functional
- `ParseUUIDPipe` on `:id`.
- `@AutoEnrollLanguage()` + `X-Learning-Language` header (mirror listing routes).
- Global JWT guard applies.
- Query cost ≤ 2 DB roundtrips (scenario + access/completion in parallel).
- No new dependencies.

## Architecture

```
ScenariosController.getById(userId, langId, scenarioId)
    │
    ▼
ScenariosListingService.getById(userId, scenarioId, languageId)
    │
    ├─► scenarioRepo.findOne({ id, status: PUBLISHED, languageId }, { relations: ['category'] })
    │     └─► null? → throw NotFoundException
    │
    ├─► Promise.all([
    │     ScenarioAccessService.checkAccess(userId, scenario),   // returns { hasAccess, isLocked, lockReason }
    │     aiConversationRepo.exist({
    │       where: { userId, scenarioId, metadata: Raw(...) }    // metadata->>'completed' = 'true'
    │     }),
    │   ])
    │
    └─► map to ScenarioDetailDto
```

## Data Flow

```
Client ── GET /scenarios/:id (Bearer, X-Learning-Language) ──► ScenariosController
                                                                    │
                                                                    ▼
                                                          ScenariosListingService.getById
                                                                    │
                                              ┌─────────────────────┼─────────────────────┐
                                              ▼                     ▼                     ▼
                                      scenario + category   access check          completion check
                                         (scenarios)        (scenario_access      (ai_conversations
                                                             + subscription)        metadata)
                                              └─────────────────────┬─────────────────────┘
                                                                    ▼
                                                           ScenarioDetailDto
                                                                    │
                                                                    ▼
                                                        { code: 1, data: ... }
```

## Related Code Files

**Create:**
- `be_flowering/src/modules/scenario/dto/scenario-detail.dto.ts` — `ScenarioDetailDto` (class-validator + class-transformer, Swagger decorated).

**Modify:**
- `be_flowering/src/modules/scenario/scenarios.controller.ts` — add `@Get(':id')` handler `getById`.
- `be_flowering/src/modules/scenario/services/scenarios-listing.service.ts` — add `getById(...)` method; inject `ScenarioAccessService` + `Repository<AiConversation>`.
- `be_flowering/src/modules/scenario/scenarios.module.ts` — register `AiConversation` in `TypeOrmModule.forFeature`; import `ScenarioAccessService` (likely already in scope).

**Read for context only:**
- `be_flowering/src/modules/scenario/services/scenario-access.service.ts` (for `checkAccess` signature)
- `be_flowering/src/database/entities/ai-conversation.entity.ts`

## Implementation Steps

1. **DTO.** Create `scenario-detail.dto.ts`:
   ```ts
   export class ScenarioCategoryRef { id: string; name: string; }
   export class ScenarioDetailDto {
     id!: string;
     title!: string;
     description!: string;
     imageUrl?: string;
     difficulty!: 'beginner' | 'intermediate' | 'advanced';
     languageId!: string;
     orderIndex!: number;
     category!: ScenarioCategoryRef;
     accessTier!: 'free' | 'premium';
     isLocked!: boolean;
     lockReason?: 'premium_required';
     userStatus!: 'available' | 'learned' | 'locked';
   }
   ```
   Add `@ApiProperty` decorators.

2. **Service method.** In `scenarios-listing.service.ts`:
   - Inject `ScenarioAccessService` + `@InjectRepository(AiConversation) private conversationRepo`.
   - Implement `getById(userId, scenarioId, languageId)`:
     ```ts
     const scenario = await this.scenarioRepo.findOne({
       where: { id: scenarioId, status: ContentStatus.PUBLISHED, languageId },
       relations: ['category'],
     });
     if (!scenario) throw new NotFoundException('Scenario not found');

     const [access, hasCompleted] = await Promise.all([
       this.accessService.checkAccess(userId, scenario),
       this.conversationRepo
         .createQueryBuilder('c')
         .where('c.user_id = :userId', { userId })
         .andWhere('c.scenario_id = :scenarioId', { scenarioId })
         .andWhere(`c.metadata->>'completed' = 'true'`)
         .getExists(),
     ]);

     const isLocked = !access.hasAccess;
     const userStatus: 'available' | 'learned' | 'locked' =
       isLocked ? 'locked' : hasCompleted ? 'learned' : 'available';

     return {
       id: scenario.id,
       title: scenario.title,
       description: scenario.description ?? '',
       imageUrl: scenario.imageUrl ?? undefined,
       difficulty: scenario.difficulty,
       languageId: scenario.languageId,
       orderIndex: scenario.orderIndex,
       category: { id: scenario.category.id, name: scenario.category.name },
       accessTier: scenario.accessTier,
       isLocked,
       ...(isLocked ? { lockReason: 'premium_required' as const } : {}),
       userStatus,
     };
     ```

3. **Controller route.** In `scenarios.controller.ts`, add above `redeem`:
   ```ts
   @Get(':id')
   @AutoEnrollLanguage()
   @ApiHeader(LANGUAGE_HEADER)
   @ApiOperation({ summary: 'Get scenario detail for the active language' })
   @ApiResponse({ status: 200, type: ScenarioDetailDto })
   @ApiResponse({ status: 404, description: 'Scenario not found' })
   getById(
     @CurrentUser() user: { id: string },
     @ActiveLanguage() lang: ActiveLanguageContext,
     @Param('id', ParseUUIDPipe) id: string,
   ) {
     return this.listingService.getById(user.id, id, lang.id);
   }
   ```

4. **Module wiring.** `scenarios.module.ts`:
   - Add `AiConversation` to `TypeOrmModule.forFeature([...])`.
   - Ensure `ScenarioAccessService` is in providers (likely inherited from parent module — verify before duplicating).

5. **Compile check.** Run `npm run build` in `be_flowering/` — must pass.

6. **Manual verification.**
   ```bash
   curl -i "$API/scenarios/$FREE_ID" -H "Authorization: Bearer $JWT" -H "X-Learning-Language: en"
   curl -i "$API/scenarios/$PREMIUM_ID_LOCKED" -H "Authorization: Bearer $JWT" -H "X-Learning-Language: en"
   curl -i "$API/scenarios/$PREMIUM_ID_UNLOCKED" -H "Authorization: Bearer $JWT" -H "X-Learning-Language: en"
   curl -i "$API/scenarios/$ID_WRONG_LANG" -H "Authorization: Bearer $JWT" -H "X-Learning-Language: es"  # expect 404
   ```

## Todo List

- [ ] Create `scenario-detail.dto.ts` with Swagger + class-validator decorators
- [ ] Add `getById` to `ScenariosListingService`, inject `ScenarioAccessService` + `Repository<AiConversation>`
- [ ] Register `AiConversation` in `scenarios.module.ts`
- [ ] Add `@Get(':id')` route to `ScenariosController`
- [ ] `npm run build` clean
- [ ] Manual curl test on dev environment (4 cases)

## Success Criteria

- [ ] All 4 curl cases return documented shape.
- [ ] 404 body is `{code: 0, message: "Scenario not found"}` (global interceptor wraps).
- [ ] Cross-language request returns 404 (no leak).
- [ ] `npm run lint` + `npm run build` pass.

## Risk Assessment

- **AccessService signature drift** — if `checkAccess` returns different shape than assumed, adapt mapping. Check before writing service method.
- **Category nullability** — `scenario.category` relation may be undefined if category row missing. Default to `{ id: '', name: '' }` defensively? No — 500 is correct; seed invariant.
- **Global JWT guard bypass** — confirm `@Public()` is NOT applied. It shouldn't be; inherits from controller class.
- **Metadata query plan** — `metadata->>'completed' = 'true'` on `ai_conversations` without index may be slow at scale. Acceptable for MVP; add partial index in follow-up.

## Security Considerations

- Endpoint requires JWT (global guard).
- UUID validation via `ParseUUIDPipe`.
- Language context resolved server-side (user's active language), not client-controlled beyond the `X-Learning-Language` header that `ActiveLanguageInterceptor` validates.
- `isLocked` cannot be forged by client; source = subscription + `user_scenario_access` rows.

## Next Steps

Phase 2 consumes this endpoint. No migration required for this phase. Docs impact tracked in Phase 4.
