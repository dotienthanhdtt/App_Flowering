# Phase 05 — Card Rendering Updates

## Context Links

- Existing: `lib/features/lessons/widgets/scenario-card.dart` (143 lines — renders `LessonScenario`, hardcodes `trial`)
- Onboarding card: `lib/features/onboarding/widgets/scenario_card.dart`
- Phase 04 new cards: `feed_scenario_card.dart`, `personal_feed_card.dart`

## Overview

- **Priority:** P1 (parallel with phase 4)
- **Status:** completed
- **Brief:** Drop all `trial` branches. Make status+access_tier rendering consistent across the three scenario-card surfaces: Flowering feed (new), For You feed (new), onboarding gift screen (existing). Introduce an `access_tier` premium badge.

## Key Insights

- Backend's `trial` status value is GONE. Any `status == 'trial'` branch in client code is dead after migration — must be deleted, not just dead.
- The onboarding `scenario_gift_screen` uses a different `Scenario` model (AI-generated, not from `/scenarios/*`). Its card doesn't show premium/status badges today — decide if it needs parity. **Decision: leave as-is; onboarding scenarios are always `free` / `available` by nature.**
- `feed_scenario_card.dart` (new in phase 4) and old `scenario-card.dart` share ~70% of the image-overlay logic. **Do not refactor into shared abstract** — phase 6 deletes `scenario-card.dart` entirely anyway.

## Requirements

### Functional

- `feed_scenario_card.dart`:
  - Thumbnail + title + status badge (top-right) + access_tier badge (top-left).
  - `ScenarioUserStatus.locked` → dark overlay + lock badge.
  - `ScenarioUserStatus.learned` → check badge.
  - `ScenarioUserStatus.available` → no status badge.
  - `ScenarioAccessTier.premium` → "PRO" pill top-left (small, gold-ish).
  - `ScenarioAccessTier.free` → no badge.
- `personal_feed_card.dart`:
  - Text-only row, no thumbnail.
  - Status: `learned` → muted style + check icon trailing.
  - `locked` → not possible here (user has already unlocked via source); if encountered, render as `available`.
  - `source: personalized` → "AI" pill next to title.
  - `source: kol` → "KOL" pill next to title + optional KOL name suffix (if backend adds later).
- Deprecated `scenario-card.dart`:
  - Drop `status == 'trial'` branch (line 43 check already maps trial to "normal card" — deletion is a no-op functionally). Phase 6 deletes the file entirely.

### Non-Functional

- Each card file ≤ 200 lines.
- No shared abstract base — keep cards independent to allow divergence.
- Badges live in `source_badge.dart` (phase 4) + new `access_tier_badge.dart`.

## Architecture

```
Flowering grid ──► FeedScenarioCard ──► [AccessTierBadge] [StatusBadge]
                                    └── [BackdropBlur title overlay]

For You list ──► PersonalFeedCard ──► [SourceBadge] [learned check]
```

## Related Code Files

**Create:**
- `lib/features/scenarios/widgets/access_tier_badge.dart` — "PRO" pill for `premium`; returns `SizedBox.shrink()` for `free`.

**Modify:**
- `lib/features/scenarios/widgets/feed_scenario_card.dart` (from phase 4) — add status badge logic + access_tier badge.
- `lib/features/scenarios/widgets/personal_feed_card.dart` (from phase 4) — add learned style + source badge.

**No change:**
- `lib/features/lessons/widgets/scenario-card.dart` — phase 6 deletes.
- `lib/features/onboarding/widgets/scenario_card.dart` — onboarding unaffected.

## Implementation Steps

1. Create `access_tier_badge.dart`:
   ```dart
   class AccessTierBadge extends StatelessWidget {
     final ScenarioAccessTier tier;
     const AccessTierBadge({super.key, required this.tier});
     @override
     Widget build(BuildContext context) {
       if (tier != ScenarioAccessTier.premium) return const SizedBox.shrink();
       return Container(
         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
         decoration: BoxDecoration(
           color: AppColors.accentGoldColor, // add if missing
           borderRadius: BorderRadius.circular(8),
         ),
         child: const AppText('PRO', variant: AppTextVariant.caption),
       );
     }
   }
   ```
   If `accentGoldColor` doesn't exist in `app_colors.dart`, add: `Color(0xFFD4A017)` (or pick from design tokens).
2. Extend `feed_scenario_card.dart`:
   - Add `Positioned(top: 8, left: 8, child: AccessTierBadge(tier: item.accessTier))`.
   - Status badge uses `ScenarioUserStatus` enum switch — no string compares.
3. Extend `personal_feed_card.dart`:
   - `if (item.status == ScenarioUserStatus.learned) Icon(LucideIcons.check, color: AppColors.successColor)`.
   - Place `SourceBadge(source: item.source)` next to title.
4. Grep-verify no residual `trial` string comparisons in the `scenarios` feature dir.
5. Run `flutter analyze`.

## Todo List

- [x] Create `access_tier_badge.dart`
- [x] Add `accentGoldColor` to `app_colors.dart` if missing
- [x] Extend `feed_scenario_card.dart` with access_tier + status enum-based badges
- [x] Extend `personal_feed_card.dart` with learned + source handling
- [x] Grep: `'trial'` string in `lib/features/scenarios/` → zero hits
- [x] `flutter analyze` clean

## Success Criteria

- 6-state matrix renders correctly on Flowering tab (available/locked/learned × free/premium).
- For You items render source badge correctly.
- No client-side reference to `'trial'` in new `scenarios` feature.
- Visual sanity check: Premium pill readable against any background image.

## Risk Assessment

- **Gold badge contrast** — ensure `PRO` pill text legible on light/dark backgrounds. Test with dark-theme screenshots in phase 7.
- **Status ordering** — if both `locked` and `learned` somehow appear (shouldn't — backend exclusive), render `learned` wins (explicit precedence in switch).
- **KOL name not in payload** — `PersonalScenarioItem` doesn't include KOL name per spec. Just show "KOL" badge; revisit when backend adds.

## Security Considerations

- None — rendering only.

## Next Steps

- Phase 6 deletes old `scenario-card.dart` and `lesson-models.dart`, migrates remaining references.
