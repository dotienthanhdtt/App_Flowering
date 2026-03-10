# Chat Grammar Correction Feature

**Date:** 2026-03-10
**Status:** ✅ Complete
**Brainstorm:** `plans/reports/brainstorm-260310-1936-chat-grammar-correction.md`

---

## Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | Model + Endpoint + Controller | ✅ Complete |
| 2 | UI — UserMessageBubble correction section | ✅ Complete |
| 3 | Screen — Wire up message + callback | ✅ Complete |
| 4 | Translations | ✅ Complete |

## Files to Modify

1. `lib/features/chat/models/chat_message_model.dart` — Add `correctedText`, `showCorrection`
2. `lib/core/constants/api_endpoints.dart` — Add `chatCorrect`
3. `lib/features/chat/controllers/ai_chat_controller.dart` — Parallel grammar check + toggle
4. `lib/features/chat/widgets/user_message_bubble.dart` — Correction UI section
5. `lib/features/chat/views/ai_chat_screen.dart` — Pass message object + callback
6. `lib/l10n/english-translations-en-us.dart` — Add translation keys
7. `lib/l10n/vietnamese-translations-vi-vn.dart` — Add translation keys

## Success Criteria

- [x] Correction API called in parallel with chat API on every user message
- [x] If errors found: correction UI appears inside user bubble matching design
- [x] If no errors: no visual change to user bubble
- [x] Hide/Show toggle works correctly
- [x] Correction API failure doesn't break chat flow
- [x] No compile errors, app runs normally