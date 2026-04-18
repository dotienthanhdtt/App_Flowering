# Backend Requirements — Onboarding Resume Support

**Consumer:** Flowering mobile app — onboarding progress resume feature
**Backend repo:** `be_flowering/`
**Module:** `src/modules/onboarding/`
**Status:** Required before mobile Phase 04 can proceed

## Context

Mobile persists onboarding progress locally so users resume at last incomplete checkpoint. Two backend gaps block full UX:

1. No way to fetch chat history for an existing `conversation_id` → resumed chat screen appears empty until next turn.
2. `POST /onboarding/complete` re-runs LLM extraction every call → resume-to-scenario-gift burns tokens + returns different scenario UUIDs each time.

## API Conventions

- **All JSON request/response keys use `snake_case`** (e.g., `conversation_id`, `turn_number`, `created_at`).
- Apply globally via existing response-transform interceptor / `class-transformer` `@Expose({ name: '...' })` mapping on DTOs.
- Internal TypeScript properties remain camelCase; only the wire shape is snake_case.
- Path params MAY be camelCase (`:conversationId`) — this rule applies to JSON bodies only.

---

## Endpoint 1 — GET Conversation Messages (MUST)

### Purpose
Return all messages for an anonymous onboarding conversation so mobile can rehydrate chat UI on resume.

### Spec

```
GET /onboarding/conversations/:conversationId/messages
```

**Auth:** `@Public()` (onboarding is pre-auth).
**Guard:** Apply existing `OnboardingThrottlerGuard` (prevent enumeration).
**Path param:** `conversationId` (UUID).

**Response 200:**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
    "turn_number": 3,
    "max_turns": 10,
    "is_last_turn": false,
    "messages": [
      {
        "id": "msg-uuid",
        "role": "assistant",
        "content": "Hello! ...",
        "created_at": "2026-04-14T23:20:00Z"
      },
      {
        "id": "msg-uuid",
        "role": "user",
        "content": "I want to learn English",
        "created_at": "2026-04-14T23:21:00Z"
      }
    ]
  }
}
```

**Response 404:** conversation not found (already the existing `NotFoundException` pattern).

### Implementation Notes
- Data already exists in `ai_conversation_messages` table (see `onboarding.service.ts:194-203` `getHistory()` for query pattern).
- Filter `type = ANONYMOUS` (match `findValidSession` constraint). Do NOT expose authenticated conversations here.
- Order ASC by `created_at`.
- Use `message_count` → compute `turn_number` using same logic as `chat()`: `msgCount === 0 ? 0 : Math.floor((msgCount - 1) / 2) + 1`.
- No `message` field required (read-only).
- Response serializer must convert any internal camelCase TypeORM fields to snake_case (use existing response interceptor / class-transformer config).

### Rate Limiting
- Reuse `OnboardingThrottlerGuard`. Additional per-conversation_id guard not needed (UUID guessing infeasible).

### Security
- `@Public()` acceptable because `conversation_id` is UUID v4 (unguessable) + anonymous-only filter.
- Return only `id`, `role`, `content`, `created_at` per message. Omit raw `metadata`, token counts, cost fields.

---

## Endpoint 2 — Idempotent Complete OR GET Profile (MUST)


### Make POST /onboarding/complete idempotent

**Change:** On second+ call with same `conversation_id`, return cached profile + scenarios instead of re-running LLM.

**Schema:** Add two columns to `ai_conversations` (or new `onboarding_profiles` table):
- `extracted_profile JSONB NULL`
- `scenarios JSONB NULL`

**Logic:**
```ts
async complete(dto) {
  const conv = await this.findValidSession(dto.conversationId);
  if (conv.extractedProfile && conv.scenarios) {
    return { ...conv.extractedProfile, scenarios: conv.scenarios };
  }
  // existing extraction + scenario generation
  const profile = this.parseExtraction(response);
  const scenarios = await this.generateScenarios(profile, conv.id);
  await this.conversationRepo.update(conv.id, {
    extractedProfile: profile,
    scenarios,
  });
  return { ...profile, scenarios };
}
```

> TS properties shown camelCase (TypeORM column names snake_case via `@Column({ name: 'extracted_profile' })`). Response serializer emits snake_case JSON keys per API convention.

**Why:** Scenario UUIDs stay stable across resumes (no mobile-side cache mismatch). Zero new endpoint. Saves LLM tokens.

## Endpoint 3 — (Optional) Session Metadata

**Purpose:** Let mobile check if conversation is alive before navigating user to chat screen (avoid flash of empty UI then restart).

```
GET /onboarding/conversations/:conversationId
```

**Response 200:**
```json
{
  "code": 1,
  "data": {
    "conversation_id": "...",
    "turn_number": 3,
    "max_turns": 10,
    "is_last_turn": false,
    "is_complete": true
  }
}
```

**Response 404:** invalid/missing.

**Skip if:** Endpoint 1 already returns this in its response (which it does). Treat a 404 from Endpoint 1 as "conversation dead." Endpoint 3 is redundant with Endpoint 1.

**Verdict:** Not needed. Mobile calls Endpoint 1 on resume; 404 → restart; 200 → hydrate.

---

## Summary — What Backend Must Ship

| # | Endpoint | Method | Status |
|---|----------|--------|--------|
| 1 | `/onboarding/conversations/:id/messages` | GET | **required** |
| 2 | `/onboarding/complete` | POST (make idempotent) | **required** |
| 3 | `/onboarding/conversations/:id` | GET | skip (redundant) |

## Database Migration

Single migration adds to `ai_conversations`:
```sql
ALTER TABLE ai_conversations
  ADD COLUMN extracted_profile JSONB NULL,
  ADD COLUMN scenarios JSONB NULL;
```

No backfill needed — existing rows compute on next `/complete` call.

## Testing (Backend-Side)

- Unit: `OnboardingService.getMessages(convId)` — returns ordered list, filters by ANONYMOUS type.
- Unit: `OnboardingService.complete()` second call returns cached row without LLM invocation (mock `UnifiedLLMService` not called).
- E2E: POST chat → GET messages → assert transcript matches. POST complete twice → assert second call is fast (<50ms) + identical output.

## Acceptance Criteria

- [ ] `GET /onboarding/conversations/:id/messages` returns full transcript for valid ANONYMOUS conversation
- [ ] Returns 404 for missing / non-anonymous conversation
- [ ] `POST /onboarding/complete` is idempotent — second call returns identical scenarios (same UUIDs) without LLM call
- [ ] Throttler guard applied to new GET endpoint
- [ ] Swagger docs updated for both endpoints
- [ ] Migration ran in dev + staging

## Non-Goals

- Server-side conversation TTL (not required by mobile; current behavior preserved).
- Endpoint for deleting a conversation (not needed — mobile just stops using the id).
- Paginating `messages` response (onboarding capped at 10 turns = ~21 messages; single response fine).

## Unresolved Questions

1. Preferred table: columns on `ai_conversations` vs new `onboarding_profiles` table? (Recommend: columns, simpler.)
2. Should `scenarios` JSONB include the `accent_color`/`icon` fields, or regenerate the presentation layer each call? (Recommend: store everything returned to client for full idempotency.)
3. Is there an existing convention for GET-by-id response wrapping? (Check `src/common/interceptors/` for response shape.)
