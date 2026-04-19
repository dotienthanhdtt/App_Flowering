# Phase 02 — C1 Payload Casing Inconsistency (snake_case)

## Context Links

- Report: `plans/reports/code-reviewer-260419-2022-feat-update-onboarding-5-commits.md` (C1)
- Report: `plans/reports/code-review-260419-2021-feat-update-onboarding-summary.md`
- Code: `lib/features/chat/controllers/ai_chat_controller.dart:294-296, 384, 467`

## Overview

- Priority: Critical
- Status: pending
- Payloads to `/ai/translate`, `/onboarding/complete`, word-translation mix camelCase and snake_case. Server expects snake_case.

## Key Insights

- Decision locked: snake_case wins. All callers convert.
- Two sites post `/onboarding/complete`: `refetchProfileIfNeeded` and `_finalizeOnboarding` — must match.

## Requirements

Functional
- All request bodies to the three endpoints use snake_case keys.
- Both onboarding callers emit identical key set.

Non-functional
- No runtime conversion helper required; hardcoded snake keys are simpler (YAGNI).

## Related Code Files

Modify
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/features/chat/controllers/ai_chat_controller.dart`
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/features/onboarding/controllers/onboarding_controller.dart` (if emits `/onboarding/complete`)
- Any other caller found via grep for `conversationId:` or `/onboarding/complete` / `/ai/translate`.

Create
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/test/features/chat/payload_casing_test.dart`

## Implementation Steps

1. Grep codebase for: `conversationId:`, `/ai/translate`, `/onboarding/complete`, word-translation endpoint URL.
2. For each call site, rewrite request body keys to snake_case (`conversation_id`, `source_text`, `target_lang`, etc.).
3. Ensure both onboarding callers emit same schema (lock canonical key list in phase commit).
4. Verify response parsing still uses `fromJson` / server-defined keys (not affected).
5. Add snapshot-style tests using mocked Dio intercept capture.

## Todo List

- [ ] Grep all camelCase keys in outbound payloads
- [ ] Rewrite `/ai/translate` payload (chat controller)
- [ ] Rewrite word-translation payload
- [ ] Rewrite `/onboarding/complete` at both call sites
- [ ] Add request-body snapshot tests for 3 endpoints
- [ ] `flutter analyze` clean

## Success Criteria

- Captured request bodies show only snake_case keys for the 3 endpoints.
- Both onboarding callers emit identical key set (diff = ∅).
- Backend smoke (manual) returns 200 for all 3.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Missed caller still sends camelCase | Med | High (500s) | Grep coverage + tests per endpoint |
| Mismatched key between onboarding callers | Med | High (data loss) | Explicit canonical constant or helper |

## Security Considerations

- None directly. Ensure no PII added to keys during rewrite.

## Next Steps / Dependencies

- Land before Phase 6 to reduce merge conflict risk in onboarding finalize path.
