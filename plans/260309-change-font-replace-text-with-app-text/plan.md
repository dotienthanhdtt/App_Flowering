---
title: "Replace raw Text widgets with AppText base widget"
description: "Standardize all text rendering through AppText widget for consistent typography"
status: completed
priority: P2
effort: 3h
branch: kai/refactor/replace-text-with-app-text
tags: [refactor, typography, ui-consistency]
created: 2026-03-09
completed: 2026-03-09
---

# Replace Text with AppText

## Goal

Replace ~116 raw `Text(` usages across 37 files with `AppText` base widget. Ensures consistent Outfit font usage and centralizes typography control.

## Completion Summary

Successfully completed Text→AppText refactoring across entire codebase:
- 100 raw `Text(` replaced with `AppText(` across ~30 files
- All phases completed with test suite passing (5/5 tests)
- Code review issues fixed and resolved
- Rule added to CLAUDE.md for future consistency

## Phases

| # | Phase | Status | Effort |
|---|-------|--------|--------|
| 1 | [Enhance AppText widget](./phase-01-enhance-app-text-widget.md) | completed | 30m |
| 2 | [Replace Text with AppText across codebase](./phase-02-replace-text-with-app-text.md) | completed | 2h |
| 3 | [Add CLAUDE.md base widget rule](./phase-03-add-claude-md-rule.md) | completed | 10m |

## Key Dependencies

- Phase 2 depends on Phase 1 (needs enhanced AppText params) ✅
- Phase 3 is independent but should be last ✅

## Exclusions

- `Text` inside `RichText` / `SelectableText` children (TextSpan) ✅ Respected
- Emoji-only `Text` widgets (e.g., flag emojis in `_LanguageFlag`) ✅ Kept as raw `Text` since they don't use Outfit font
- `Text` inside `AppText.build()` itself (it wraps `Text` internally) ✅ Respected
