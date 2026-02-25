---
title: "Pencil Design System Sync"
description: "Sync Flutter codebase colors, typography, buttons, and text inputs to match Pencil MCP design source of truth"
status: complete
priority: P2
effort: 3h
branch: main
tags: [design-system, ui, refactor, pencil-sync]
created: 2026-02-26
completed: 2026-02-26
---

# Pencil Design System Sync

## Objective

Align Flutter codebase with Pencil MCP design variables. Design-only update -- no new features.

## Scope

- Full color palette replacement (old Gen Z aesthetic -> Pencil warm neutral palette)
- Font family change: Inter -> Outfit
- Button component restyle (height, radius, shadows, variants)
- Text input component restyle (radius, borders, padding, label sizing)
- Fix all broken references from removed/renamed colors

## Phases

| # | Phase | File(s) | Status |
|---|-------|---------|--------|
| 1 | [Color Palette](phase-01-color-palette.md) | `app_colors.dart` | Complete |
| 2 | [Typography](phase-02-typography.md) | `app_text_styles.dart` | Complete |
| 3 | [Buttons](phase-03-buttons.md) | `app_button.dart` | Complete |
| 4 | [Text Input](phase-04-text-input.md) | `app_text_field.dart` | Complete |
| 5 | [Fix References](phase-05-fix-references.md) | 3 files with broken refs | Complete |

## Execution Order

Phase 1 first (all other phases depend on new color names). Phases 2-4 parallel. Phase 5 last.

## Breakage Points (from scan)

- `flowering-app-widget-with-getx.dart` -- `AppColors.secondary`, `AppColors.divider`
- `app_button.dart` -- `AppColors.secondary`
- `app_text_field.dart` -- `AppColors.textHint`, `AppColors.divider`
- `app_text_styles.dart` -- `AppColors.textHint`
- `error_widget.dart` -- `AppColors.textSecondary` (color value changes)

## Risk

Low risk. No feature logic changes. All modifications are to static constants and widget styling.

## Success Criteria

- `flutter analyze` passes with 0 errors
- All old color names removed (secondary, peach, mint, skyBlue, softPink)
- All renamed colors updated (textHint->textTertiary, divider->border)
- Font family is Outfit everywhere
- Button/input specs match Pencil design variables
