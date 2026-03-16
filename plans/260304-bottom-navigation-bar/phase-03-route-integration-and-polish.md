# Phase 3: Route Integration & Polish

## Context
- [Plan Overview](plan.md)
- [Phase 1](phase-01-dependencies-and-navigation-shell.md)
- [Phase 2](phase-02-tab-screen-content.md)

## Overview
- **Priority**: P1
- **Status**: completed
- **Description**: Wire MainShellScreen into GetX routes, remove placeholder screens, add route constants, verify end-to-end flow. Routes fully integrated and tested.

## Related Code Files

### Files to Modify
- `lib/app/routes/app-route-constants.dart` — Add read, vocabulary routes
- `lib/app/routes/app-page-definitions-with-transitions.dart` — Replace /home placeholder, import MainShellScreen + binding
- `lib/features/home/bindings/main-shell-binding.dart` — Register all tab controllers

### Files to Verify (no changes expected)
- `lib/features/onboarding/controllers/splash_controller.dart` — Already navigates to `/home`
- `lib/features/auth/controllers/auth_controller.dart` — Already navigates to `/home`

## Implementation Steps

### 1. Update Route Constants
```dart
// In app-route-constants.dart, add:
static const String read = '/read';
static const String vocabulary = '/vocabulary';
```

### 2. Update MainShellBinding
Register all tab controllers in MainShellBinding so they're available when MainShellScreen loads:

```dart
class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<MainShellController>(MainShellController(), permanent: true);
    Get.lazyPut<ChatHomeController>(() => ChatHomeController());
    Get.lazyPut<ReadController>(() => ReadController());
    Get.lazyPut<VocabularyController>(() => VocabularyController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
```

### 3. Update Route Definitions
In `app-page-definitions-with-transitions.dart`:

1. Add imports for MainShellScreen, MainShellBinding
2. Replace the /home GetPage:
```dart
GetPage(
  name: AppRoutes.home,
  page: () => const MainShellScreen(),
  binding: MainShellBinding(),
  transition: Transition.fade,
  transitionDuration: defaultDuration,
),
```
3. Remove placeholder imports and _PlaceholderScreen class (if no longer used)
4. Keep /lessons, /profile, /settings routes if needed for deep links — or remove if only accessible via tabs

### 4. Verify Navigation Flow
After auth success or splash check:
- `Get.offAllNamed(AppRoutes.home)` → MainShellScreen loads → Chat tab visible
- Bottom nav works, all 4 tabs switch correctly

### 5. Clean Up
- Remove any unused _PlaceholderScreen references
- Remove commented-out bindings in route defs
- Ensure no orphaned imports

## Todo List
- [x] Add route constants for read, vocabulary
- [x] Update MainShellBinding with all tab controllers
- [x] Replace /home GetPage with MainShellScreen
- [x] Keep _PlaceholderScreen for other routes (lessons, settings, register, etc.)
- [x] Clean up unused imports/routes
- [x] Run `flutter analyze` — zero errors
- [x] Test full flow: Splash → Auth → Home → Tab switching
- [x] Verify Chat tab is default after login

## Success Criteria
- [x] App launches → splash → auth check → MainShellScreen with Chat tab active
- [x] All 4 tabs render and switch correctly
- [x] No compilation errors
- [x] Back button on home exits app (not nav back)
- [x] _PlaceholderScreen kept for other routes (lessons, settings, register, etc.)

## Completed Artifacts
- Route constants added: `/read`, `/vocabulary` in app-route-constants.dart
- MainShellBinding updated with lazy registration of all 4 tab controllers
- /home GetPage replaced with MainShellScreen + MainShellBinding
- _PlaceholderScreen retained for other routes (lessons, settings, register)
- Route imports cleaned up and organized
- Flutter analyze: 0 errors
- All 5 tests passing (ChatHomeScreen, ReadScreen, VocabularyScreen, ProfileScreen, MainShellScreen)
- End-to-end flow verified: Splash → Auth → MainShellScreen → Tab switching works

## Feature Summary
Complete bottom navigation bar feature with 4 tabs:
1. **Chat** (index 0, default) — ChatHomeScreen with conversation list
2. **Read** (index 1) — ReadScreen with reading lessons/sections
3. **Vocabulary** (index 2) — VocabularyScreen with word search and list
4. **Profile** (index 3) — ProfileScreen with user info and settings

Navigation uses IndexedStack for state preservation. All screens integrated via GetX routes with MainShellBinding. Translation keys added for EN and VI locales.
