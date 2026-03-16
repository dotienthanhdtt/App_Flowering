# Phase 3: Add CLAUDE.md Base Widget Rule

## Context Links
- CLAUDE.md: `./CLAUDE.md` (project root)

## Overview
- **Priority:** Low
- **Status:** completed
- **Description:** Add rule to CLAUDE.md so future code always uses `AppText` instead of raw `Text`.

## Related Code Files

### Files to modify
- `/Users/tienthanh/Documents/new_flowering/app_flowering/flowering/CLAUDE.md`

## Implementation Steps

1. Open `CLAUDE.md`
2. Find the `**Key Rules:**` section (line ~91)
3. Add a new bullet after existing rules:

```markdown
- Always use base widgets from `lib/shared/widgets/` instead of raw Flutter widgets:
  - `AppText` instead of `Text` (ensures consistent Outfit font typography)
  - `AppButton` instead of `ElevatedButton`/`TextButton`
  - `AppTextField` instead of `TextField`
```

## Todo List

- [x] Add base widget rule to CLAUDE.md

## Success Criteria

- [x] Rule appears in CLAUDE.md under Key Rules
- [x] Rule is clear and actionable for AI agents and developers

## Completion Notes

Phase 3 successfully completed. Rule added to CLAUDE.md:
- Base widget rule added to Key Rules section
- Covers `AppText` instead of `Text` (primary focus)
- Also includes `AppButton` instead of `ElevatedButton`/`TextButton`
- Also includes `AppTextField` instead of `TextField`
- Rule is clear and actionable for future development
- All references to base widgets documented for consistency
