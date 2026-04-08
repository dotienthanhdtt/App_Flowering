# iOS Simulator CodeSign Build Failure

**Date:** 2026-04-07
**Branch:** feat/tts-stt
**Severity:** Blocking — prevents all simulator builds

---

## Problem

`flutter run` and `flutter build ios --simulator` fail with:

```
Command CodeSign failed with a nonzero exit code
```

Verbose output shows every embedded framework fails codesign:

```
.../Runner.app/Frameworks/AppAuth.framework: resource fork, Finder information, or similar detritus not allowed
.../Runner.app/Frameworks/sqflite_darwin.framework: resource fork, Finder information, or similar detritus not allowed
... (all 15+ frameworks)
```

Direct `xcodebuild` with `BUILD_DIR=/tmp/` succeeds. Direct `xcodebuild` with `BUILD_DIR=~/Documents/.../build/ios` fails identically.

---

## Root Cause

**iCloud Drive FileProvider + `com.apple.provenance` extended attribute.**

The project lives in `~/Documents/` which is managed by iCloud Drive. macOS FileProvider automatically stamps every file created under `~/Documents/` with an irremovable `com.apple.provenance` extended attribute.

```
$ xattr -rl build/ios/Debug-iphonesimulator/Runner.app/Frameworks/
.../Frameworks/: com.apple.provenance:
```

The `codesign` tool interprets `com.apple.provenance` as "resource fork, Finder information, or similar detritus" and refuses to sign any file that carries it.

### Why standard fixes don't work

| Attempted Fix | Result | Why |
|---|---|---|
| `xattr -cr` on project | Fails | `com.apple.provenance` is system-managed, cannot be deleted |
| `flutter clean` + rebuild | Fails | New build artifacts get provenance xattr immediately |
| `.nosync` directory | Fails | `.nosync` prevents iCloud sync but NOT provenance stamping |
| Symlink `build/` → `/tmp/` | Fails | Flutter passes unresolved path to xcodebuild; FileProvider intercepts writes through symlinks from managed directories |
| Script phase to strip xattrs | Fails | `xattr -cr` cannot remove `com.apple.provenance` |

### Why direct xcodebuild with /tmp BUILD_DIR works

When `BUILD_DIR=/tmp/...`, xcodebuild writes directly to `/tmp/` (not FileProvider-managed). No provenance xattr is added. The codesign step succeeds.

---

## Solution

Disable code signing for **simulator SDK only** (`iphonesimulator*`). Simulator doesn't enforce code signatures — the default "Sign to Run Locally" identity is unnecessary.

### Changes Made

**1. `ios/Podfile`** — Disable codesign for all pod targets on simulator:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['CODE_SIGNING_ALLOWED[sdk=iphonesimulator*]'] = 'NO'
    end
  end
end
```

**2. `ios/Runner.xcodeproj/project.pbxproj`** — Disable codesign for Runner target on simulator:

Added to **project-level Debug config** (97C147031CF9000F007C117D):
```
"CODE_SIGNING_ALLOWED[sdk=iphonesimulator*]" = NO;
```

Added to **Runner target Debug config** (97C147061CF9000F007C117D):
```
"CODE_SIGNING_ALLOWED[sdk=iphonesimulator*]" = NO;
```

### Scope

- Only affects `iphonesimulator` SDK builds
- Physical device (`iphoneos`) and Release builds are unaffected
- No impact on App Store distribution

### Additional Cleanup

- Added `GoogleService-Info.plist` and `firebase_options.dart` to `.gitignore` (contain API keys)
- Added `build.nosync` to `.gitignore`
- Removed stale `build.nosync/` directory

---

## Verification

```
$ xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,id=...' \
  -configuration Debug BUILD_DIR=.../build/ios build
** BUILD SUCCEEDED **

$ xcrun simctl get_app_container booted com.flowering.app
/Users/.../Runner.app
APP INSTALLED
```

---

## Long-term Recommendation

Move the project out of `~/Documents/` (e.g. `~/Developer/` or `~/Projects/`) to eliminate iCloud FileProvider interference entirely. This avoids:
- `com.apple.provenance` codesign failures
- iCloud file eviction corrupting pod directories
- Slower I/O from FileProvider interception

---

## Unresolved Questions

- Will Xcode 26 GA fix the `com.apple.provenance` + codesign interaction? (Current: Xcode 26.4 beta)
- Does `CODE_SIGNING_ALLOWED=NO` for simulator cause issues with entitlements-dependent features (e.g., Keychain Sharing, Push Notifications in simulator)?
