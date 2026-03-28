---
title: "Migrate Flutter JSON keys from camelCase to snake_case"
description: "Update all model fromJson/toJson and request payloads to match new backend snake_case API contract"
status: completed
priority: P1
effort: 2h
branch: kai/refactor/snake-case-api-migration
tags: [api, migration, models, breaking-change]
created: 2026-03-28
completed: 2026-03-28
---

# snake_case API Migration Plan

## Summary

Backend switched all JSON keys to snake_case. Flutter app uses manual `fromJson`/`toJson` with camelCase string literals. Migration is mechanical: update every JSON key string in models, request payloads, and the auth interceptor.

**Approach:** Direct find-and-replace in each file. No architectural changes needed. No serialization library to configure.

**Key facts:**
- Manual JSON serialization (no json_serializable/freezed)
- 11 model files with `json['camelCase']` patterns
- 3 controller files with camelCase request body keys
- 1 service file with camelCase request body keys
- 1 interceptor file with mixed snake_case/camelCase (partially migrated)
- API response wrapper (`code`, `message`, `data`) is unchanged

## Phases

| # | Phase | Files | Status |
|---|-------|-------|--------|
| 1 | [Models - fromJson/toJson](./phase-01-models.md) | 9 | ✅ Completed |
| 2 | [Controllers & Services - request payloads](./phase-02-controllers-services.md) | 4 | ✅ Completed |
| 3 | [Auth interceptor - response parsing](./phase-03-auth-interceptor.md) | 1 | ✅ Completed |
| 4 | [Documentation updates](./phase-04-verify.md) | - | ✅ Completed |

## Key Dependencies

- Backend API must be fully deployed with snake_case before app update ships
- Hive cache will contain old camelCase data; models should handle both formats during transition (or cache should be cleared)

## Risk

- **Cache deserialization**: Cached JSON in Hive (subscription, languages) uses old camelCase keys. After migration, cached data will fail to parse. Mitigation: add fallback reads for old keys OR clear cache on app update.
- **Onboarding session model**: API doc changed field names (`session_id` vs `sessionToken`, `turn_count` vs `turnNumber`, `response` vs `reply`). These are structural changes, not just casing -- needs careful mapping.
