# Code Review: Native Splash Screen Fix

**Date:** 2026-03-08
**Scope:** 3 files, ~15 LOC changed
**Focus:** pubspec.yaml, main.dart, splash_controller.dart

## Overall Assessment

The implementation correctly integrates `flutter_native_splash` with the preserve/remove pattern. The approach is sound: preserve the native splash during async initialization in `main()`, then remove it once the Flutter-rendered splash screen takes over. One critical issue found regarding asset generation.

## Critical Issues

### C1. Native splash assets not generated

The `flutter_native_splash:create` command does not appear to have been run. The Android `styles.xml` still contains the default Flutter launch theme rather than the generated splash theme. Without running the generator, the `pubspec.yaml` config block has no effect -- the native splash screen will show the default white screen, not the configured orange background with logo.

**Fix:** Run the generator command:
```bash
cd /Users/tienthanh/Documents/new_flowering/app_flowering/flowering
dart run flutter_native_splash:create
```

This must be run every time the splash config in `pubspec.yaml` changes.

## High Priority

### H1. FlutterNativeSplash.remove() called in onInit -- potential timing issue

In `splash_controller.dart` line 15, `FlutterNativeSplash.remove()` is called immediately in `onInit()`. This is called when the SplashController is first created via `SplashBinding`, which happens when GetX navigates to the splash route. At this point, the Flutter splash UI frame may not yet have been rendered.

This means there could be a brief flash (white frame) between the native splash disappearing and the Flutter splash screen painting.

**Recommendation:** Move `remove()` to `onReady()` instead of `onInit()`. GetX's `onReady()` fires after the first frame is rendered, ensuring the Flutter UI is visible before the native splash is dismissed:

```dart
@override
void onReady() {
  super.onReady();
  FlutterNativeSplash.remove();
}
```

Keep `_checkAuthAndNavigate()` in `onInit()` since it can run in parallel.

### H2. No error handling around initializeServices() in main.dart

If any service initialization fails (e.g., Hive corruption, dotenv file missing), the native splash screen will hang indefinitely since `FlutterNativeSplash.remove()` is never called and `runApp()` is never reached. The user would see a frozen splash screen with no way to recover.

**Recommendation:** Wrap initialization in try-catch and ensure the app still launches with graceful degradation:

```dart
try {
  await dotenv.load(fileName: '.env.$env');
  await Hive.initFlutter();
  await initializeServices();
} catch (e) {
  // Log error, proceed with limited functionality
  debugPrint('Service initialization failed: $e');
}
runApp(const FloweringApp());
```

## Medium Priority

### M1. SplashController still extends GetxController, not BaseController

Previous review (code-reviewer-260228-1624) flagged this as H2. The project convention requires all controllers to extend `BaseController`. Still unresolved.

### M2. android_12 config missing dark_mode variant

The `pubspec.yaml` splash config does not specify `color_dark` or a dark mode variant for Android 12+. On devices with dark mode enabled, the splash may show an unexpected background color.

**Recommendation:** Add dark mode config:
```yaml
flutter_native_splash:
  color: "#FF7A27"
  color_dark: "#FF7A27"  # or a darker variant
  image: assets/logos/logo.png
  android_12:
    color: "#FF7A27"
    color_dark: "#FF7A27"
    image: assets/logos/logo.png
    icon_background_color: "#FF7A27"
    icon_background_color_dark: "#FF7A27"
```

### M3. No web/fullscreen configuration specified

The config does not explicitly set `fullscreen: true` or `web: false`. These default to `false` and `true` respectively, which is likely fine but worth being explicit about.

## Low Priority

### L1. 3-second minimum delay in _checkAuthAndNavigate

The `Future.delayed(Duration(seconds: 3))` combined with the native splash hold creates a cumulative perceived startup time. Now that the native splash covers the initialization period, consider reducing the Flutter splash delay to 1-2 seconds.

## Edge Cases Found by Scouting

1. **Init failure = frozen splash**: If `initializeServices()` throws, native splash hangs forever (covered in H2).
2. **onInit vs onReady timing**: Native splash removed before Flutter frame renders, possible white flash (covered in H1).
3. **Dark mode mismatch**: Android 12 dark mode users see default color instead of brand color (covered in M2).
4. **Duplicate controller creation**: Previous review flagged `SplashBinding` using `Get.put()` without `permanent: true` -- rebuilds could create duplicate controllers. Not directly related to this change but interacts with it since `remove()` could be called multiple times (safe -- `flutter_native_splash` handles this gracefully).

## Positive Observations

- Correct use of the preserve/remove pattern -- this is the recommended approach
- Clean integration, minimal code changes
- Proper placement: preserve in main.dart before async work, remove in the controller
- The `pubspec.yaml` config properly handles both pre-Android 12 and Android 12+ splash

## Recommended Actions (Priority Order)

1. **[CRITICAL]** Run `dart run flutter_native_splash:create` to generate platform assets
2. **[HIGH]** Move `FlutterNativeSplash.remove()` from `onInit()` to `onReady()`
3. **[HIGH]** Add try-catch around initialization in `main.dart`
4. **[MEDIUM]** Add dark mode splash config
5. **[LOW]** Consider reducing the 3-second Flutter splash delay

## Metrics

- Type Coverage: N/A (Dart strong mode handles this)
- Test Coverage: No new tests needed for this change (UI/splash behavior)
- Linting Issues: 0 expected from these changes
