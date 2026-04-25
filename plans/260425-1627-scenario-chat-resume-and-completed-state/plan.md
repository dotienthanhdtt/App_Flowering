---
title: "Scenario Chat: Resume + Completed State"
description: "Adapt POST /scenario/chat client to new {scenario, messages[]} response shape. Handle 3 entry states: new user, resume mid-conv (CHATTING), completed (DONE → hide input, show View Result button)."
status: done
priority: P1
effort: 4h
branch: feat/update-onboarding
tags: [mobile, scenario-chat, getx, flutter, api-migration]
created: 2026-04-25
completed: 2026-04-25
brainstorm: ../reports/brainstorm-260425-1627-scenario-chat-resume-and-completed-state.md
blockedBy: []
blocks: []
supersedes: []
---

# Scenario Chat: Resume + Completed State

## Summary

Backend changed `POST /scenario/chat` from per-turn `{reply, ...}` to full state `{scenario:{conversation_id, max_turns, turn, status}, messages:[{id, role, content, created_at}]}`. Status string: `CHATTING` | `DONE`. Same endpoint serves kickoff, send, AND resume.

Client must:
1. Render full message history on every response (no longer single-message append).
2. Preserve client-side per-message UI state (translation cache, grammar correction) across server-replaces.
3. On `status=DONE`: hide input bar, show "View Result" button (no-op stub).
4. Skip rendering empty-content messages.
5. Suppress TTS auto-play on initial load (resume case) — only fire on send-completion.

8 files touched. No new files. No backend changes scope.

## Phases

| # | Phase                                          | Status | Effort | File                                          |
|---|------------------------------------------------|--------|--------|-----------------------------------------------|
| 1 | Models + service: new response shape           | done   | 1h     | [phase-01](phase-01-models-and-service.md)    |
| 2 | Controller refactor: merge + grammar fallback  | done   | 2h     | [phase-02](phase-02-controller-and-merge.md)  |
| 3 | View + l10n: View Result button, delete banner | done   | 1h     | [phase-03](phase-03-view-and-l10n.md)         |

## Key Dependencies

- Backend ships new `/scenario/chat` response shape on the same endpoint (assumed coordinated).
- Existing widgets reused: `AppButton`, `ChatTopBar`, `ScenarioChatInputBar`, message bubbles.

## Open Questions (carried from brainstorm)

1. Backend behavior for `message: ''` + existing `conversationId` — confirmed as "load state"?
2. Retry semantics on resume failure — same inline retry or navigate back?

## Success Criteria

- Cases 1/2/3 render correctly; `flutter analyze` clean; existing first-time UX unchanged.
- Translation toggle + grammar correction survive server replaces.
- No TTS audio bursts on resume.
