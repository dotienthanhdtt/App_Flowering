# Phase 03 — Split Files Over 200 Lines

## Context Links
- `research/researcher-03-code-structure.md` (full file list)

## Overview
- **Priority:** P2 (maintainability, not performance)
- **Status:** pending
- **Effort:** ~5h

Enforce the 200-line rule from `docs/code-standards.md`. 12 files currently violate.

## Key Insights
- Largest offender is `ai_chat_controller.dart` (538 lines). Natural split: session, voice/TTS bridge, grammar, translation, message helpers.
- Most widget files violate because private sub-widgets live in same file. Standard Flutter pattern is to extract those when >200.
- `audio_service.dart` (282 lines) appears unused — verify and delete (reduces scope).
- l10n files are exempt (flat translation maps, splitting adds noise without benefit).

## Requirements

**Functional**
- No behavior change. Pure refactor.
- All existing imports continue to resolve.

**Non-functional**
- Every split file stays under 200 lines.
- Follow `docs/code-standards.md` file naming (kebab-case or snake_case as already used per-file).

## Architecture

Split strategy per file — decomposition-first.

```
ai_chat_controller.dart (538)
  ├─ ai_chat_controller.dart          (main controller, ~150 lines)
  ├─ ai_chat_session_mixin.dart        (bootstrap, rehydrate, create — ~120)
  ├─ ai_chat_voice_mixin.dart          (voice input + transcription — ~80)
  ├─ ai_chat_grammar_translation_mixin.dart (grammar + sentence translate + word tap — ~120)
  └─ ai_chat_message_helpers.dart     (add/remove message helpers, scroll — ~60)
```

**Alternative (preferred if mixins feel heavy):** extract to free-standing services per concern and inject them.

```
word-translation-sheet.dart (338)
  ├─ word-translation-sheet.dart        (shell + state dispatcher, ~100)
  ├─ word-translation-header.dart       (~60)
  ├─ word-translation-states.dart       (loading + error, ~50)
  └─ word-translation-content.dart      (pronunciation, definition, examples, ~120)
```

```
storage_service.dart (299)
  ├─ storage_service.dart              (GetxService shell + init, ~80)
  ├─ lessons_cache_mixin.dart          (LRU lessons, ~100)
  ├─ chat_cache_mixin.dart             (FIFO chat, ~60)
  └─ preferences_mixin.dart            (preference get/set + permanent flags, ~60)
```

```
auth_controller.dart (274)
  ├─ auth_controller.dart              (base shell + form controllers, ~120)
  ├─ auth_validators.dart               (pure functions, ~50)
  └─ auth_social_mixin.dart             (Google + Apple flows, ~100)
```

```
app-page-definitions-with-transitions.dart (257)
  ├─ app-page-definitions-with-transitions.dart (top-level `pages` + defaults, ~50)
  ├─ routes/onboarding-pages.dart       (~80)
  ├─ routes/auth-pages.dart              (~60)
  └─ routes/main-pages.dart              (~60)
```

```
ai_chat_screen.dart (226)
  ├─ ai_chat_screen.dart                 (screen shell, ~80)
  ├─ chat/widgets/chat_error_banner.dart (~30)
  ├─ chat/widgets/voice_input_overlay.dart (~30)
  └─ chat/widgets/chat_message_list.dart  (~120)
```

```
scenario_card.dart (222)
  ├─ scenario_card.dart                  (shell, ~70)
  ├─ scenario_card_body.dart             (~60)
  ├─ scenario_card_placeholder.dart      (~60)
  └─ scenario_level_dots.dart            (~40)
```

```
login_email_screen.dart (219)
  ├─ login_email_screen.dart             (shell + scroll layout, ~90)
  └─ login_email_form.dart               (form section, ~120)
```

```
language-picker-sheet.dart (254)
  ├─ language-picker-sheet.dart          (sheet shell, ~120)
  └─ language-picker-row.dart            (_PickerRow extracted, ~120)
```

```
api_client.dart (230)
  ├─ api_client.dart                     (HTTP methods + init, ~170)
  └─ api-sse-client.dart                 (postStream + SSE parser, ~60)
  // OR: keep as-is with documented exception since related
```

```
api_exceptions.dart (208)
  Accept minor overage OR extract `mapDioException` + `LanguageContextError` to `api-exception-mapper.dart`.
```

## Related Code Files

**Delete (verify first)**
- `lib/core/services/audio_service.dart` — appears dead, superseded by `lib/core/services/audio/`

**Modify & split** — see Architecture table above.

## Implementation Steps

1. **Verification pass**: grep for `import.*audio_service.dart` (not `audio/`). If zero matches in production code, delete. Run analyze.
2. Split files in order: controllers → services → widgets → screens → routes. Start with smallest (fewest dependents).
3. For mixins-based splits: use `extension` or `mixin` on the base class. Pass controller reference explicitly if no inheritance relationship.
4. Run `flutter analyze` after each split — fail fast on broken imports.
5. Commit per file or small groups (not one giant commit).

## Todo List
- [ ] Verify `audio_service.dart` unused; delete if confirmed
- [ ] Split `ai_chat_controller.dart` (538 → ≤200 per file)
- [ ] Split `word-translation-sheet.dart` (338)
- [ ] Split `storage_service.dart` (299)
- [ ] Split `auth_controller.dart` (274)
- [ ] Split `app-page-definitions-with-transitions.dart` (257)
- [ ] Split `language-picker-sheet.dart` (254) — extract _PickerRow
- [ ] Split `ai_chat_screen.dart` (226)
- [ ] Split `scenario_card.dart` (222)
- [ ] Split `login_email_screen.dart` (219)
- [ ] Evaluate `api_client.dart` split (230) — keep or split
- [ ] Evaluate `api_exceptions.dart` (208) — document exemption or split
- [ ] `flutter analyze` — zero errors, zero new warnings
- [ ] `flutter test` — all green
- [ ] `find lib -name "*.dart" -exec wc -l {} + | awk '$1 > 200'` returns no files (except l10n)

## Success Criteria
- No file in `lib/` over 200 lines (exempt: `l10n/*`).
- `flutter analyze` clean.
- `flutter test` green.
- Smoke: app builds, launches, auth works, chat works, feed works.

## Risk Assessment
- **Risk**: extension/mixin-based splits can confuse debugger stack traces. Mitigation: prefer free-standing services over mixins when state management is complex.
- **Risk**: splitting route file changes the export surface. Mitigation: keep `AppPages.pages` as the single entry; internal split into lists that get concatenated.
- **Risk**: `audio_service.dart` not actually dead — mitigation: full-repo grep before delete, run tests.

## Security Considerations
- None — refactor only.

## Next Steps
- Phase 04 handles remaining memory leaks; cleaner diffs now that files are split.
