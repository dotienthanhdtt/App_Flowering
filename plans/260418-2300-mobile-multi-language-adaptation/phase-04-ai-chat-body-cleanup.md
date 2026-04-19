# Phase 04 — AI Chat Body Cleanup + TTS/STT Getter Update

## Context Links

- Brainstorm: [brainstorm-summary.md](brainstorm-summary.md) §3, §7
- Backend contract: [mobile-adaptation-requirements.md §4](../../../be_flowering/plans/260418-2238-multi-language-content-architecture/mobile-adaptation-requirements.md)
- Phase 02: interceptor now injects header — body field is redundant.
- Referenced file: `lib/features/chat/controllers/ai_chat_controller.dart` (lines 51, 159, 334, 356, 436, 491)

## Overview

- **Priority:** P0
- **Status:** done
- **Description:** Drop `targetLanguage` from AI chat request body in `_createSession()` (line 159) and `_checkGrammar()` (line 436). Update `_targetLanguage` getter (line 51) plus TTS/STT callers (lines 334, 356, 491) to read from `LanguageContextService` instead of `OnboardingController`.

## Key Insights

- Backend prefers header over body; mixed sending was a transition-window accommodation. Brainstorm §3: remove immediately — backend DB fallback covers old app versions.
- TTS/STT still need the raw language code for device audio APIs (not HTTP). That read should come from `LanguageContextService.activeCode` so post-onboarding switches (phase 8) take effect without a chat controller restart.
- Grammar check endpoint (`/ai/chat/correct`) currently ships `target_language` in body; per backend plan it reads from header too — drop the body field.
- Translate endpoint at line 289 ships `source_lang` + `target_lang` derived from onboarding controller — this is a bi-directional API (sentence translation source + target), NOT the learning language scope. Leave untouched.

## Requirements

**Functional:**
- Remove `targetLanguage` from `_createSession()` POST body (line 159).
- Remove `target_language` from `_checkGrammar()` POST body (line 436).
- Replace `_targetLanguage` getter (line 51) to read from `LanguageContextService` instead of `_onboardingCtrl.selectedLearningLanguage.value`.
- TTS (`_ttsService.speak(..., language: _targetLanguage)` at lines 334, 491) and STT (`_voiceInputService.startVoiceInput(language: _targetLanguage)` at line 356) now read through the service via the getter.
- Translate endpoint call (lines 284-292) stays as-is — bidirectional translation params.

**Non-functional:**
- File stays under 200 lines per existing limit — currently 533 lines. **Out of scope to refactor file size** (flagged as tech debt, not this phase's job).

## Architecture

```
AiChatController
  │
  ├─ _targetLanguage getter ──► LanguageContextService.activeCode
  │                                   │
  │   (was: OnboardingController.selectedLearningLanguage)
  │
  ├─ _createSession()  body: { nativeLanguage }         (targetLanguage removed)
  │                    header: X-Learning-Language: <code>  (via interceptor)
  │
  ├─ _checkGrammar()   body: { previous_ai_message, user_message, conversation_id? }
  │                    header: X-Learning-Language
  │
  ├─ TTS call          language: _targetLanguage   (read from service)
  └─ STT call          language: _targetLanguage   (read from service)
```

## Related Code Files

**MODIFY:**
- `/Users/tienthanh/Dev/new_flowering/app_flowering/flowering/lib/features/chat/controllers/ai_chat_controller.dart`

**NOT MODIFIED (explicit):** 
- `toggleTranslation()` at line 270 — bidirectional translate params are independent concern.

**CREATE:** none. **DELETE:** none.

## Implementation Steps

1. Add import near top:
   ```dart
   import '../../../core/services/language-context-service.dart';
   ```

2. Add field:
   ```dart
   final LanguageContextService _langCtx = Get.find();
   ```

3. Replace `_targetLanguage` getter (line 51):
   ```dart
   String get _targetLanguage => _langCtx.activeCode.value ?? '';
   ```

4. In `_createSession()` (line 155-162), replace body with:
   ```dart
   data: {
     'nativeLanguage': _onboardingCtrl.selectedNativeLanguage.value,
   },
   ```
   Remove `'targetLanguage': _onboardingCtrl.selectedLearningLanguage.value,` line.

5. In `_checkGrammar()` (line 432-439), remove `target_language` line from body:
   ```dart
   data: {
     'previous_ai_message': previousAiMessage,
     'user_message': userText,
     if (_conversationId != null) 'conversation_id': _conversationId,
   },
   ```

6. Lines 334, 356, 491 need no code change — they already reference `_targetLanguage` which now sources from service.

7. Defensive check at start of `_createSession()`:
   ```dart
   if (_langCtx.activeCode.value == null || _langCtx.activeCode.value!.isEmpty) {
     errorMessage.value = 'err_language_required'.tr; // phase 6 adds key
     Get.offNamed(AppRoutes.onboardingLearningLanguage);
     return;
   }
   ```
   This catches the degenerate case where chat is entered without picker — routes back.

8. `flutter analyze` clean. Smoke test: HTTP logger shows no `targetLanguage` field in `/onboarding/chat` body, but `X-Learning-Language` header present.

## Todo List

- [ ] Import + `_langCtx` field added
- [ ] `_targetLanguage` getter reads from service
- [ ] `_createSession()` body no longer ships `targetLanguage`
- [ ] `_checkGrammar()` body no longer ships `target_language`
- [ ] Defensive pre-check routes back to picker if code null
- [ ] Verify TTS/STT still receive non-empty language string in normal flow
- [ ] `flutter analyze` clean
- [ ] Manual verify via HTTP logger: body clean, header present

## Success Criteria

- [ ] `grep -n 'targetLanguage'` in chat controller returns zero hits (except translate body which is independent).
- [ ] `/onboarding/chat` + `/ai/chat/correct` bodies no longer contain language field per logger.
- [ ] TTS + STT still play/listen in correct language after language switch (phase 8 verification).

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Translate endpoint confusion | Low | Explicit callout: translate body retains `source_lang`/`target_lang` — these are translation direction params, not scope. |
| Empty `_targetLanguage` when TTS fires before picker completes | Medium | Defensive pre-check + phase 3 guarantees service set before chat navigation. |
| Old Flutter build uploaded to stores still sends field | Low | Backend ignores body when header present — harmless. |

## Security Considerations

- None — language code is not sensitive.

## Next Steps

- No direct dependents; phase 5-10 proceed in parallel where their graph allows.
