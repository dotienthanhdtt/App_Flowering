# QA Report — Flutter API Client Smoke Test

**Date:** 2026-04-19 10:07 | **Branch:** feat/update-onboarding | **Tester:** main session

## ⚠ Environment tested = DEV, not PROD

User-supplied base URL: `https://dev.broduck.me` (matches `.env.dev`).
Configured production URL: `https://api.flowering.app` (`.env.prod`).
**Action:** re-run the runner with `BASE_URL=https://api.flowering.app` and a prod-issued token before shipping any claim of "production verified".

## Result

| Metric | Value |
|---|---|
| Endpoints designed | 10 (+ 13 skipped-by-design) |
| Endpoints executed | 10 |
| **Pass** | **9** |
| Fail | 0 |
| Skip (runtime) | 1 — `GET /lessons` (test account has 0 enrolled languages) |

## Runtime detail

```
Tier 1 — Public
  PASS GET    /languages?type=native           430 ms
  PASS GET    /languages?type=learning         282 ms
  PASS GET    /languages                       294 ms
  PASS POST   /onboarding/chat                1854 ms   (first-turn greeting)

Tier 2 — Authed read-only (Bearer)
  PASS GET    /users/me                        404 ms
  PASS GET    /languages/user                  373 ms
  PASS GET    /subscriptions/me                401 ms

Tier 3 — Authed content (Bearer + X-Learning-Language)
  SKIP GET    /lessons                                  test account has zero enrolled languages
                                                         → auto-skipped by runner (correct prerequisite check)

Tier 4 — AI (Bearer + X-Learning-Language)
  PASS POST   /ai/translate                   3282 ms
  PASS POST   /ai/chat/correct                2745 ms
```

Response times: non-AI **p95 ≈ 430 ms**, public p95 ≈ 300 ms. AI endpoints within the 10 s budget.

## Findings (non-blocking, discovered during smoke design)

1. **`POST /ai/translate` returns HTTP 500 on invalid payload.** When the request omits `type` or uses the wrong key, Nest returns `"Cannot read properties of undefined (reading 'toLowerCase')"` with status 500. Expected: 400 with a class-validator message. Root cause: `translate-request.dto.ts:25` calls `.toLowerCase()` on `o.type` inside `@ValidateIf` before validation confirms `type` is a string. Low risk (only hit by malformed clients) but should be fixed.

2. **Error messages on validation 400s leak internal field names** (e.g. "previousAiMessage must be ..."). Acceptable for a private API — flag only if a consumer-facing changelog requires snake_case surfaces.

3. **`api_endpoints.dart` has stale constants** — `chatMessages`, `chatSend`, `chatVoice`, `progress`, `stats` are defined but have **zero callers** (grep confirmed). Candidate for deletion per YAGNI.

4. **`/lessons` prerequisite is real user state.** The 403 on first attempt was correct backend behavior — the test account simply has no learning language enrolled. To cover this path in smoke, either (a) keep a dedicated test account with a stable enrolled language, or (b) have the runner enroll a language before testing and un-enroll after (requires DELETE).

## Deliverables

- `scripts/api-smoke-test.sh` — reusable smoke runner. Accepts `BASE_URL`, `ACCESS_TOKEN`, `LEARNING_LANG`, `--include-ai`. Auto-detects enrolled language via `GET /languages/user` to pick the right `X-Learning-Language`. Read-only against user data.
- `plans/reports/tester-260419-1007-flutter-api-smoke-matrix.md` — endpoint-by-endpoint test case matrix.
- This report.

## Coverage — what was NOT tested and why

| Endpoint | Reason |
|---|---|
| `POST /languages/user`, `PATCH /languages/user/native`, `PATCH/DELETE /languages/user/:id` | Writes to user data. Out of smoke scope. |
| `POST /onboarding/complete` | Creates profile (mutation). |
| `POST /ai/transcribe` | Multipart upload + $$$ per call. |
| `GET /onboarding/conversations/:id/messages` | Needs seeded conversation ID. |
| `/auth/register`, `/auth/login`, `/auth/forgot-password`, `/auth/verify-otp`, `/auth/reset-password` | Backend returns 410 (deprecated). Test = verify 410 if desired. |
| `POST /auth/firebase` | Needs live Firebase idToken; only meaningful from a running device/emulator. |
| `POST /auth/refresh` | Would rotate the test account's refresh token. |
| `POST /auth/logout` | Invalidates all tokens for user. |
| `/chat/*`, `/progress*` | Stale constants, no callers in Flutter code. |

## Recommendations

1. **Re-run against `https://api.flowering.app`** with a prod-issued token to complete the original "prod" objective.
2. **Fix `/ai/translate` 500 → 400** — trivial guard on `o.type` inside `ValidateIf` (`typeof o.type === 'string' && ...`).
3. **Enroll the test account in at least one language** (e.g., `en`) so `/lessons` can be covered on every run.
4. **Remove stale endpoint constants** from `api_endpoints.dart:44-55` (`chatMessages`, `chatSend`, `chatVoice`, `progress`, `stats`).
5. **Wire the runner into CI** as a post-deploy gate (requires a dedicated test-account credential in CI secrets).

## Security note on the shared token

The Bearer token shared in this session is for `dotienthanhdtt@gmail.com` (sub `89c0be08-…`) and expires **2026-05-10** (~21 days from now per `exp` claim). Recommend logging that session out after this test to force rotation, since the raw token now lives in the conversation transcript.

## Open questions

- Should `/auth/firebase` be smoke-tested via a service account or skipped permanently from backend smoke (only tested via Flutter integration tests)?
- Should the smoke runner gain a `--mutation` mode that creates + tears down test artefacts (language enrollment, onboarding completion) against an ephemeral test user, to close the write-path coverage gap?
