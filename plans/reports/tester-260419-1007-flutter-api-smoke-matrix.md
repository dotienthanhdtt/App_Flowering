# Flutter API Client — Production Smoke Test Matrix

**Date:** 2026-04-19 10:07 | **Branch:** feat/update-onboarding | **Scope:** endpoints actually invoked by the Flutter client (grep of `ApiEndpoints.*` usages)

**Prod base URL:** `https://api.flowering.app` (from `.env.prod` → `API_BASE_URL`)

**Response contract:** `{ "code": 1, "message": "...", "data": {...} }`. Pass = HTTP 2xx AND `code == 1`.

**Required headers:**
- `Authorization: Bearer <access_token>` — all endpoints except `/auth/*` and `/languages` (public list)
- `X-Learning-Language: <code>` — content-scoped endpoints (lessons, AI). Auth/meta endpoints skip it per `active-language-interceptor.dart:10-16`
- `Content-Type: application/json`, `Accept: application/json`

---

## Tier 1 — Public endpoints (no auth required)

| # | Method | Path | Body | Expect |
|---|---|---|---|---|
| 1 | GET | `/languages?type=native` | — | `data[]` with `code,name,native_name` |
| 2 | GET | `/languages?type=learning` | — | `data[]` non-empty |
| 3 | GET | `/languages` | — | `data[]` superset |
| 4 | POST | `/onboarding/chat` | `{}` (no conversationId) | `data.conversation_id` + greeting in `data.messages[]` |

## Tier 2 — Authed read-only (Bearer token, NO X-Learning-Language)

| # | Method | Path | Expect |
|---|---|---|---|
| 5 | GET | `/users/me` | `data.id`, `data.email` |
| 6 | GET | `/languages/user` | `data[]` (may be empty) |
| 7 | GET | `/subscriptions/me` | `data.status` |

## Tier 3 — Authed content (Bearer + X-Learning-Language: en)

| # | Method | Path | Expect |
|---|---|---|---|
| 8 | GET | `/lessons` | `data` with category-grouped lessons |

## Tier 4 — AI endpoints (authed, cost $ per call — run only if user confirms)

| # | Method | Path | Body | Expect |
|---|---|---|---|---|
| 9 | POST | `/ai/translate` | `{"text":"hello","source_lang":"en","target_lang":"vi"}` | `data.translation` string |
| 10 | POST | `/ai/chat/correct` | `{"text":"I is happy"}` | `data.corrections[]` |

## SKIPPED — mutating / expensive / requires fixtures

| Endpoint | Reason |
|---|---|
| `POST /languages/user` | writes user language |
| `PATCH /languages/user/native` | mutates |
| `PATCH/DELETE /languages/user/:id` | mutates |
| `POST /onboarding/complete` | creates user profile |
| `POST /ai/transcribe` | multipart + expensive |
| `GET /onboarding/conversations/:id/messages` | needs seeded conversation |
| `/auth/register`, `/auth/login`, `/auth/forgot-password`, `/auth/verify-otp`, `/auth/reset-password` | backend returns `410 Gone` (disabled) |
| `POST /auth/firebase` | requires live Firebase idToken exchange |
| `POST /auth/refresh` | would rotate test account's refresh token |
| `POST /auth/logout` | invalidates all tokens for user |
| `/chat/messages`, `/chat/send`, `/chat/voice`, `/progress*` | constants defined but no caller grep — likely dead endpoints |

---

## Pass/fail criteria per request

1. TCP/TLS connect OK (no timeout, no cert error)
2. HTTP status 2xx
3. Response body is valid JSON
4. Body has `code` field with value `1`
5. `data` field exists and matches expected shape (key presence only; deep schema check out of scope)
6. P95 response time < 3s for non-AI, < 10s for AI endpoints

A failure at any step = FAIL with specific reason.

## Open questions
- Confirm AI endpoints should be hit live (cost implications). Default: skip Tier 4 unless user passes `--include-ai`.
- Should `/auth/firebase` token exchange be smoke-tested? Requires live Firebase idToken — not currently feasible without running the Flutter app.
