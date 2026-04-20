# Phase 04 — Memory Leak Prevention

## Context Links
- `research/researcher-02-memory-leaks.md` L1, L8, L11

## Overview
- **Priority:** P2 (correctness risk, not an immediate outage)
- **Status:** pending
- **Effort:** ~3h

Prevent in-flight HTTP from writing to disposed controllers; cap open Hive boxes; sweep stale temp recordings.

## Key Insights
- `AiChatController` has NO cancellation mechanism. If the user backs out mid-request, resolved futures still mutate `messages` — sometimes silently because Rx survives via fenix.
- `StorageService._langLessonBoxes` accumulates forever on language switches.
- Failed audio uploads leave `.m4a` files in tmp — OS eventually reclaims, but aggregates on user's device.

## Requirements

**Functional**
- No behavior change for happy path.
- On controller dispose mid-flight, requests cancel cleanly and drop their results.

**Non-functional**
- At most 2 language lesson boxes open simultaneously (active + last-used).
- Temp recordings older than 1 hour cleaned on app start.

## Architecture

```
ApiClient.get/post/...(..., CancelToken? cancelToken)
   └─ forwards cancelToken to Dio

BaseController
   └─ late final CancelToken _lifecycleToken = CancelToken();
   └─ onClose(): _lifecycleToken.cancel('disposed');
   └─ apiCall() uses _lifecycleToken by default (override-able per call)

AiChatController
   ├─ uses inherited _lifecycleToken for all requests
   ├─ grammar-check uses separate _grammarToken (cancel previous on new check) — Phase 06
   └─ onClose: cancels token, disposes controllers

StorageService.getLessonsBoxFor(code)
   └─ LRU cache of size 2: when opening a new box, close the oldest

AudioService (or temp cleaner service)
   └─ init: sweep /tmp for recording_*.m4a older than 1h
```

## Related Code Files

**Modify**
- `lib/core/base/base_controller.dart` — add `CancelToken` lifecycle
- `lib/core/network/api_client.dart` — accept `CancelToken?` param on all methods
- `lib/features/chat/controllers/ai_chat_controller.dart` — use lifecycle token
- `lib/core/services/storage_service.dart` — LRU-cap `_langLessonBoxes`
- `lib/core/services/audio_service.dart` OR new `audio/recording-cleanup-service.dart` — sweep old recordings (skip if audio_service is deleted in Phase 03; put sweeper into `record-audio-provider.dart` init)

## Implementation Steps

1. **BaseController**: add `final CancelToken _lifecycleToken = CancelToken();` and `onClose()` cancels it. Expose `cancelToken` getter.
2. **ApiClient**: add optional `CancelToken? cancelToken` to `get/post/put/delete/uploadFile`. Forward to `Dio.get(..., cancelToken: cancelToken)`.
3. **apiCall helper** in BaseController: optionally accept a `CancelToken` but default to `_lifecycleToken`.
4. **AiChatController**: update all `_apiClient.post/get` calls to pass `cancelToken: cancelToken`.
5. Handle `DioException` cancellation as NOT an error (check `CancelToken.isCancelled` before writing state).
6. **StorageService**: add `_langLessonBoxesLru` with max size 2. When 3rd opened, close the least-recently-used box.
7. **Recording cleanup**: on `RecordAudioProvider.init()` (or equivalent), list tmp dir, delete `recording_*.m4a` older than 1 hour.
8. Test: intentionally back out of onboarding chat mid-request; confirm no errors or state updates.

## Todo List
- [ ] Add `_lifecycleToken` + `cancelToken` getter to `BaseController`
- [ ] Cancel token in `BaseController.onClose()`
- [ ] Add `CancelToken?` param to `ApiClient` HTTP methods
- [ ] Update `apiCall` helper to forward cancel token
- [ ] Update `AiChatController` request sites to use cancel token
- [ ] Guard state writes behind `!cancelToken.isCancelled`
- [ ] LRU-cap `_langLessonBoxes` to 2 open boxes
- [ ] Add temp recording sweeper on audio provider init
- [ ] Manual test: back-nav mid-request causes no errors
- [ ] `flutter analyze` clean, `flutter test` green

## Success Criteria
- Backing out of chat during a slow request logs no warnings, no errors, no stale `messages` mutations.
- `lsof` on iOS simulator shows ≤2 open `lessons_cache_*` boxes at any time.
- Tmp dir does not accumulate recordings across multiple app sessions.

## Risk Assessment
- **Risk**: closing a lang box while a background task reads it causes exception. Mitigation: only LRU-close when switching active language (idle moment).
- **Risk**: CancelToken cancellation on a POST that already hit the server means client thinks it failed but server committed. Acceptable — no worse than network timeout; idempotency is backend's concern.
- **Risk**: tmp sweeper deletes a file in-flight for upload. Mitigation: only delete files older than 1h.

## Security Considerations
- Cancelled requests do not expose tokens; no data leak.
- Recording cleanup only touches app's own tmp dir.

## Next Steps
- Phase 05 defers service init now that cleanup is reliable.
