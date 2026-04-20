# Phase 01 — Models & API Endpoints

## Context Links

- Brainstorm: [reports/brainstorm-260420-1100-mobile-api-v2-migration.md](../reports/brainstorm-260420-1100-mobile-api-v2-migration.md)
- Current models: `lib/features/lessons/models/lesson-models.dart`, `lib/features/onboarding/models/scenario_model.dart`
- Endpoints: `lib/core/constants/api_endpoints.dart`

## Overview

- **Priority:** P0 (prerequisite for phase 2-6)
- **Status:** completed
- **Brief:** Create the new `scenarios` feature dir with enum + feed-item models. Add two new endpoint constants. Update existing models additively (`access_tier`, `type`) — dropping `trial` lives in phase 5.

## Key Insights

- Backend `/scenarios/default` items include: `id, title, description, image_url, difficulty, language_id, access_tier, order_index`. Spec implies `type` + `status` (computed) also present — confirm from response, add defensively.
- `/scenarios/personal` items: `id, title, description, difficulty, language_id, added_at, source`. No `image_url`. Also needs `access_tier` + `status` + `type` for the shared card renderer.
- Parse defensively: unknown enum value → fallback to safe default. This prevents runtime crashes if backend adds new values (e.g. future `type: "community"`).

## Requirements

### Functional

- New enums parsed from strings, with `fromString` factory that falls back:
  - `ScenarioAccessTier` — `free | premium` (default: `free`)
  - `ScenarioUserStatus` — `available | locked | learned` (default: `available`)
  - `ScenarioType` — `defaultType | kol` (default: `defaultType`)
  - `PersonalSource` — `personalized | kol` (default: `personalized`)
- New `ScenarioFeedItem` model for Flowering tab (default feed):
  - `id, title, description, imageUrl?, difficulty, languageId, accessTier, status, type, orderIndex`
- New `PersonalScenarioItem` model for For You tab:
  - `id, title, description, difficulty, languageId, addedAt, source, accessTier, status, type`
- New `ScenariosPagination` (page, limit, total).
- New `ScenariosFeedResponse<T>` generic wrapper (`items` + `pagination`).
- Update `LessonScenario.status` comment — still parses strings but `trial` branch deprecated (actual branch removal in phase 5).
- Update `Scenario` (onboarding) — add optional `accessTier`, `type` fields (nullable-safe) without breaking existing AI-generated payloads.

### Non-Functional

- All new files under 150 lines.
- Enums use `fromString` factory pattern — single source of parse logic.
- Models are immutable (`const` constructors where possible).
- snake_case file names (Dart convention).

## Architecture

```
lib/features/scenarios/
└── models/
    ├── scenario_access_tier.dart       # enum
    ├── scenario_user_status.dart        # enum
    ├── scenario_type.dart               # enum
    ├── personal_source.dart             # enum
    ├── scenario_feed_item.dart          # Flowering tab item
    ├── personal_scenario_item.dart      # For You tab item
    ├── scenarios_pagination.dart        # shared pagination
    └── scenarios_feed_response.dart     # generic {items, pagination} wrapper
```

## Related Code Files

**Create:**
- `lib/features/scenarios/models/scenario_access_tier.dart`
- `lib/features/scenarios/models/scenario_user_status.dart`
- `lib/features/scenarios/models/scenario_type.dart`
- `lib/features/scenarios/models/personal_source.dart`
- `lib/features/scenarios/models/scenario_feed_item.dart`
- `lib/features/scenarios/models/personal_scenario_item.dart`
- `lib/features/scenarios/models/scenarios_pagination.dart`
- `lib/features/scenarios/models/scenarios_feed_response.dart`

**Modify:**
- `lib/core/constants/api_endpoints.dart` — add `scenariosDefault`, `scenariosPersonal` constants.
- `lib/features/onboarding/models/scenario_model.dart` — add nullable `accessTier`, `type` fields parsed via new enums. Keep existing fields intact.

**No change:**
- `lib/features/lessons/models/lesson-models.dart` — full cleanup deferred to phase 5/6.

## Implementation Steps

1. Create `scenario_access_tier.dart`:
   ```dart
   enum ScenarioAccessTier {
     free,
     premium;

     static ScenarioAccessTier fromString(String? raw) {
       switch (raw) {
         case 'premium': return ScenarioAccessTier.premium;
         default: return ScenarioAccessTier.free;
       }
     }

     String get apiValue => name;
   }
   ```
2. Create `scenario_user_status.dart`, `scenario_type.dart`, `personal_source.dart` with same pattern. For `ScenarioType`, reserve `defaultType` (Dart keyword collision with `default`) but serialize as `'default'`.
3. Create `scenarios_pagination.dart`:
   ```dart
   class ScenariosPagination {
     final int page;
     final int limit;
     final int total;
     const ScenariosPagination({required this.page, required this.limit, required this.total});
     factory ScenariosPagination.fromJson(Map<String, dynamic> j) => ScenariosPagination(
       page: j['page'] as int? ?? 1,
       limit: j['limit'] as int? ?? 20,
       total: j['total'] as int? ?? 0,
     );
   }
   ```
4. Create `scenarios_feed_response.dart` — generic wrapper:
   ```dart
   class ScenariosFeedResponse<T> {
     final List<T> items;
     final ScenariosPagination pagination;
     const ScenariosFeedResponse({required this.items, required this.pagination});
     factory ScenariosFeedResponse.fromJson(
       Map<String, dynamic> json,
       T Function(Map<String, dynamic>) itemFromJson,
     ) => ScenariosFeedResponse(
       items: (json['items'] as List<dynamic>? ?? [])
           .whereType<Map<String, dynamic>>()
           .map(itemFromJson)
           .toList(),
       pagination: ScenariosPagination.fromJson(
         json['pagination'] as Map<String, dynamic>? ?? {},
       ),
     );
   }
   ```
5. Create `scenario_feed_item.dart`:
   - Fields per spec §3.1.
   - `fromJson`: parse enums via `fromString` factories.
   - `imageUrl` nullable — backend returns URL for default feed.
6. Create `personal_scenario_item.dart`:
   - Fields per spec §3.2 — no `imageUrl`, has `source`, has `addedAt` (parse `DateTime`).
   - Same enum parsing for `accessTier`, `status`, `type`.
7. Update `api_endpoints.dart`:
   ```dart
   // Scenarios
   static const String scenariosDefault = '/scenarios/default';
   static const String scenariosPersonal = '/scenarios/personal';
   ```
   Keep `lessons` constant — removed in phase 6.
8. Update `scenario_model.dart` (onboarding):
   - Add `final ScenarioAccessTier? accessTier;` (nullable — onboarding AI may not set it)
   - Add `final ScenarioType? type;`
   - Parse in `fromJson` with `fromString` only if key present; else `null`.
9. Run `flutter analyze` on all touched files.

## Todo List

- [x] Create 4 enum files with `fromString` + `apiValue` pattern
- [x] Create `scenarios_pagination.dart` + `scenarios_feed_response.dart`
- [x] Create `scenario_feed_item.dart` with enum-aware `fromJson`
- [x] Create `personal_scenario_item.dart` with `DateTime` parsing
- [x] Add `scenariosDefault`, `scenariosPersonal` to `api_endpoints.dart`
- [x] Add nullable `accessTier`, `type` to onboarding `Scenario` model
- [x] `flutter analyze` clean

## Success Criteria

- All 8 new model files compile without errors.
- Enum `fromString` returns safe default on unknown input (unit-testable).
- Onboarding gift screen still renders (no regression from nullable field addition).
- No changes yet to `/lessons` flow — existing Home screen unaffected.

## Risk Assessment

- **Dart keyword `default`** — `ScenarioType.default` illegal. Use `defaultType` in Dart but serialize `'default'` via `apiValue` getter.
- **Nullable vs required on onboarding `Scenario`** — keep nullable; onboarding AI-generated payloads may omit these fields forever.
- **Backend field drift** — if `/scenarios/*` later adds fields, defensive parsing keeps client compatible.

## Security Considerations

None — pure model/enum work, no network or storage changes.

## Next Steps

- Phase 2 consumes these models to build the service layer.
