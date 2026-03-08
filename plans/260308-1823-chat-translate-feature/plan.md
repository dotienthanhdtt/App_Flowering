---
title: "Chat Translate Feature"
description: "Add word-level and sentence-level translation to AI chat bubbles with bottom sheet UI"
status: complete
priority: P1
effort: 4h
branch: feat/chat-translate
tags: [chat, translation, vocabulary, ui]
created: 2026-03-08
completed: 2026-03-08
---

# Chat Translate Feature

## Summary

Add word-level tap-to-translate and sentence-level translate to AI chat bubbles.
Word taps open a bottom sheet (design 08a) showing translation, pronunciation, definition, examples.
Sentence translate calls API on first tap, caches result, toggles on subsequent taps.

## Phases

| # | Phase | Status | Effort | File |
|---|-------|--------|--------|------|
| 1 | Model + Service + Endpoint | Complete | 1.5h | [phase-01](phase-01-model-service-endpoint.md) |
| 2 | Word Translation Bottom Sheet UI | Complete | 1.5h | [phase-02](phase-02-word-translation-sheet.md) |
| 3 | Bubble Integration + Controller Wiring | Complete | 1h | [phase-03](phase-03-bubble-integration.md) |

## Dependencies

- Backend `POST /ai/translate` endpoint must be deployed
- `AppTappablePhrase` widget exists and is ready to use
- `AiMessageBubble`, `AiChatController`, `ChatMessage` model exist

## Key Decisions

1. `TranslationService` as global GetX singleton — reusable across chat contexts
2. In-memory caching per session (word cache by word string, sentence cache by messageId)
3. Onboarding chat uses client-generated IDs (`ai_xxx`) — sentence translate disabled for those
4. Word splitting by space is acceptable (target language is English)

## Out of Scope

- TTS/audio playback for word pronunciation (separate feature)
- CJK word boundary handling
- Vocabulary list/review screen
- Offline translation caching (Hive persistence)
