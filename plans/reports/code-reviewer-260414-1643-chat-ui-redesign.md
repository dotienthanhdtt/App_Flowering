# Code Review — Chat UI Redesign (08A–08E)

Scope: 10 files under `lib/features/chat/widgets/`, `lib/shared/widgets/app_tappable_phrase.dart`, `lib/core/constants/{app_colors,app_sizes}.dart`. Visual/token-level refactor, no behavior changes.

`flutter analyze` on changed surface: **0 new issues**. Only pre-existing kebab-case `file_names` infos (project-approved).

---

## Critical
None.

## High
None.

## Medium

### M1. `flutter_widget_from_html_core` dependency is now orphaned
- `lib/features/chat/widgets/grammar_correction_section.dart` was the sole consumer (confirmed via grep: no remaining `HtmlWidget` / `flutter_widget_from_html_core` imports in `lib/`).
- `pubspec.yaml:60` still declares `flutter_widget_from_html_core: ^0.17.0`.
- Impact: app size bloat + transitive deps (`csslib`, `html`) that no longer serve a purpose. Violates YAGNI from `development-rules.md`.
- Fix: remove the line from `pubspec.yaml`, run `flutter pub get`. If kept intentionally for a planned feature, add a `# pending: <reason>` comment.

### M2. `_stripHtml` does not decode HTML entities
- Regex `<[^>]*>` strips tags only. If backend returns `&amp;`, `&#39;`, `&quot;`, they render literally (e.g. "it&#39;s" instead of "it's") — this is user-visible bad UX on an already-red error card.
- The old `HtmlWidget` decoded entities automatically, so this is a **regression** compared to prior behavior for any response that contained entity-encoded punctuation.
- Fix (minimal, no new dep): extend `_stripHtml` with the common set:
  ```dart
  String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
  ```
  (Order matters — `&amp;` last-or-first? First is fine since `&amp;amp;` would be a pathological case from the API.) Actually `&amp;` should be **last** to avoid double-decoding; swap as needed.
- If backend guarantees no entity encoding, add a `// Backend contract: raw text only` comment and close this out.

## Low

### L1. `infoColor` hex shift (#6B89AD → #9CB0CF) affects 1 off-plan caller
- Non-chat caller: `lib/features/onboarding/widgets/step_dots_indicator.dart:26` — inactive step dot color.
- Side effect: inactive dots become lighter/cooler. Likely still acceptable against the onboarding white background (both are mid-tone blues), but this was **not explicitly reviewed against the onboarding design frames**.
- Recommendation: if the design for step dots hasn't changed, verify contrast on a device. If it's a concern, introduce a dedicated `hairlineColor`/`dividerColor` token and restore `infoColor` to a semantic-only use — but that's a larger refactor, YAGNI says leave it unless a designer flags it.
- Plan noted `step_dots_indicator.dart` as a known caller — so this is acknowledged, just flagging visibility.

### L2. Contrast on amber context card
- Bg `#FFB830` × text `#191919` (textPrimary) → luminance ratio ≈ **10.4:1** (pass WCAG AAA for normal text).
- Bg `#FFB830` × icon `#FF7B47` (primaryColor, chat_bubble_outline) → ratio ≈ **1.6:1**. **Fails WCAG AA (3:1)** for non-text graphics.
- This is a design-spec faithful rendering per researcher report, so it's not a code defect — but if accessibility is a concern, raise with the designer. Mitigation options: darker icon, or add a subtle stroke.
- No action required unless product wants to address.

### L3. `AppText` inside `AiMessageBubble` translation row lost `lineHeight`
- Before: `variant: AppTextVariant.bodyLarge` carried the 1.33 line-height from `AppTextStyles.bodyLarge`.
- After: `fontSize: AppSizes.fontSizeMedium` with no `variant` and no `height:` — falls back to the default TextStyle line-height for Inter (tighter).
- Impact: translation text inside AI bubble may sit tighter than the rest of the bubble. Minor visual polish.
- Fix: add `height: AppSizes.lineHeightMedium` (constant already exists and is used elsewhere).

### L4. Redundant `AppSizes.space1 / 2` (evaluates to 2)
- `grammar_correction_section.dart:54` uses `const SizedBox(height: AppSizes.space1 / 2)`. Works (compile-time `const`), but would be clearer as a direct `AppSizes.space05` or literal `2`. Token `space05` doesn't exist. Not worth adding a token for one use site.
- Nit. Leave as-is.

## Nits

### N1. `AppTappablePhrase` — `fontSize`/`fontWeight` API change is backward-compatible
- Both are optional, defaulted to `null`. All existing callers (grep confirms only `ai_message_bubble.dart` and internal use) unaffected.
- Behavior change worth noting: previously, when `color == null`, the base variant style returned unmodified. Now `style.copyWith(color: null, ...)` is called unconditionally. `copyWith(color: null)` is a no-op in Flutter's `TextStyle` (null means "leave existing"), so behavior is preserved. ✓

### N2. `chat_input_bar.dart` top border color `infoColor` doubled elsewhere
- Divider in `chat_top_bar.dart:66`, AI bubble translation separator, text input border, input bar top border all use `infoColor` now. Consistent with design "hairline" token — good. If more callers added in future, consider renaming to `hairlineColor` for intent clarity. Not required now.

### N3. Unused tokens removed cleanly
- `navBarHeight` + `navItemWidth` were removed from `app_sizes.dart`. Grep confirms zero remaining references in `lib/`. Clean.

---

## Focus Questions Answered

| Question | Answer |
|---|---|
| `infoColor` shift breaks non-chat? | **L1** — step dots only; likely fine, flagged for designer check. |
| `_stripHtml` safe for entities? | **M2** — no, regression vs HtmlWidget. Add entity-decode pass OR confirm backend contract. |
| `AppTappablePhrase` API broke callers? | **N1** — no, backward-compatible. Only 1 caller in codebase. |
| Contrast on amber card? | **L2** — text passes AAA; icon fails AA (1.6:1). Design-faithful, raise with designer if needed. |
| Base-widget convention violations / dead imports? | **M1** — orphaned `flutter_widget_from_html_core` in pubspec. No import violations; `AppText` used consistently. |

---

## Recommended Actions (prioritized)

1. **M1** — Remove `flutter_widget_from_html_core: ^0.17.0` from `pubspec.yaml`.
2. **M2** — Extend `_stripHtml` to decode common entities OR confirm backend returns raw text and document with a comment.
3. **L3** — Add `height: AppSizes.lineHeightMedium` to translation `AppText` in `ai_message_bubble.dart:82`.
4. **L1/L2** — Verify with designer (no code change required).

---

## Unresolved Questions

- Does the grammar correction API guarantee raw text (no `&amp;`, `&#39;` entity encoding)? If yes, M2 downgrades to nit + comment.
- Was the inactive step-dot color intentionally changed by the design team, or is `infoColor` being overloaded? If the latter, consider splitting into `hairlineColor` vs `dividerColor` vs `inactiveIndicatorColor` — but defer until a second semantic-divergence case appears (YAGNI).

**Status:** DONE_WITH_CONCERNS
