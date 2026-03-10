---
title: "Enforce BaseController/BaseScreen inheritance across all features"
description: "Add CLAUDE.md rules and migrate all controllers/screens to use base classes"
status: completed
priority: P1
effort: 3h
branch: current
tags: [refactoring, architecture, base-classes]
created: 2026-03-10
---

# Base Class Inheritance Enforcement

## Objective

Standardize all feature controllers and screens to inherit from `BaseController` and `BaseScreen`/`BaseStatelessScreen`, then codify this as a mandatory rule.

## Phases

| # | Phase | Status | Effort |
|---|-------|--------|--------|
| 1 | [Update CLAUDE.md rules](./phase-01-update-rules.md) | ✅ completed | 15m |
| 2 | [Migrate existing code](./phase-02-migrate-existing-code.md) | ✅ completed | 2h45m |

## Key Dependencies

- `lib/core/base/base_controller.dart` -- provides `isLoading`, `errorMessage`, `apiCall()`, `showSuccess()`
- `lib/core/base/base_screen.dart` -- provides `BaseScreen<T>` (with loading overlay) and `BaseStatelessScreen`

## Risk

- Controllers that define their own `isLoading`/`errorMessage` fields will shadow BaseController's -- must remove duplicates
- Screens embedded inside other screens (tab children) should NOT use Scaffold -- must use content-only pattern
- `WelcomeProblemScreen` is a `StatefulWidget` -- no base class for that; exempt it
