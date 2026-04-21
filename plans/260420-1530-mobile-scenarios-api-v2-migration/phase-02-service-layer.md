# Phase 02 — Scenarios Service Layer

## Context Links

- Phase 01 models: `lib/features/scenarios/models/*`
- Existing service pattern: `lib/core/services/language-context-service.dart`, `lib/features/subscription/controllers/subscription-controller.dart`
- DI bindings: `lib/app/bindings/global-dependency-injection-bindings.dart`
- API client: `lib/core/network/api_client.dart`

## Overview

- **Priority:** P0 (prerequisite for phase 3).
- **Status:** completed
- **Brief:** Thin service class wrapping `/scenarios/default` and `/scenarios/personal`. Registered as a singleton GetxService so both feed controllers share one instance. No caching layer — controllers manage their own state.

## Key Insights

- `ActiveLanguageInterceptor` attaches `X-Learning-Language` automatically — service does not manually set it.
- `ApiClient.get<T>` already handles `ApiResponse<T>` unwrapping and `fromJson`. Service returns the typed response.
- No batching / parallel fetch needed in V1 — each tab fires its own call on appearance.

## Requirements

### Functional

- `ScenariosService` with two methods:
  ```dart
  Future<ApiResponse<ScenariosFeedResponse<ScenarioFeedItem>>> getDefaultFeed({int page, int limit});
  Future<ApiResponse<ScenariosFeedResponse<PersonalScenarioItem>>> getPersonalFeed({int page, int limit});
  ```
- Both pass query params `page` and `limit`; no body.
- No explicit `X-Learning-Language` handling — rely on interceptor.
- No client-side caching — keep service stateless.

### Non-Functional

- File ≤ 100 lines.
- Registered as `Get.put(ScenariosService(), permanent: true)` in global bindings.
- Extends `GetxService` (for lifecycle parity with other core services).

## Architecture

```
FloweringFeedController ──┐
                           ├──► ScenariosService ──► ApiClient ──► Dio (+ ActiveLanguageInterceptor)
ForYouFeedController ─────┘
```

## Related Code Files

**Create:**
- `lib/features/scenarios/services/scenarios_service.dart`

**Modify:**
- `lib/app/bindings/global-dependency-injection-bindings.dart` — register `ScenariosService`.

## Implementation Steps

1. Create `scenarios_service.dart`:
   ```dart
   class ScenariosService extends GetxService {
     final ApiClient _apiClient = Get.find<ApiClient>();

     Future<ApiResponse<ScenariosFeedResponse<ScenarioFeedItem>>> getDefaultFeed({
       int page = 1,
       int limit = 20,
     }) {
       return _apiClient.get<ScenariosFeedResponse<ScenarioFeedItem>>(
         ApiEndpoints.scenariosDefault,
         queryParameters: {'page': page, 'limit': limit},
         fromJson: (data) => ScenariosFeedResponse.fromJson(
           data as Map<String, dynamic>,
           ScenarioFeedItem.fromJson,
         ),
       );
     }

     Future<ApiResponse<ScenariosFeedResponse<PersonalScenarioItem>>> getPersonalFeed({
       int page = 1,
       int limit = 20,
     }) {
       return _apiClient.get<ScenariosFeedResponse<PersonalScenarioItem>>(
         ApiEndpoints.scenariosPersonal,
         queryParameters: {'page': page, 'limit': limit},
         fromJson: (data) => ScenariosFeedResponse.fromJson(
           data as Map<String, dynamic>,
           PersonalScenarioItem.fromJson,
         ),
       );
     }
   }
   ```
2. Register in global bindings alongside other singleton services (check insertion order — must be after `ApiClient`).
3. Manual smoke check (if backend is reachable in dev): fire both endpoints via a throwaway call in main debug branch, verify shape.

## Todo List

- [x] Create `scenarios_service.dart` (≤100 lines)
- [x] Register in `global-dependency-injection-bindings.dart` (AppBindings)
- [x] Verify `Get.find<ScenariosService>()` resolves at app boot (via lazyPut + fenix)
- [x] `flutter analyze` clean

## Success Criteria

- Service resolves at runtime (`Get.find<ScenariosService>()` doesn't throw).
- Both methods return typed `ApiResponse` with populated `items`/`pagination` against a real backend.
- No direct Dio usage in service — goes through `ApiClient`.

## Risk Assessment

- **DI ordering** — `ApiClient` init must run before `ScenariosService.onInit`. Existing bindings file has explicit order; append at end.
- **Generic `fromJson`** — Dart generics + JSON can misfire. Test with both DTOs in phase 7.

## Security Considerations

- No auth tokens touched here — `AuthInterceptor` handles.
- No user-controlled input — `page`/`limit` are ints from controllers, not user text.

## Next Steps

- Phase 3 creates the two feed controllers consuming this service.
