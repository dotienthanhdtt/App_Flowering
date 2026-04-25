# Phase 03 — View + l10n: View Result Button, Delete Banner

## Context Links
- Brainstorm: [`../reports/brainstorm-260425-1627-scenario-chat-resume-and-completed-state.md`](../reports/brainstorm-260425-1627-scenario-chat-resume-and-completed-state.md)
- Plan overview: [`plan.md`](plan.md)
- Depends on: [phase-02](phase-02-controller-and-merge.md) (controller emits `completed.value` from server status)

## Overview
- **Priority:** P1
- **Status:** done
- **Effort:** 1h
- Replace `_CompletedBanner` with `_ViewResultBar` (no-op button). Add l10n key. Delete orphaned key + widget.

## Key Insights
- `_CompletedBanner` is local to `scenario_chat_screen.dart` — single delete + replace.
- `AppButton` is the standard CTA per CLAUDE.md base widgets contract.
- `'scenario_chat_view_result'` key naming follows existing pattern `scenario_chat_*`.

## Requirements

### Functional
- When `controller.completed.value == true` → bottom area shows a single "View Result" button.
- Button tap = no-op (stub for follow-up).
- Input bar hidden in completed state (already wired via existing `Obx` branching).
- New key `scenario_chat_view_result` in both en + vi files.
- Delete key `scenario_chat_complete_banner` from both files.

### Non-functional
- No new shared widgets — reuse `AppButton`.
- Match horizontal padding of input bar for visual continuity.

## Architecture

```
buildContent()
  └── Obx (bottom area)
       ├── if completed → _ViewResultBar          (NEW)
       ├── if kickoffFailed → _KickoffErrorBanner (unchanged)
       └── else → ScenarioChatInputBar             (unchanged)
```

## Related Code Files

### Modified
- `lib/features/scenario-chat/views/scenario_chat_screen.dart` — replace `_CompletedBanner` with `_ViewResultBar`
- `lib/l10n/english-translations-en-us.dart` — add `scenario_chat_view_result`, remove `scenario_chat_complete_banner`
- `lib/l10n/vietnamese-translations-vi-vn.dart` — same

### Created
- (none)

### Deleted
- `_CompletedBanner` widget (private class inside `scenario_chat_screen.dart`)
- l10n key `scenario_chat_complete_banner` (both files)

## Implementation Steps

### Step 1 — view swap

In `lib/features/scenario-chat/views/scenario_chat_screen.dart`:

1. Replace the `Obx` bottom-area block (around line 40-46) — change `_CompletedBanner()` call to `const _ViewResultBar()`:

```dart
Obx(() {
  if (controller.completed.value) return const _ViewResultBar();
  if (controller.kickoffFailed.value) {
    return _KickoffErrorBanner(onRetry: controller.retryKickoff);
  }
  return const ScenarioChatInputBar();
}),
```

2. Delete the `_CompletedBanner` class (lines ~140-169).

3. Add `_ViewResultBar` at the same location:

```dart
class _ViewResultBar extends StatelessWidget {
  const _ViewResultBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space4,
        vertical: AppSizes.space3,
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          text: 'scenario_chat_view_result'.tr,
          onPressed: () {},
        ),
      ),
    );
  }
}
```

> NOTE: `AppButton` defaults are full-width per shared widget. Confirm by opening `lib/shared/widgets/app_button.dart` if this assumption is wrong, set `isFullWidth: true`. Keep `SafeArea(top:false)` so the button doesn't sit under the home indicator on iOS.

### Step 2 — l10n keys

In `lib/l10n/english-translations-en-us.dart`:
- Find line containing `'scenario_chat_complete_banner': 'Conversation complete. Tap Practice Again to replay.',`
- Delete that line.
- Add `'scenario_chat_view_result': 'View Result',` adjacent to other `scenario_chat_*` keys.

In `lib/l10n/vietnamese-translations-vi-vn.dart`:
- Mirror the deletion of the corresponding `scenario_chat_complete_banner` entry.
- Add `'scenario_chat_view_result': 'Xem kết quả',` in the same relative position.

### Step 3 — verify

```bash
cd /Users/tienthanh/Dev/new_flowering/app_flowering/flowering
flutter analyze
grep -rn "scenario_chat_complete_banner" lib/    # should return zero hits
grep -rn "_CompletedBanner" lib/                  # should return zero hits
grep -rn "scenario_chat_view_result" lib/         # should appear in 3 files (view + 2 l10n)
```

### Step 4 — manual smoke test

1. `flutter run --dart-define=ENV=dev`.
2. Open a scenario where backend returns `status: CHATTING` + 1 msg → existing UX, input visible.
3. (If backend can be coerced) open a scenario with `status: DONE` → input hidden, "View Result" button visible, tap = no-op.
4. Open scenario mid-conversation (`CHATTING` + N msgs) → all bubbles render, scrolled bottom, can continue typing.

## Todo List

- [x] Replace `_CompletedBanner()` call with `_ViewResultBar()` in screen
- [x] Delete `_CompletedBanner` widget class
- [x] Add `_ViewResultBar` widget class
- [x] Add `scenario_chat_view_result` to en l10n; remove `scenario_chat_complete_banner`
- [x] Add `scenario_chat_view_result` to vi l10n; remove `scenario_chat_complete_banner`
- [x] `flutter analyze` clean across full project
- [x] Manual smoke test for case 1 (existing UX preserved)
- [x] Manual smoke test for case 2 (resume mid-conv) — if backend supports
- [x] Manual smoke test for case 3 (DONE state) — if backend supports

## Success Criteria

- `flutter analyze` clean.
- Bottom area shows `View Result` button when `completed=true`; input otherwise.
- Tap on `View Result` does nothing (no-op stub).
- Empty messages from server produce no bubble.
- Existing scenario chat first-time UX unchanged.

## Risk Assessment

- **Risk:** `AppButton` default colors don't match success/done aesthetic. **Mitigation:** ship default; design polish in a follow-up if needed.
- **Risk:** Removing `scenario_chat_complete_banner` breaks any other reference. **Mitigation:** the grep step in verify catches stragglers.
- **Risk:** Vietnamese translation copy off — confirm `Xem kết quả` reads naturally in context (no notes from product team flagged otherwise).

## Security Considerations
- None.

## Next Steps
- Wire actual "View Result" navigation/screen in a separate plan when product spec lands.
- Consider extracting `_ViewResultBar` to `widgets/` directory if it grows beyond a single button.
