---
title: "Bottom Navigation Bar"
description: "4-tab bottom navigation (Chat, Read, Vocabulary, Profile) with IndexedStack page switching"
status: completed
priority: P1
effort: 4h
tags: [frontend, feature, navigation]
created: 2026-03-04
completed: 2026-03-04
---

# Bottom Navigation Bar

## Overview
Add 4-tab custom bottom navigation bar matching Pencil design. Chat tab default. IndexedStack for state preservation. Full-screen push for sub-pages.

## Status
All 3 phases complete. Feature fully integrated and tested (5/5 tests passing, 0 analysis errors).

## Phases

| # | Phase | Status | Effort |
|---|-------|--------|--------|
| 1 | [Dependencies & Navigation Shell](phase-01-dependencies-and-navigation-shell.md) | completed | 1.5h |
| 2 | [Tab Screen Content](phase-02-tab-screen-content.md) | completed | 2h |
| 3 | [Route Integration & Polish](phase-03-route-integration-and-polish.md) | completed | 30m |

## Key Decisions
- **IndexedStack** for tab switching (preserves state)
- **Custom BottomNavBar** widget (not Flutter built-in) to match Pencil design
- **lucide_icons** package for icon matching
- **Full-screen push** for sub-pages (no nested navigators)
- **Chat tab = index 0** (default)
- Repurpose existing empty feature dirs: `home/`, `lessons/`, `profile/`
- New `vocabulary/` feature dir needed
- Chat home screen lives in `chat/` feature alongside onboarding chat

## Design Tokens (Pencil)
- Active: `#FF7A27` (AppColors.primary), fontWeight 600
- Inactive: `#9C9585` (AppColors.textTertiary), fontWeight 500
- Bar bg: white, height 80, top corners 20px
- Shadow: blur 12, `#19191908`, y:-2
- Border: inside `#F0ECDA` (AppColors.borderLight), 1px
- Font: Outfit 10px, icons 22x22, gap 4, item width 64

## Dependencies
- `lucide_icons` Flutter package (new)
- Existing: `get`, `google_fonts`, design tokens

## Reports
- [Brainstorm Report](reports/brainstorm-report.md)
