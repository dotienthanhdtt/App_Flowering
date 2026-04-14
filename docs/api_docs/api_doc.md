# API Documentation — Unimplemented Endpoints

**Last Updated:** 2026-04-14
**Base URL:** `http://localhost:3000` (development)
**API Version:** 1.8.0

> **Scope:** This document tracks backend endpoints **NOT yet implemented** in the Flutter app (`app_flowering/flowering/`). Implemented endpoints have been removed — refer to the backend repo (`be_flowering/`) or Swagger (`/api/docs`) for the full contract.

## Overview

RESTful API for AI-powered language learning application. All endpoints except webhooks and public auth require JWT authentication via Bearer token. All responses wrapped in standard format: `{code: 1, message, data}` (code 1 = success, 0 = error).

## Response Format

### Success Response (code: 1)
```json
{
  "code": 1,
  "message": "Success message",
  "data": {...}
}
```

### Error Response (code: 0)
```json
{
  "code": 0,
  "message": "Error description",
  "data": null
}
```

### JSON Key Naming

**All JSON keys (request body params and response data fields) use `snake_case`.** Internally DTOs use camelCase; a request middleware (`SnakeToCamelCaseMiddleware`) and response interceptor (`ResponseTransformInterceptor`) convert between the two transparently.

URL path params use camelCase (e.g., `:scenarioId`, `:languageId`, `:sessionId`). Query-string keys use snake_case (e.g., `?language_code=en`).

## Authentication

### Bearer Token Format
```
Authorization: Bearer <jwt_token>
```

- Default expiry: 7 days
- Algorithm: HS256
- Public routes: Use @Public() decorator

---

## Endpoints

### Health Check

#### GET /
Liveness/health probe. Used by load balancers and Railway deploy checks.

**Auth:** Not required | **Response (200):**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "status": "ok",
    "timestamp": "2026-04-14T09:00:00.000Z"
  }
}
```

---

### Authentication

#### POST /auth/logout
Invalidate refresh token.

**Auth:** Required | **Response (204):** No content

---

### User Management

#### PATCH /users/me
Update user profile.

**Auth:** Required | **Request:**
```json
{
  "display_name": "Jane Doe",
  "avatar_url": "https://example.com/avatar.jpg",
  "native_language_id": "uuid"
}
```

All fields optional. **Response (200):**
```json
{
  "code": 1,
  "message": "User updated",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "display_name": "Jane Doe",
    "avatar_url": "https://example.com/avatar.jpg",
    "email_verified": true,
    "native_language_id": "uuid",
    "native_language_code": "en",
    "native_language_name": "English",
    "created_at": "2026-03-01T10:00:00.000Z"
  }
}
```

---

### Subscriptions (Webhook)

#### POST /webhooks/revenuecat
RevenueCat webhook endpoint (idempotency via WebhookEvent table). Not called by the app — consumed by RevenueCat service.

**Auth:** Bearer token (REVENUECAT_WEBHOOK_SECRET; not a JWT) | **Request:**
```json
{
  "event": {
    "id": "event_uuid",
    "type": "INITIAL_PURCHASE|RENEWAL|CANCELLATION|EXPIRATION|PRODUCT_CHANGE",
    "app_user_id": "user_uuid",
    "original_app_user_id": "user_uuid",
    "environment": "PRODUCTION",
    "product_id": "monthly_subscription",
    "purchased_at_ms": 1706976000000,
    "expiration_at_ms": 1709654400000
  }
}
```

**Response (200):** `{code: 1, message: "Webhook received", data: {status: "received"}}`

**Processing:** Async (responds <60s)

---

### Languages (User)

#### GET /languages/user
Get the caller's learning languages.

**Auth:** Required | **Response (200):** `{code: 1, message: "User languages found", data: [{id, language: {...}, proficiency_level, is_active}]}`

---

#### POST /languages/user
Add language to the caller's learning list.

**Auth:** Required | **Request:**
```json
{
  "language_id": "uuid",
  "proficiency_level": "beginner|intermediate|advanced|native"
}
```

**Response (201):** `{code: 1, message: "Language added", data: {...}}`

---

#### PATCH /languages/user/:languageId
Update language proficiency.

**Auth:** Required | **Request:**
```json
{
  "proficiency_level": "intermediate"
}
```

**Response (200):** `{code: 1, message: "Language updated", data: {...}}`

---

#### PATCH /languages/user/native
Set native language.

**Auth:** Required | **Request:**
```json
{
  "language_id": "uuid"
}
```

**Response (200):** `{code: 1, message: "Native language set", data: {...}}`

---

#### DELETE /languages/user/:languageId
Remove language.

**Auth:** Required | **Response (200):** `{code: 1, message: "Language removed", data: null}`

---

### AI Features

#### POST /ai/chat
Chat with AI tutor.

**Auth:** Required (Premium) | **Rate Limit:** default global throttler | **Request:**
```json
{
  "message": "How do I use the past tense in Spanish?",
  "context": {
    "conversation_id": "uuid",
    "target_language": "Spanish",
    "native_language": "English",
    "proficiency_level": "beginner",
    "lesson_topic": "Past tense"
  },
  "model": "gpt-4o"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| message | string | Yes | User message (max 4000 chars) |
| context.conversation_id | UUID | Yes | Conversation session id |
| context.target_language | string | Yes | Language being learned |
| context.native_language | string | Yes | User's native language |
| context.proficiency_level | string | Yes | `beginner|elementary|intermediate|upper-intermediate|advanced` |
| context.lesson_topic | string | No | Current lesson topic |
| model | enum | No | Override default LLM (see `LLMModel` enum) |

**Response (200):** `{code: 1, message: "Success", data: {message, conversation_id}}`

---

#### SSE /ai/chat/stream
Stream chat response (Server-Sent Events).

**Auth:** Required (Premium) | **Request:** Same shape as `POST /ai/chat`

**Response:** text/event-stream. Each event payload: `{ "data": { "content": "<chunk>" } }`.

---

### Scenario Chat

Engage in roleplay conversations within scenario-based learning activities.

#### POST /scenario/chat
Conduct a turn in a scenario roleplay conversation.

**Auth:** Required (Premium) | **Rate Limit:** 20 req/min, 100 req/hr | **Request:**
```json
{
  "scenario_id": "uuid",
  "message": "I need a table for two",
  "conversation_id": "uuid",
  "force_new": false
}
```

| Field | Type | Required | Limit | Description |
|-------|------|----------|-------|-------------|
| scenario_id | UUID | Yes | - | ID of scenario to engage with |
| message | string | No | 2000 chars | User's roleplay response (omit on first turn to let AI open) |
| conversation_id | UUID | No | - | Conversation ID to resume existing session |
| force_new | boolean | No | - | Abandon any active conversation for this scenario and start fresh. Cannot combine with `conversation_id`. |

**Response (200):**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "reply": "Of course! A table for two right away. This way, please.",
    "conversation_id": "uuid",
    "turn": 1,
    "max_turns": 12,
    "completed": false
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| reply | string | AI roleplay response |
| conversation_id | UUID | Conversation session ID |
| turn | number | Current turn number (1-based) |
| max_turns | number | Maximum turns for this conversation |
| completed | boolean | True when max turns reached |

**Behavior:**
- First turn: Omit `message` parameter; AI initiates the roleplay
- Subsequent turns: Include `message` parameter
- Resume conversation: Provide `conversation_id` from previous turn
- Conversation ends when `completed: true`
- Re-practice: send `force_new: true` to abandon the active conversation and start fresh
- Premium subscription required

**Errors:**
- 400 (conversation completed, invalid body, scenario not found, or `force_new` combined with `conversation_id`)
- 401 (missing/invalid JWT)
- 403 (free user trying premium scenario)
- 404 (scenario not found)

---

#### GET /scenario/:scenarioId/conversations
List the caller's past conversations for one scenario (newest first).

**Auth:** Required | **Rate Limit:** none (non-AI endpoint)

**Response (200):**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "items": [
      {
        "id": "uuid",
        "started_at": "2026-04-14T09:00:00.000Z",
        "last_turn_at": "2026-04-14T09:15:00.000Z",
        "turn_count": 5,
        "completed": false,
        "max_turns": 12
      }
    ]
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Conversation id |
| started_at | ISO date | When the conversation was created |
| last_turn_at | ISO date | Timestamp of the most recent activity |
| turn_count | number | Completed user/assistant turn pairs so far |
| completed | boolean | True when the turn cap has been reached |
| max_turns | number | Turn cap for this conversation |

**Behavior:**
- Owner-filter only: returns only conversations owned by the caller
- No premium gate: downgraded users can still review their own history
- Empty array when the user has never engaged with the scenario

**Errors:** 401 (missing/invalid JWT)

---

#### GET /scenario/conversations/:id
Fetch a single conversation transcript (owner only).

**Auth:** Required | **Rate Limit:** none (non-AI endpoint)

**Response (200):**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "id": "uuid",
    "scenario_id": "uuid",
    "completed": true,
    "turn": 12,
    "max_turns": 12,
    "messages": [
      { "role": "assistant", "content": "Welcome!", "created_at": "2026-04-14T09:00:00.000Z" },
      { "role": "user", "content": "Thanks", "created_at": "2026-04-14T09:00:05.000Z" }
    ]
  }
}
```

**Behavior:**
- Owner-check: 403 if the conversation belongs to another user
- Returns full transcript in chronological order
- Filters out any `system` role messages

**Errors:** 401 (missing/invalid JWT), 403 (conversation owned by another user), 404 (conversation not found)

---

### Vocabulary (Spaced Repetition & CRUD)

**Auth:** Required | **Rate Limit:** None (non-AI endpoint)

#### GET /vocabulary
List user's vocabulary with optional filters and pagination.

**Query params:**
- `language_code` (optional) — Filter by source/target language (e.g., "en", "es")
- `box` (optional, 1-5) — Filter by Leitner box number
- `search` (optional) — Search word or translation (substring)
- `page` (optional, default: 1) — Page number
- `limit` (optional, default: 20, max: 100) — Items per page

**Response (200):**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "items": [
      {
        "id": "uuid",
        "word": "beautiful",
        "translation": "hermoso",
        "source_lang": "en",
        "target_lang": "es",
        "part_of_speech": "adjective",
        "pronunciation": "byoo-tuh-fuhl",
        "definition": "pleasing to look at",
        "examples": ["It was a beautiful day.", "She looked beautiful."],
        "box": 2,
        "due_at": "2026-04-15T10:00:00Z",
        "last_reviewed_at": "2026-04-12T10:00:00Z",
        "review_count": 5,
        "correct_count": 4,
        "created_at": "2026-03-28T10:00:00Z"
      }
    ],
    "total": 42,
    "page": 1,
    "limit": 20
  }
}
```

**Errors:** 401 (unauthorized)

---

#### GET /vocabulary/:id
Get a single vocabulary item.

**Response (200):**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "id": "uuid",
    "word": "beautiful",
    "translation": "hermoso",
    "source_lang": "en",
    "target_lang": "es",
    "part_of_speech": "adjective",
    "pronunciation": "byoo-tuh-fuhl",
    "definition": "pleasing to look at",
    "examples": ["It was a beautiful day."],
    "box": 2,
    "due_at": "2026-04-15T10:00:00Z",
    "last_reviewed_at": "2026-04-12T10:00:00Z",
    "review_count": 5,
    "correct_count": 4,
    "created_at": "2026-03-28T10:00:00Z"
  }
}
```

**Errors:** 401 (unauthorized), 404 (not found or not owned)

---

#### DELETE /vocabulary/:id
Delete a vocabulary item.

**Response (204):** No content

**Errors:** 401 (unauthorized), 404 (not found or not owned)

---

#### POST /vocabulary/review/start
Start a Leitner SRS review session. Returns due vocabulary cards for review.

**Auth:** Required | **Request:**
```json
{
  "language_code": "en",
  "limit": 10
}
```

| Field | Type | Required | Limit | Description |
|-------|------|----------|-------|-------------|
| language_code | string | No | 10 chars | Filter cards by language; defaults to all |
| limit | number | No | max 100 | Max cards per session (default: 20) |

**Response (201):**
```json
{
  "code": 1,
  "message": "Session started",
  "data": {
    "session_id": "session-uuid-1234",
    "cards": [
      {
        "vocab_id": "uuid",
        "word": "beautiful",
        "translation": "hermoso",
        "pronunciation": "byoo-tuh-fuhl",
        "part_of_speech": "adjective",
        "definition": "pleasing to look at",
        "examples": ["It was a beautiful day."],
        "box": 1,
        "source_lang": "en",
        "target_lang": "es"
      }
    ],
    "total": 3
  }
}
```

**Behavior:**
- Session TTL: 1 hour
- Returns cards where `due_at <= NOW()` ordered by box priority
- Session ID used for rating and completion endpoints

**Errors:** 401 (unauthorized)

---

#### POST /vocabulary/review/:sessionId/rate
Rate a card in a review session (correct/incorrect).

**Auth:** Required | **Request:**
```json
{
  "vocab_id": "uuid",
  "correct": true
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| vocab_id | UUID | Yes | Vocabulary ID from session cards |
| correct | boolean | Yes | true = correct, false = incorrect |

**Response (201):**
```json
{
  "code": 1,
  "message": "Card rated",
  "data": {
    "updated": {
      "box": 2,
      "due_at": "2026-04-15T10:00:00Z"
    },
    "remaining": 2
  }
}
```

**Leitner Transitions:**
| From Box | Correct | New Box | Interval |
|----------|---------|---------|----------|
| 1 | yes | 2 | +3 days |
| 2 | yes | 3 | +7 days |
| 3 | yes | 4 | +14 days |
| 4 | yes | 5 | +30 days |
| 5 | yes | 5 | +30 days |
| 1-5 | no | 1 | +1 day |

**Errors:**
- 400 (vocab not in session, already rated, invalid body)
- 401 (unauthorized)
- 403 (vocab not owned)
- 404 (session expired, vocab missing)

---

#### POST /vocabulary/review/:sessionId/complete
Complete a review session. Returns stats.

**Auth:** Required | **Response (201):**
```json
{
  "code": 1,
  "message": "Review completed",
  "data": {
    "total": 5,
    "correct": 4,
    "wrong": 1,
    "accuracy": 80,
    "box_distribution": [
      { "box": 1, "count": 0 },
      { "box": 2, "count": 2 },
      { "box": 3, "count": 1 },
      { "box": 4, "count": 1 },
      { "box": 5, "count": 1 }
    ]
  }
}
```

**Behavior:**
- Session is deleted after completion
- box_distribution shows final box counts of all reviewed cards
- Deleted session cannot be resumed

**Errors:** 401 (unauthorized), 404 (session not found)

---

## Error Codes

| Code | Status | Meaning |
|------|--------|---------|
| 200 | OK | Request successful |
| 201 | Created | Resource created |
| 400 | Bad Request | Invalid input |
| 401 | Unauthorized | Missing/invalid token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource exists |
| 500 | Server Error | Internal error |
| 503 | Service Unavailable | External service down |

## Rate Limiting

**AI Endpoints:**
- Free users: 100 requests/hour
- Premium users: 1000 requests/hour
- Per-user rate limiting enforced

## Interactive Documentation

**Swagger UI:** Available at `/api/docs` in development mode.

## Implementation Status

The following endpoints are **already implemented** in the Flutter app and have been removed from this document (see source references in `lib/`):

- `POST /auth/register` · `POST /auth/login` · `POST /auth/firebase` · `POST /auth/refresh`
- `POST /auth/forgot-password` · `POST /auth/verify-otp` · `POST /auth/reset-password`
- `GET /users/me`
- `GET /subscriptions/me`
- `GET /languages`
- `GET /lessons`
- `POST /ai/translate` · `POST /ai/chat/correct` · `POST /ai/transcribe`
- `POST /onboarding/chat` · `POST /onboarding/complete`
