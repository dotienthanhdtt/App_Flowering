---
title: "AI Chat Screen UI Update (08A-08E)"
description: "Update AI chat screen widgets to match Pencil design screens 08A through 08E"
status: completed
priority: P1
effort: 6h
branch: feat/chat-ui-update-08a-08e
tags: [ui, chat, design-sync, flutter]
created: 2026-03-23
completed: 2026-03-23
---

# AI Chat Screen UI Update (08A-08E)

## Summary

Update the AI chat screen and all child widgets to match Pencil design screens 08A (default), 08B (text input), 08C (recording), 08D (translated), 08E (word tap bottom sheet). This is a UI-only update — no new backend APIs or architectural changes.

## Phases

| # | Phase | Status | File |
|---|-------|--------|------|
| 1 | Top bar + Correction + Input widgets | Complete | [phase-01](phase-01-topbar-correction-input.md) |
| 2 | Message bubbles + Recording bar | Complete | [phase-02](phase-02-bubbles-recording.md) |
| 3 | Bottom sheet + Context card + Screen integration | Complete | [phase-03](phase-03-sheet-context-screen.md) |

## Key Dependencies

- AppColors and AppSizes constants already cover most design tokens
- Missing color: `#545F71` used for icons/text in design maps to `AppColors.neutralColor` (already exists)
- Missing color: `#9CB0CF` for divider/handle maps to `AppColors.infoColor` (already exists)
- `word-translation-sheet.dart` (shared widget) needs updates — coordinate with any other screens using it

## Design Token Mapping

| Design Value | AppColors/AppSizes Constant |
|---|---|
| #FD9029 | `primaryColor` |
| #0077BA | `secondaryColor` |
| #F9F7F2 | `backgroundColor` |
| #FFFFFF | `surfaceColor` |
| #1C1C1E | `textPrimaryColor` (close to #191919) |
| #545F71 | `neutralColor` |
| #9CB0CF | `infoColor` |
| #E63950 | `errorColor` |
| #E5DFC9 | `borderColor` |
| 12px radius | `radiusM` |
| 999px radius | `radiusPill` |

## Notes

- Design uses `#1C1C1E` for text but codebase has `#191919` — difference is negligible, keep existing
- User bubble color changes from orange (`primaryColor`) to blue (`secondaryColor`) per design
- Grammar correction moves from inside user bubble to standalone card below user bubble
- "Flora" label removed from AI bubbles; AI avatar removed
- Action buttons move from inside bubble to below bubble with pill-shaped backgrounds
