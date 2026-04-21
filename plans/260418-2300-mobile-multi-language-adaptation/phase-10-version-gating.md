# Phase 10 — Version Gating (Anonymous Upgrade Wall)

## Context Links

- Brainstorm: [brainstorm-summary.md](brainstorm-summary.md) §Implementation Risks "Forced update flow"
- Backend contract: [mobile-adaptation-requirements.md §8, §10](../../../be_flowering/plans/260418-2238-multi-language-content-architecture/mobile-adaptation-requirements.md) — backend DB fallback covers authed users; anonymous has no fallback.
- Phase 2 interceptor fails anonymous requests without header → old anonymous installs WILL break without a forced update.

## Overview

- **Priority:** P1
- **Status:** pending
- **Description:** Add minimum-version check before anonymous onboarding. Old clients hit an upgrade wall blocking `/onboarding/*` entry. Coordinate version threshold with backend rollout timeline.

## Key Insights

- Per spec §8: backend fallback works for authed users (old app → header-less → DB fallback). Anonymous flow has NO fallback → 400.
- Simplest path: add a remote-config-style min-version endpoint (or reuse RevenueCat / Firebase Remote Config if already wired) that returns `{ minAppVersion: 'x.y.z' }`. Called once on app startup. If current version < min, show upgrade wall.
- Check `lib/features/subscription/services/revenuecat-service.dart` — RevenueCat supports remote config-like attributes. Reuse if available to avoid new endpoint.
- Version read from `package_info_plus` (already in Flutter deps likely) or `pubspec.yaml` constant.
- Upgrade wall UI: full-screen, non-dismissible, CTA opens app store link.

## Requirements

**Functional:**
- On app boot (after `initializeServices()`, before first routing decision):
  - Fetch `minAppVersion` (prefer existing RevenueCat attribute; fall back to new endpoint `GET /app/min-version` if needed — defer endpoint creation pending confirmation).
  - Compare with current version (`package_info_plus`).
  - If current < min: navigate to `UpgradeWallScreen` and skip normal routing.
- `UpgradeWallScreen`: full-screen, shows message + button linking to store listing (iOS App Store URL, Android Play Store URL).
- Wall only blocks anonymous users explicitly: check `AuthStorage` for token; if authed, skip wall (backend DB fallback protects them).
- On upgrade: user installs new version → normal boot.

**Non-functional:**
- Startup cost: min-version check must complete in < 500ms or be non-blocking with default-allow.
- All copy via `.tr`.

## Architecture

```
main() → initializeServices() → VersionGate.check()
                                    │
                                    ├─ authed?   yes → skip gate
                                    │            no
                                    ▼
                                fetchMinVersion()
                                    │ (RevenueCat attr or /app/min-version)
                                    ▼
                                currentVersion < min?
                                    │  yes               no
                                    ▼                    ▼
                             UpgradeWallScreen       normal routing
                             (non-dismissible)
```

## Related Code Files

**CREATE:**
- `lib/core/services/version-gate-service.dart` — encapsulates check.
- `lib/features/upgrade-wall/views/upgrade-wall-screen.dart`
- `lib/features/upgrade-wall/controllers/upgrade-wall-controller.dart`

**MODIFY:**
- `lib/app/flowering-app-widget-with-getx.dart` — insert gate call before initial route decision.
- `lib/app/routes/app-route-constants.dart` — add `upgradeWall = '/upgrade-wall'`.
- `lib/app/routes/app-page-definitions-with-transitions.dart` — add `GetPage`.
- `lib/l10n/english-translations-en-us.dart` + VI — add `upgrade_wall_title`, `upgrade_wall_body`, `upgrade_wall_cta_ios`, `upgrade_wall_cta_android`.
- `pubspec.yaml` — add `package_info_plus` if not present.

**DELETE:** none.

## Implementation Steps

1. Add `package_info_plus` to `pubspec.yaml` (check `flutter pub deps` first — may already be transitive).

2. Create `VersionGateService`:
   ```dart
   class VersionGateService extends GetxService {
     Future<bool> shouldShowUpgradeWall() async {
       final auth = Get.find<AuthStorage>();
       if (await auth.hasValidToken()) return false; // authed users covered by backend fallback
       try {
         final min = await _fetchMinVersion();           // from RevenueCat or endpoint
         final current = (await PackageInfo.fromPlatform()).version;
         return _isBelow(current, min);
       } catch (_) { return false; } // fail open
     }

     Future<String> _fetchMinVersion() async { /* RevenueCat or /app/min-version */ }
     bool _isBelow(String current, String min) { /* semver compare */ }
   }
   ```

3. `UpgradeWallScreen` (BaseStatelessScreen) — logo, title, body, CTA button opening `url_launcher` to `https://apps.apple.com/app/<id>` or `https://play.google.com/store/apps/details?id=<package>`.

4. In `flowering-app-widget-with-getx.dart`, after boot services, before home route decision:
   ```dart
   final gate = Get.put(VersionGateService());
   final wall = await gate.shouldShowUpgradeWall();
   if (wall) {
     // Return MaterialApp with home = UpgradeWallScreen, no routing
   }
   ```

5. Translation keys (EN):
   ```dart
   'upgrade_wall_title':       'Update required',
   'upgrade_wall_body':        "You're on an older version. Please update to continue.",
   'upgrade_wall_cta_ios':     'Update on App Store',
   'upgrade_wall_cta_android': 'Update on Play Store',
   ```
   VI parallel.

6. `flutter analyze` clean.

7. Manual test: set current version < min via local override → confirm wall blocks onboarding.

## Todo List

- [ ] `package_info_plus` available (verify or add)
- [ ] `VersionGateService` created with semver compare
- [ ] `UpgradeWallScreen` + controller created
- [ ] Routes + page definition added
- [ ] Translations added (EN + VI)
- [ ] App boot wired to check gate before routing
- [ ] Authed users bypass gate
- [ ] Store URLs verified on both platforms
- [ ] `flutter analyze` + `flutter test` clean

## Success Criteria

- [ ] Anonymous user on below-min version → sees wall, cannot bypass.
- [ ] Authed user on below-min version → boots normally (backend fallback protects).
- [ ] Network failure fetching min version → fail-open (boot normally).
- [ ] CTA opens correct store listing per platform.

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Min-version source not yet available (neither RevenueCat attr nor endpoint) | High | BLOCKED flag until coordinated with backend team; in interim, hardcode min version in config + ship fix-it release later. |
| Semver compare bug locks out current version users | High | Unit-test `_isBelow`; include boundary cases `0.9.9`, `1.0.0`, `1.0.0+1` (build tag ignored). |
| Network timeout on gate check blocks boot | Medium | 2s timeout + fail-open. |

## Security Considerations

- Store URLs hardcoded per-platform; no dynamic URL risk.
- Min version check is non-security-critical (bypass means user gets old UX, not a vulnerability).

## Next Steps

- After all phases land: coordinate backend rollout → monitor warning logs for header-less requests from old authed clients → bump min-version after 2 releases per spec §10.
- Follow-up: create actual `/app/min-version` endpoint on backend if RevenueCat attribute path rejected.

## Unresolved (escalate before merge)

- **Source of min-version value:** RevenueCat attribute vs new backend endpoint vs Firebase Remote Config. Must resolve before implementation starts.
- **Exact version threshold:** depends on which version first ships the header. Typically `minAppVersion = firstFeatureVersion`.
