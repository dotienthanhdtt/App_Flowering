# Phase 02 — Rebuild Optimizations: Obx Scope, Const, ListView

## Context Links
- `research/researcher-01-performance.md` H2, H4, H6, H7

## Overview
- **Priority:** P1 (directly improves perceived smoothness)
- **Status:** pending
- **Effort:** ~3h

Tighten Obx scopes so single-value changes don't rebuild large subtrees; fix chat list rebuilding on every typing-indicator flip.

## Key Insights
- An Obx rebuilds its builder on ANY observable it reads during the last build. Wrapping a `ListView.builder` in an Obx that reads both `messages` and `isTyping` means `isTyping=true` rebuilds the entire list delegate (not the items, but delegate construction + tree diffing).
- Scenarios tabs wrap `RefreshIndicator` inside `Obx` — `isLoading` flip rebuilds `NotificationListener` and the list.
- `messages.refresh()` in `ai_chat_controller` triggers listeners on every mutation of a single message — fine while transcript is short, but grows linearly.

## Requirements

**Functional**
- Behavior identical: all reactive updates still propagate.
- No visible regression in chat streaming, typing indicator, feed refresh.

**Non-functional**
- Reduce chat list rebuild frequency from per-typing-tick to per-message-change.
- Reduce scenarios tab rebuilds from per-state-change to per-relevant-change.

## Architecture

```
Current (bad):
  Obx {
    RefreshIndicator {
      NotificationListener {
        ListView.builder {...}
      }
    }
  }
  // Any observable touched inside rebuilds everything

Target:
  RefreshIndicator {
    NotificationListener {
      ListView.builder {
        itemBuilder: Obx {...}       // per-item reactivity
      }
    }
  }
  // loading overlay handled separately with its own Obx sibling
```

## Related Code Files

**Modify**
- `lib/features/chat/views/ai_chat_screen.dart` — split list Obx from typing-indicator Obx
- `lib/features/scenarios/views/flowering_tab.dart` — move Obx into builder/sibling
- `lib/features/scenarios/views/for_you_tab.dart` — same pattern
- `lib/features/chat/controllers/ai_chat_controller.dart` — replace `messages.refresh()` with targeted updates where feasible
- `lib/features/auth/views/login_email_screen.dart` — confirm Obx scopes (already narrow; minor cleanup)
- `lib/features/vocabulary/views/vocabulary-screen.dart` — confirm Obx scope

## Implementation Steps

### A. Chat list decomposition
1. In `ai_chat_screen.dart`, replace the single `Obx` wrapping `_ChatList` with:
   - An inner Obx that reads only `controller.messages` for the list itemCount/items.
   - A separate footer widget built off `controller.isTyping` (e.g., a `_TypingFooter` widget that is `Obx(() => controller.isTyping.value ? AiTypingBubble() : SizedBox.shrink())`).
2. The list itemCount becomes `controller.messages.length` + fixed 1 for footer cell.
3. Alternatively: keep current layout but split the two observables into two Obx widgets with clear scopes.
4. Verify typing bubble appears/disappears smoothly; scroll animation still fires.

### B. Scenarios tabs — move Obx
1. In `flowering_tab.dart` and `for_you_tab.dart`, restructure:
   - Outer widget: `RefreshIndicator` + `NotificationListener` + `GridView.builder`/`ListView.builder`.
   - `Obx` moves INSIDE `itemBuilder` (item-level reactivity) OR wrap only `itemCount` selector via `GetBuilder`.
   - Loading spinner becomes a sibling: `Obx(() => loading && items.empty ? LoadingWidget : SizedBox.shrink())` sitting above the list in a Stack.
   - Empty/error state wrapped in its own Obx.
2. Ensure `_onScroll` still fires loadMore.

### C. Fine-grained message updates
1. Identify all `messages.refresh()` call sites in `ai_chat_controller.dart` (lines 283, 304, 398, 414, 453).
2. For each, verify whether a full list rebuild is necessary or whether the change is localized to one message.
3. Option A (simple, minor win): keep `refresh()` for now but track improvement with a follow-up.
4. Option B (larger change, more benefit): convert `ChatMessage` to have `.obs` fields for `showTranslation`, `showCorrection`, `correctedText`, `translatedText`. Each bubble's Obx reads only its message's observables.
5. **Choose A for this phase** (KISS/YAGNI — B gets its own phase if measurements justify it).

### D. Const constructor sweep
1. Run `flutter analyze --fatal-infos` with `prefer_const_constructors` lint on.
2. Add `const` where missing (mostly SizedBox spacers that are already const). Low yield but easy.

### E. Verify `ListView.builder` usage everywhere
1. Grep existing `ListView.separated`/`ListView.builder` — all 16 usages already use builder pattern (confirmed by researcher).
2. No action except document it.

## Todo List
- [ ] Split chat list Obx: messages-only list + separate typing-footer Obx
- [ ] Refactor `flowering_tab.dart` to move Obx inside builder
- [ ] Refactor `for_you_tab.dart` to move Obx inside builder
- [ ] Extract shared empty/error state widget (feeds into Phase 07)
- [ ] `flutter analyze --fatal-infos` — resolve new const suggestions
- [ ] Manual smoke: typing indicator toggles without list flicker
- [ ] Manual smoke: feed refresh doesn't jank

## Success Criteria
- `flutter analyze` clean.
- Perceptual check: AiTypingBubble appearing does not cause any visible flicker in chat transcript.
- Feed scroll stays at 60fps during refresh indicator animation.

## Risk Assessment
- **Risk**: new Obx boundaries can miss an observable read, causing stale UI. Mitigation: manual smoke + keep Obx outer fallback during review.
- **Risk**: typing indicator flicker on fast consecutive AI responses. Mitigation: add 100ms minimum display via animation if observed.

## Security Considerations
- None — pure UI refactor.

## Next Steps
- Phase 03 splits oversize files which benefits from the Obx refactor already being in place.
