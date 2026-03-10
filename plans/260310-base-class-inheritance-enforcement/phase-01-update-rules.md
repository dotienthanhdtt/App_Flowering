---
phase: 1
title: "Update CLAUDE.md rules for base class inheritance"
status: pending
priority: P1
effort: 15m
---

## Context Links

- Base classes: `lib/core/base/base_controller.dart`, `lib/core/base/base_screen.dart`
- Rules file: `CLAUDE.md` (root of flowering/)

## Overview

Add mandatory rules to CLAUDE.md requiring all feature controllers and screens to inherit from base classes.

## Related Code Files

### Files to Modify
- `CLAUDE.md`

## Implementation Steps

### 1. Add Base Class Inheritance Rules to CLAUDE.md

Insert a new section **"### Base Class Inheritance (Mandatory)"** after the existing "Key Rules" bullet list (after line 103, before "### State Management Pattern").

Add this content:

```markdown
### Base Class Inheritance (Mandatory)

All feature controllers and screens MUST inherit from the base classes in `lib/core/base/`:

**Controllers:**
- All controllers in `features/*/controllers/` MUST extend `BaseController` (not `GetxController` directly)
- `BaseController` provides: `isLoading`, `errorMessage`, `apiCall()`, `showSuccess()`, `clearError()`
- Do NOT redeclare `isLoading` or `errorMessage` -- use inherited ones from `BaseController`
- Always call `super.onInit()` / `super.onClose()` when overriding lifecycle

**Screens (views):**
- Screens with a controller: extend `BaseScreen<ControllerType>` -- gets automatic loading overlay, SafeArea, Scaffold
  - Override `buildContent()` instead of `build()` for screen body
  - Override `buildAppBar()`, `buildFab()`, `buildBottomNav()` as needed
  - Override `backgroundColor`, `useSafeArea`, `showLoadingOverlay` getters to customize
- Screens without a controller: extend `BaseStatelessScreen` -- same pattern minus loading overlay
- StatefulWidget screens (rare): exempt from base class, document why in a comment

**Exemptions:**
- Shared widgets (`shared/widgets/`, `features/*/widgets/`) -- these are composable components, NOT screens
- Tab child screens embedded in IndexedStack -- these should NOT use BaseScreen (would create nested Scaffolds); use plain StatelessWidget with just content, no Scaffold
- StatefulWidget screens that need `State` lifecycle (e.g., animation controllers, PageController) -- exempt but add comment explaining why
```

### 2. Update the existing BaseController example

In the existing "### BaseController Pattern" section (line 210-228), update the example comment from:

```dart
class AuthController extends BaseController {
```

to also add a note:

```markdown
> **Rule:** Never extend `GetxController` directly in feature controllers. Always use `BaseController`.
```

## Todo List

- [ ] Add "Base Class Inheritance (Mandatory)" section to CLAUDE.md after line 103
- [ ] Add note to existing BaseController Pattern section
- [ ] Verify no contradictions with existing rules

## Success Criteria

- CLAUDE.md contains clear, enforceable rules for base class inheritance
- Rules distinguish screens vs widgets vs tab children
- Rules list exemptions explicitly
