# Onboarding API

Base path: `/onboarding`
Auth: All endpoints are **public** (no JWT required). Sessions are identified by `conversationId`.

---

## Flow Overview

```
POST /onboarding/chat       (Mode A — create)
  → body: {nativeLanguage, targetLanguage}
  → returns conversationId + greeting reply

POST /onboarding/chat       (Mode B — turn, repeat up to 10 times)
  → body: {conversationId, message}
  → returns AI reply

POST /onboarding/complete
  → body: {conversationId}
  → extract structured profile from conversation

POST /auth/register|login|firebase  (with conversationId)
  → link onboarding session to user account
```

> **Breaking change (2026-04-14):** `POST /onboarding/start` has been removed.
> Session creation is now handled by the same `/onboarding/chat` endpoint (Mode A) —
> one request produces the conversation + the first greeting.

---

## POST /onboarding/chat

Unified endpoint. Branches by presence of `conversationId` in the request body.

### Mode A — Create session + first turn (greeting)

**Request body**
```json
{
  "nativeLanguage": "vi",
  "targetLanguage": "en"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `nativeLanguage` | string | yes | ISO 639-1 native language code |
| `targetLanguage` | string | yes | ISO 639-1 target language code |

Notes:
- `conversationId` MUST be omitted or `null`.
- `message` (if sent) is silently ignored.

### Mode B — Subsequent chat turn

**Request body**
```json
{
  "conversationId": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Hi, I want to learn English for work"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `conversationId` | UUID | yes | From prior Mode A response |
| `message` | string | optional | User message (empty allowed on first follow-up) |

Notes:
- Language fields are ignored in this mode.

### Response (uniform for both modes)

```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "conversationId": "550e8400-e29b-41d4-a716-446655440000",
    "reply": "Hi! What language would you like to learn?",
    "messageId": "msg_a1b2c3",
    "turnNumber": 1,
    "isLastTurn": false
  }
}
```

| Field | Description |
|---|---|
| `conversationId` | Stable across the session; echoed in both modes |
| `reply` | AI message text (greeting on Mode A, response on Mode B) |
| `messageId` | Message ID for tracking (used by translate/grammar endpoints) |
| `turnNumber` | Current turn (1–10) |
| `isLastTurn` | `true` when max turns reached — client should trigger `/onboarding/complete` |

### Errors

| Status | Cause |
|---|---|
| 400 | Missing `nativeLanguage`/`targetLanguage` on create (no `conversationId`) |
| 400 | Session expired or max turns reached |
| 404 | `conversationId` invalid / not found |
| 404 | Any request to removed `/onboarding/start` |
| 429 | Rate limited |

### Rate limits (per IP)

| Mode | Limit |
|---|---|
| Create (no `conversationId`) | **5 requests/hour** |
| Chat (with `conversationId`) | **30 requests/hour** |

### curl

Mode A:
```bash
curl -X POST https://api.example.com/onboarding/chat \
  -H "Content-Type: application/json" \
  -d '{"nativeLanguage":"vi","targetLanguage":"en"}'
```

Mode B:
```bash
curl -X POST https://api.example.com/onboarding/chat \
  -H "Content-Type: application/json" \
  -d '{"conversationId":"550e8400-...","message":"Hello"}'
```

---

## POST /onboarding/complete

Extract a structured user profile from the onboarding conversation. Call after `isLastTurn: true`.

**Request body**
```json
{
  "conversationId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response 200**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "name": "Thanh",
    "nativeLanguage": "vi",
    "targetLanguage": "en",
    "currentLevel": "B1",
    "learningGoals": ["business communication", "travel"],
    "weeklyAvailability": "5 hours",
    "preferredTopics": ["technology", "sports"]
  }
}
```

If extraction fails, returns `{ "raw": "<ai response text>" }`.

**Errors**
- `404` — `conversationId` not found

---

## Session Lifecycle

| State | Description |
|---|---|
| `ANONYMOUS` | Active session not yet linked to a user account |
| `AUTHENTICATED` | Linked after user registers/logs in with `conversationId` |

- Session TTL: **7 days**
- Max turns: **10** (5 exchanges)
- Linking is best-effort; authentication succeeds even if linking fails

---

## Client Integration Notes

Flutter client (`lib/features/chat/controllers/ai_chat_controller.dart`):
- Single `_createSession()` call on `onInit` — no separate bootstrap/start call.
- `_mapOnboardingError` differentiates Mode A (5/hr) vs Mode B (30/hr) rate-limit copy.
- On 404/400: local session state is cleared so user can restart cleanly.
- Request bodies use **camelCase** keys.
