---
phase: 1
priority: high
status: done
---

# Phase 1: Install & Configure flutter_native_splash

## Overview
Add `flutter_native_splash` package and configure it to show orange background + centered logo on both Android and iOS native splash screens.

## Related Code Files

### Files to modify
- `pubspec.yaml` — add dependency + config
- `lib/main.dart` — add `FlutterNativeSplash.preserve()` + `FlutterNativeSplash.remove()`
- `lib/features/onboarding/controllers/splash_controller.dart` — call `FlutterNativeSplash.remove()` when Flutter UI ready

### Files auto-generated (by package)
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/values/styles.xml`
  - `android/app/src/main/res/values-night/styles.xml`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/*`

## Implementation Steps

### 1. Add dependency to pubspec.yaml
```yaml
dependencies:
  flutter_native_splash: ^2.4.4
```

### 2. Add configuration to pubspec.yaml
```yaml
flutter_native_splash:
  color: "#FF7A27"
  image: assets/logos/logo.png

  android_12:
    color: "#FF7A27"
    image: assets/logos/logo.png
    icon_background_color: "#FF7A27"

  ios: true
  android: true
```

### 3. Run the package generator
```bash
cd flowering
flutter pub get
dart run flutter_native_splash:create
```
This auto-generates all native platform files (Android XML, iOS storyboard, asset images).

### 4. Update main.dart — preserve splash until Flutter ready
```dart
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // ... existing init code ...
  runApp(const FloweringApp());
}
```

### 5. Remove native splash when Flutter SplashScreen renders
In `splash_controller.dart` `onInit()`:
```dart
FlutterNativeSplash.remove();
```

## Todo List
- [x] Add `flutter_native_splash: ^2.4.4` to pubspec.yaml dependencies
- [x] Add `flutter_native_splash:` config block to pubspec.yaml
- [x] Run `flutter pub get`
- [x] Run `dart run flutter_native_splash:create`
- [x] Update `main.dart` with `FlutterNativeSplash.preserve()`
- [x] Update `splash_controller.dart` with `FlutterNativeSplash.remove()`
- [x] Verify compile: `flutter analyze`

## Success Criteria
- Native splash shows orange background with centered logo
- No white/blank flash between native splash and Flutter splash
- Seamless transition perceived as single splash screen
- Android 12+ devices show proper splash with logo
- iOS devices show orange background with logo

## Risk Assessment
- **Low risk**: Package is mature (2.4.x), widely used, well-maintained
- **Android 12+ edge case**: The `android_12` config block handles the new SplashScreen API
- **Logo sizing**: Package auto-resizes; may need to check logo doesn't get cropped on small screens
