---
title: "TTS + STT Audio Architecture"
description: "Abstract audio services with flutter_tts, speech_to_text, and backend transcription"
status: complete
priority: P1
effort: 12h
tags: [feature, audio, tts, stt, backend, frontend]
created: 2026-04-06
completed: 2026-04-06
---

# TTS + STT Audio Architecture

## Overview

Replace monolithic `AudioService` with abstract provider pattern: `TtsService` (text-to-speech for AI messages) + `VoiceInputService` (hybrid STT + recording). Auto-play AI messages, hold-to-record with live transcription, backend fallback for accuracy.

## Context

- [Brainstorm Report](../reports/brainstorm-260406-tts-stt-audio-architecture.md)
- [Researcher Report](../reports/researcher-flutter-audio-packages-api-surface.md)
- [Completion Report](../reports/completion-report.md)

## Phases

| # | Phase | Status | Effort | Link |
|---|-------|--------|--------|------|
| 1 | Dependencies + permissions + models | Complete | 1h | [phase-01](./phase-01-dependencies-permissions-models.md) |
| 2 | Abstract contracts | Complete | 1.5h | [phase-02](./phase-02-abstract-contracts.md) |
| 3 | Concrete providers | Complete | 3h | [phase-03](./phase-03-concrete-providers.md) |
| 4 | Services (TtsService + VoiceInputService) | Complete | 3h | [phase-04](./phase-04-services.md) |
| 5 | DI + migration (remove old AudioService) | Complete | 1.5h | [phase-05](./phase-05-di-migration.md) |
| 6 | Chat UI integration | Complete | 2h | [phase-06](./phase-06-chat-ui-integration.md) |

## Dependencies

- `flutter_tts: ^4.2.5` — on-device TTS
- `speech_to_text: ^7.3.0` — on-device STT
- `record: ^6.2.0` (existing) — audio recording
- `audioplayers: ^5.2.1` (existing) — audio playback
- Backend `POST /ai/transcribe` endpoint (optional, enhances accuracy on iOS)

## Key Constraints

- Android: `speech_to_text` + `record` can't share mic simultaneously
- iOS: 60s hard limit on speech recognition (use 55s safety timeout)
- TTS must stop before STT starts (audio session conflict)
