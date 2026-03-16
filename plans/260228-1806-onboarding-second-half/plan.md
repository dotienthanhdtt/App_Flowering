---
title: "Onboarding Second Half — Screens 07-14"
description: "Connect AI Chat to real APIs, build Scenario Gift, Login Gate, Auth screens, and Forgot Password flow"
status: completed
priority: P1
effort: 16h (actual: 15.5h)
branch: feat/onboarding-first-half
tags: [feature, frontend, onboarding, auth]
created: 2026-02-28
completed: 2026-02-28
---

# Onboarding Second Half — Screens 07-14

## Overview

Complete the onboarding flow by connecting AI Chat to real APIs, building Scenario Gift display, Login Gate bottom sheet, full auth screens (signup/login), and forgot password flow.

**Source:** [brainstorm report](../reports/brainstorm-260228-1742-onboarding-second-half.md)

## Flow

```
07_ai_chat (real /onboarding/start + /chat + /complete)
  → 08_scenario_gift (5 AI-generated scenario cards)
  → 09_login_gate (bottom sheet: Apple / Google / Email)
      ├── 10_signup_email → POST /auth/register
      └── 11_login_email → POST /auth/login
              └── 12_forgot_password → 13_otp → 14_new_password
After auth success → /home
```

## Phases

| # | Phase | Status | Effort | Link |
|---|-------|--------|--------|------|
| 1 | Foundation — routes, models, translations | Completed | 2h | [phase-01](./phase-01-foundation-routes-models.md) |
| 2 | Language API integration (screens 05-06) | Completed | 2h | [phase-02](./phase-02-language-api-integration.md) |
| 3 | AI Chat real API (screen 07) | Completed | 3h | [phase-03](./phase-03-ai-chat-real-api.md) |
| 4 | Scenario Gift screen (screen 08) | Completed | 2h | [phase-04](./phase-04-scenario-gift-screen.md) |
| 5 | Auth feature — gate, signup, login (screens 09-11) | Completed | 4h | [phase-05](./phase-05-auth-feature.md) |
| 6 | Forgot Password flow (screens 12-14) | Completed | 3h | [phase-06](./phase-06-forgot-password-flow.md) |

## Dependencies

- Phase 1 → all other phases (foundation)
- Phase 2 → Phase 3 (languages must load before chat start)
- Phase 3 → Phase 4 (chat completes → scenario gift)
- Phase 4 → Phase 5 (scenario gift → login gate)
- Phase 5 → Phase 6 (login screen → forgot password)
- Social auth (Google/Apple SDKs) → separate scope, use TODO stubs
- Forgot password backend endpoints → may not be ready, implement UI with TODO stubs

## Key Decisions

- `sessionToken` stored in OnboardingController + StorageService (Hive fallback)
- OnboardingController kept alive via `permanent: true` (not `fenix: true`) to preserve state across screens
- Language data cached 24h in StorageService; hardcoded fallback for offline
- All new screens follow existing StatelessWidget + GetxController pattern
- Social auth packages (google_sign_in, sign_in_with_apple) added to pubspec.yaml now; handlers as TODO stubs
- Forgot password screens built now (will show API errors until backend deploys)
- TopicChipGrid widget removed entirely — real API uses quick replies instead

---

## Validation Log

### Session 1 — 2026-02-28
**Trigger:** Post-plan validation before implementation
**Questions asked:** 4

#### Questions & Answers

1. **[Architecture]** How should we persist OnboardingController state (sessionToken, selected languages, profile) across screens 05-14?
   - Options: permanent:true | StorageService only | fenix:true + init restore
   - **Answer:** permanent: true
   - **Rationale:** `fenix: true` re-creates with fresh state after GC — unusable for stateful flow. `permanent: true` keeps the single instance alive throughout onboarding.

2. **[Scope]** Should we add social auth packages to pubspec.yaml now?
   - Options: Add packages now | Defer entirely | Add + implement
   - **Answer:** Add packages now
   - **Rationale:** Packages in pubspec unblocks native config work. Handlers stay as TODO stubs.

3. **[Risk]** Should we build forgot password screens now (backend not ready)?
   - Options: Build now | Defer to separate PR
   - **Answer:** Build now
   - **Rationale:** UI complete, API calls fail gracefully. Unblocks testing when backend deploys.

4. **[Architecture]** Should we remove TopicChipGrid widget from AI Chat?
   - Options: Remove entirely | Keep but hide | Repurpose for quick replies
   - **Answer:** Remove entirely
   - **Rationale:** Real API handles topics through conversation turns. Quick replies from API replace manual selection.

#### Confirmed Decisions
- OnboardingController persistence: `permanent: true` — avoids state loss
- Social auth: add packages now, implement later — reduces future overhead
- Forgot password: build now — parallel work while waiting for backend
- Topic chips: remove entirely — dead code after API migration

#### Impact on Phases
- Phase 01: Change `fenix: true` → `permanent: true` in OnboardingBinding
- Phase 01: Add google_sign_in + sign_in_with_apple to pubspec.yaml
- Phase 03: Delete TopicChipGrid widget + related code
- Phase 06: No changes needed (already planned to build with API calls)
