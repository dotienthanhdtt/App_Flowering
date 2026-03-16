# Brainstorm Report — Onboarding Second Half

**Date:** 2026-02-28
**Branch:** feat/onboarding-first-half
**Scope:** Screens 07–14 (AI Chat → Auth flow)

---

## 1. Problem Statement

First half (screens 01–06) is complete. Second half needs:
- Screen 07: AI Chat — connect to real `/onboarding/*` APIs (replace mock)
- Screen 08: Scenario Gift — display 5 AI-generated personalized scenarios
- Screen 09: Login Gate — bottom sheet modal over dimmed scenarios
- Screen 10: Signup Email — full registration form
- Screen 11: Login Email — login form + social options
- Screen 12–14: Forgot Password → OTP → New Password flow

---

## 2. Clarified Feature Decisions

| Question | Decision |
|---|---|
| Scenario Gift data source | Extend `/onboarding/complete` response to include `scenarios[]` array |
| Forgot password endpoints | Missing — add to `api_needed.md`, implement after backend builds them |
| Chat integration | Connect to real API (replace scripted mock) |
| Language data | Use real `GET /languages` API (not hardcoded mock) |

---

## 3. Revised Flow

```
07_ai_chat (real /onboarding/start + /onboarding/chat)
  → when isLastTurn=true: call /onboarding/complete
  → 08_scenario_gift (show scenarios[] from complete response)
  → 09_login_gate (bottom sheet)
      ├── Apple → POST /auth/apple (+ sessionToken)
      ├── Google → POST /auth/google (+ sessionToken)
      └── Email → 10_signup_email → POST /auth/register (+ sessionToken)
                  Already have account? → 11_login_email → POST /auth/login (+ sessionToken)
                                              Forgot? → 12_forgot_password
                                                         → POST /auth/forgot-password
                                                         → 13_otp_verification
                                                         → POST /auth/verify-otp
                                                         → 14_new_password
                                                         → POST /auth/reset-password
```

After any auth success → `/home` (store accessToken + refreshToken in AuthStorage)

---

## 4. Session Token State Management

`sessionToken` (from `/onboarding/start`) must persist across screens 07 → 09/10/11.

**Approach:** Store in `OnboardingController` (GetX, kept alive) + `StorageService` (Hive) as fallback.
- Key: `onboarding_session_token`
- Clear after successful auth linking

---

## 5. Language API Integration (Screens 05, 06)

**Change:** Replace mock lists in `onboarding_language_model.dart` with real data from `GET /languages`.
- Fetch on screen load, show loading skeleton
- Cache in StorageService for 24h (languages rarely change)
- Offline fallback: use cached or minimal hardcoded fallback list

---

## 6. AI Chat Screen Changes (Screen 07)

Current mock-scripted flow → real API flow:

| Step | Action |
|---|---|
| Screen open | Call `POST /onboarding/start` with selected languages → store `sessionToken` |
| User sends message | Call `POST /onboarding/chat` → show Flora's reply |
| isLastTurn=true | After last reply, call `POST /onboarding/complete` → navigate to scenario gift |
| Progress bar | Based on `turnNumber / 10` (max 10 turns) |
| Error handling | Show retry on network failure; session expired → restart onboarding |

---

## 7. Scenario Gift Screen (Screen 08)

- Receives `OnboardingProfile` (with `scenarios[]`) from controller
- Shows 5 cards in scrollable list with color-coded accent icons
- Single CTA: "Start Practicing →" → shows Login Gate bottom sheet (Screen 09)
- Scenarios stored in controller state (no persistence needed)

---

## 8. Login Gate — Bottom Sheet (Screen 09)

- Shown as overlay on top of Scenario Gift (dimmed background effect)
- Three auth paths: Apple → Google → Email
- All pass `sessionToken` to link onboarding session
- "Already have an account?" → Login Email (Screen 11)
- Social auth needs platform SDKs (google_sign_in, sign_in_with_apple packages)

---

## 9. Auth Screens (10, 11)

**Signup (10):** fullName, email, password, confirmPassword → `POST /auth/register`
- Client-side validation: email format, password ≥ 8 chars, passwords match
- On 409: show "Email already registered" error

**Login (11):** email, password → `POST /auth/login`
- Social options: Apple + Google (same as bottom sheet)
- "Forgot password?" → Screen 12

---

## 10. Forgot Password Flow (12→13→14)

**Backend endpoints missing** — documented in `docs/api_docs/api_needed.md`:
- `POST /auth/forgot-password` — sends 6-digit OTP email
- `POST /auth/verify-otp` — returns `resetToken`
- `POST /auth/reset-password` — sets new password

**OTP UX:** 6 individual character boxes, auto-advance on input, 47s countdown with resend.

---

## 11. API Constants to Add

See `docs/api_docs/api_needed.md` Section C. Missing from `api_endpoints.dart`:
- `/auth/google`, `/auth/apple`
- `/auth/forgot-password`, `/auth/verify-otp`, `/auth/reset-password`
- All `/languages/*` endpoints
- All `/onboarding/*` endpoints

---

## 12. Implementation Risks

| Risk | Mitigation |
|---|---|
| Backend not ready (forgot password, scenarios) | Implement screens with TODO stubs; unblock auth flow first |
| Social auth SDK setup (Google, Apple) | Requires native config (iOS plist, Android manifest) — scope separately |
| `sessionToken` loss between screens | Store in both controller + Hive; validate before each call |
| 10-turn chat limit | UI must handle isLastTurn gracefully (disable input, show completion) |

---

## 13. Recommended Implementation Order

1. Add missing constants to `api_endpoints.dart`
2. Connect language selection (05, 06) to real `GET /languages` API
3. Replace AI Chat mock with real `/onboarding/*` API flow
4. Build Scenario Gift screen (08)
5. Build Login Gate bottom sheet (09)
6. Build Signup + Login screens (10, 11)
7. Build Forgot Password flow (12–14) — blocked on backend

---

## Next Steps

- [ ] Create implementation plan for second half
- [ ] Backend team: implement 3 forgot-password endpoints + extend `/onboarding/complete` with `scenarios[]`
- [ ] Add google_sign_in + sign_in_with_apple packages to pubspec.yaml
