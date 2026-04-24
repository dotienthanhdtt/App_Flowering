# Code Review: scenario-chat / scenarios / chat

One-line: Functionally sound slice with good separation of concerns; one definite runtime crash in `scenario_chat_screen`, one wrong-language translation default, one unsanitized HTML sink, and several lifecycle/lurking-async concerns.

Scope: 3 feature dirs, ~60 files, ~4500 LOC reviewed.

---

## Critical (must fix)

1. **ObxError crash on scenario chat entry** — `lib/features/scenario-chat/views/scenario_chat_screen.dart:31`
   Issue: `Obx(() => ChatTopBar(title: controller.scenarioTitle))` — `scenarioTitle` is a plain `final String`, no `.obs` accessed; GetX 4.6 throws `ObxError: the improper use of a GetX has been detected` when an Obx builder observes zero reactives.
   Fix: Remove the Obx wrapper: `ChatTopBar(title: controller.scenarioTitle)`.

2. **Wrong translation language defaults in scenario chat** — `scenario_chat_controller_translation.dart:26-29`
   Issue: `_translation.translateContent(text, conversationId: …)` omits `sourceLang` / `targetLang`, so `TranslationService` falls back to hard-coded `en`→`vi`. Scenarios in other target languages will return incorrect translations.
   Fix: Pass `sourceLang: _targetLanguage` and `targetLang: <user native>` from a controller-owned native-language accessor (mirror how `ai_chat_controller_grammar_translation.dart:27-29` does it).

3. **Unsanitized HTML rendering of server string** — `lib/features/chat/widgets/grammar_correction_section.dart:48`
   Issue: `HtmlWidget(correctedText, ...)` renders raw server-sourced HTML (`/ai/chat/correct` response). No allowlist / no `factoryBuilder`. Malicious or accidental `<a href="javascript:…">`, `<iframe>`, or scripted content can render or leak taps. Backend compromise → UI attack surface on every user.
   Fix: Either switch to `AppText` (plain text) if the correction is only bold/italic words, or pass a restrictive `factoryBuilder`/`onTapUrl`/`customWidgetBuilder` allowlist. Strip unknown tags server-side too.

4. **Binding calls `Get.back()` during `dependencies()` mid-routing** — `scenario_chat_binding.dart:12`, `scenario_detail_binding.dart:12`
   Issue: Calling `Get.back()` inside a binding that hasn't finished installing leaves the target route partially on the stack and the controller un-registered; the next `Get.find<ScenarioChatController>()` inside the view then throws. Also masks whatever caller sent malformed args.
   Fix: Register a dummy controller or throw `ArgumentError`, and validate args at the call site before navigation.

## Important (should fix)

5. **`FormData.fromMap` containing `MultipartFile` built from a file path** — `scenario_chat_controller_voice.dart:32-34`, `ai_chat_controller_voice.dart:35-37`
   Issue: `await MultipartFile.fromFile(filePath, filename: 'voice.m4a')` — if user cancels STT or the temp file is purged between stop and upload, `fromFile` throws `FileSystemException`. Caught silently (`catch (_)`) so lost transcription is invisible; but also leaks the file path on some platforms via Dio logs.
   Fix: Guard with `File(filePath).existsSync()` first, delete the temp after upload, and log failure to analytics (even if silent in UI).

6. **Grammar / transcription callbacks outlive the controller** — `scenario_chat_controller_voice.dart:44-51`, `scenario_chat_controller_grammar.dart:49-54`, mirrored in chat
   Issue: After `onClose` the ScrollController/TextEditingController are disposed, but in-flight `_sendAudioForTranscription` / `_checkGrammar` still mutate `messages` and call `messages.refresh()`. The Rx survives but the controller is `_lifecycleToken.isCancelled` — mutations are wasted and, if `_scrollToBottom()` fires after close, `scrollController.hasClients` check is safe but touching a disposed controller on iOS has triggered asserts in past Flutter versions.
   Fix: Check `!_lifecycleToken.isCancelled` (or a local `_disposed` bool set in `onClose`) before mutating after `await`.

7. **ScenarioDetailController language-change `Get.back()` too aggressive** — `scenario_detail_controller.dart:28-30`
   Issue: `ever<String?>(_langCtx.activeCode, (_) { Get.back(); })` fires on ANY change including a user-initiated setActive that pushed a NEW detail page onto the stack. If a race yields back-before-push, it pops the previous screen. Also no guard against `Get.back()` racing with hardware-back: can pop two routes.
   Fix: Capture language at onInit, compare on change, and only pop if the stack's top is this screen (`Get.isDialogOpen != true` + route-check).

8. **Raw `TextField` used instead of `AppTextField`** — `lib/features/chat/widgets/chat_text_input_field.dart:32`
   Issue: CLAUDE.md mandates `AppTextField` for consistency. Current raw `TextField` bypasses shared styling and accessibility conventions.
   Fix: Replace with `AppTextField` (or extend AppTextField to support hint-only collapsed variant used here).

9. **Raw `Text()` used for scenario card title** — `lib/features/scenarios/widgets/feed_scenario_card.dart:109-120`
   Issue: `Text(item.title, ...)` with hardcoded `fontFamily: 'Outfit'` violates the `AppText` rule.
   Fix: Use `AppText` variant; centralize the frosted-title style.

10. **`sendMessage` silently drops on null conversationId** — `ai_chat_controller_messaging.dart:10`
    Issue: `if (_conversationId == null || isChatComplete.value) return;` — also clears `textEditingController.clear()` is NOT executed in this early-return path (good), but the user also gets ZERO feedback. If backend `/onboarding/chat` create call is still pending at user's first tap, the message is silently lost.
    Fix: Show snackbar or queue for retry after session established.

11. **Fire-and-forget `sendMessage(result.transcribedText)` not awaited** — `ai_chat_controller_voice.dart:20`
    Issue: Unawaited async, unlike the scenario-chat twin (`await sendText(...)` on line 16 of voice). Inconsistency can cause ordering bugs if user starts a second recording while first STT is still racing.
    Fix: `await sendMessage(...)` or explicitly document intent.

12. **API contract — `pagination.limit == 0` guard incomplete** — `flowering_feed_controller.dart:80-82` / `for_you_feed_controller.dart:80-82`
    Issue: `final limit = feed.pagination.limit == 0 ? _pageLimit : feed.pagination.limit;` — then `_hasMore = _page * limit < feed.pagination.total;`. If backend returns `total: -1` (unknown total) or `limit > total`, logic drifts. Also, if page N returns fewer items than `limit` but `total` is stale, hasMore falsely true → infinite loop retrying page N+1.
    Fix: Also break when `feed.items.isEmpty` or `feed.items.length < limit`.

13. **`messages[i].text = accurate` mutates after `await`** — `ai_chat_controller_voice.dart:50`, `scenario_chat_controller_voice.dart:46`
    Issue: If the user sends a SECOND voice message before the FIRST transcription upload completes, the loop finds the LAST user message and replaces its text with the FIRST recording's backend transcription — corrupts the wrong message.
    Fix: Capture `userMessageId` when adding the user bubble and pass it through the transcription future; match by id, not by position.

## Minor / nitpicks

14. **Files at/over 200 lines** — `scenario_chat_screen.dart` (208), `scenario_detail_screen.dart` (212), `ai_chat_screen.dart` (228), `ai_chat_controller_session.dart` (200).
    Fix: Extract `_VoiceInputOverlay`, `_ErrorBanner`, `_ChatList` into their own files under `widgets/`.

15. **`ChatMessage.showCorrection = true` default** — `chat_message_model.dart:30`.
    Issue: Every new chat message has `showCorrection = true` by default, so a user message with NO corrected text would still try to render the section (handled by `if (msg.correctedText != null)` in the view, so harmless — but the default is semantically wrong).
    Fix: default to `false`.

16. **Non-deterministic user message IDs** — `user_${DateTime.now().millisecondsSinceEpoch}` (2 places).
    Issue: Two rapid-fire sends within the same millisecond collide on ID. Then `indexWhere(m.id == messageId)` resolves to the first match → grammar correction applied to wrong bubble.
    Fix: Use `const Uuid().v4()` like scenario-chat already does for AI messages.

17. **Scroll animation on disposed controller** — `_scrollToBottom` in both controllers.
    Issue: `hasClients` guard is there, but animateTo(250ms) runs on a possibly-about-to-dispose controller. Low probability; no observed crash.
    Fix: Check `_lifecycleToken.isCancelled` before animating.

18. **`Get.context` may be null** — `scenario_chat_controller_translation.dart:44`
    Issue: `final ctx = Get.context; if (ctx == null) return;` — silent drop on word tap, no user feedback.
    Fix: Pass context from view (`ai_chat` variant already does).

19. **scenario_chat_controller.dart uses `Get.find<TranslationService>()` via accessor inside every access** — `:67`
    Minor perf: fine, but inconsistent with other services eagerly captured at field-init.

## Adversarial findings (red-team)

A. **Kickoff + rapid back-nav leak** — `sendKickoff()` fires in `onInit`; if user backs out immediately, `apiCall` still resolves, `onSuccess` sets `turn`/`maxTurns` on a closed controller. Benign (BaseController's `_lifecycleToken` absorbs), but `_addAiMessage` triggers `_ttsService.speak` — the TTS will play after the user has left the screen.

B. **TTS auto-play on hidden screen** — `_addAiMessage` fires `speak` if `autoPlayEnabled`. No guard against backgrounding or page pop. On iOS backgrounded audio with no audio session configured can crash the engine.

C. **Rotation during kickoff** — Controller is preserved (GetX), but `scrollController.dispose()` in `onClose` runs only when the route is popped. Multiple orientations do not re-run onInit. OK, but confirm controller is `permanent: false` (default lazyPut, yes).

D. **Very long AI reply** — `AppTappablePhrase` splits by space; a 10k-word reply builds 10k `TapGestureRecognizer`s, all kept in memory. No virtualization. Potential jank / OOM on long responses.

E. **Empty `reply` from server** — `_addAiMessage('')` early-returns silently; but `turn`/`completed` are still updated. Conversation state advances but UI shows nothing — user sees the typing bubble disappear and thinks chat crashed.
Fix: fallback message `chat_empty_reply`.

F. **Concurrent language switch during fetch** — `flowering_feed_controller` handles it via `_fetchGen` guard, but `ForYouFeedController` has the same guard; both trigger off the same `LanguageContextService` emit. If both workers fire, they each kick a fresh fetch cleanly. But if a pull-to-refresh is also mid-flight, `isRefreshing` is never reset for the language-triggered fetch (only `fetchFeed` called from `refreshFeed` toggles it). Minor UX glitch.

G. **Locked scenario reached anyway** — `scenario_detail_controller.startChat()` navigates unconditionally; there's no client-side guard if `detail.isLocked == true`. Backend returns 403 on `/scenario/chat`, the `ForbiddenException` path shows snackbar + `Get.back()`, OK. But the free tier could tap `Start` if CTA logic has a bug; consider double-checking in `startChat`.

H. **Scenario detail `notFound` not reset on retry** — `scenario_detail_controller.fetch` only sets `notFound = true`; on retry after temporary 404 it does not reset. User stuck. Fix: set `notFound.value = false` at start of fetch.

---

## Unresolved questions

- Is `flutter_widget_from_html_core` configured with a tag allowlist anywhere globally, or is `grammar_correction_section` the first consumer? (affects severity of finding #3)
- What does the backend guarantee about `reply` being non-empty? If it can be empty on benign conditions, finding E needs backend coordination.
- Is there a product preference for silently dropping user messages on null `_conversationId` (finding #10) vs showing an error?
- Does `translateContent` backend support auto-detecting source/target or does the caller genuinely need both? (affects fix shape for finding #2)
