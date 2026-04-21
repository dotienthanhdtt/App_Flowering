# Phase 01 — Header Widgets

## Context Links

- Design frame: `4xVNl` (09_chat_screen) in `flowering_design.pen`; relevant sub-frame `mRMes` (Flag & Dropdown) inside `TJOsb` (Top Bar).
- Reuse: `lib/features/onboarding/widgets/language_card.dart` — `LanguageListCard`, `LanguageFlag`.
- Reuse: `lib/features/onboarding/models/onboarding_language_model.dart` — `OnboardingLanguage`.
- Service: `lib/core/services/language-context-service.dart`.

## Overview

- **Priority:** High (blocks phase-02).
- **Status:** Pending.
- **Brief:** Build the two new widgets used by the home header: the flag button in the app bar, and the bottom-sheet picker that opens from it.

## Key Insights

- The existing `LanguageListCard` already matches the look-and-feel of the design's `tLfyG` (Language Card). Use it inside the picker to avoid duplication.
- `LanguageFlag` already handles network URL + emoji fallback — reuse it inside the header button at a smaller size (32px).
- Header button should be purely presentational; all state & IO stays in `ChatHomeController` (phase-02).

## Requirements

### Functional

- `HomeLanguageButton`:
  - Inputs: `OnboardingLanguage? active`, `VoidCallback onTap`.
  - If `active` is null, render a subtle placeholder (globe icon) instead of an empty flag.
  - Emits `onTap` when pressed.
- `LanguagePickerSheet`:
  - Inputs: `List<OnboardingLanguage> languages`, `String? activeCode`, `ValueChanged<OnboardingLanguage> onSelect`.
  - Renders a title (`language_picker_title`.tr) + list of `LanguageListCard`s.
  - Active entry shows a subtle "selected" indicator (check icon on the right instead of chevron).
  - Dismiss on select; caller is responsible for the switch + refetch.

### Non-Functional

- Both widgets stateless; <100 lines each.
- Follow `CLAUDE.md` base-widget rules: `AppText` for all text, no raw `Text` except where already allowed (e.g. emoji fallback inside `LanguageFlag`).
- File names kebab-case per `development-rules.md`.

## Architecture

```
ChatHomeScreen header
└── HomeLanguageButton (lib/features/chat/widgets/home-language-button.dart)
      tap → showModalBottomSheet → LanguagePickerSheet
                                    (lib/features/chat/widgets/language-picker-sheet.dart)
                                    └── ListView → LanguageListCard (reused)
```

## Related Code Files

**Create:**
- `lib/features/chat/widgets/home-language-button.dart`
- `lib/features/chat/widgets/language-picker-sheet.dart`

**Read (no edits):**
- `lib/features/onboarding/widgets/language_card.dart`
- `lib/features/onboarding/models/onboarding_language_model.dart`
- `lib/core/constants/app_colors.dart`, `app_sizes.dart`

## Implementation Steps

1. `home-language-button.dart`:
   - Stateless widget. Row layout with 10px gap.
   - Flag: 32×32 `LanguageFlag` clipped to `cornerRadius: 20` (matches design `F1Hki`).
   - Chevron: `Icons.expand_more` (or `LucideIcons.chevronDown`) size 20.
   - Tappable via `GestureDetector` with 8px hit padding.
   - Placeholder when `active == null`: `Icons.language` in a 32px circle with `surfaceMutedColor` bg.
2. `language-picker-sheet.dart`:
   - Show via `showModalBottomSheet(context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => LanguagePickerSheet(...))`.
   - Root = rounded-top (radiusL) `Container` with `surfaceColor` bg + drag handle.
   - Header row: title `AppText('language_picker_title'.tr, variant: h2)`; trailing close icon.
   - Body: `ListView.separated` of `LanguageListCard` (use `flagSize: 48`, `cardPadding: 16` to match design `tLfyG`).
   - Active row: override trailing icon with `LucideIcons.check` in `AppColors.primaryColor` (wrap `LanguageListCard` via a thin adapter if needed, or pass a `trailing` param if we add one).
   - On tap: `onSelect(language)` then `Navigator.pop(context)`.

## Todo List

- [ ] Create `home-language-button.dart` (<80 lines).
- [ ] Create `language-picker-sheet.dart` (<150 lines).
- [ ] Add helper `showLanguagePickerSheet(context, ...)` static method on picker.
- [ ] Run `flutter analyze` on the two new files.

## Success Criteria

- Both files compile, no analyzer warnings.
- Visual sanity check against `get_screenshot('4xVNl')`.
- Button swaps between flag and placeholder cleanly.

## Risk Assessment

- **LanguageListCard has no `trailing` override** — if adding a param is ugly, wrap in a custom `_PickerRow` in the sheet file to avoid polluting the onboarding widget. Prefer wrap.

## Security Considerations

- None — widgets are purely presentational; no network or persistence in phase-01.

## Next Steps

- Phase-02 consumes these widgets in `ChatHomeScreen` + `ChatHomeController`.
