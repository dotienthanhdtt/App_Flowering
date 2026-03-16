# Phase 1: Dependencies & Navigation Shell

## Context
- [Brainstorm Report](reports/brainstorm-report.md)
- [Plan Overview](plan.md)

## Overview
- **Priority**: P1
- **Status**: completed
- **Description**: Add lucide_icons package, create MainShellScreen with custom BottomNavBar, MainShellController, and MainShellBinding. All files created and tested.

## Key Insights
- AppColors already has `primary` (#FF7A27) and `textTertiary` (#9C9585) matching design
- AppColors.borderLight = #F0ECDA matches nav border
- Existing `home/` feature dir is empty — repurpose for main shell
- AppSizes has `radiusXL` = 20 for top corners
- GoogleFonts.outfit already used in AppTextStyles

## Requirements

### Functional
- Bottom nav with 4 tabs: Chat, Read, Vocabulary, Profile
- Chat tab selected by default on app launch
- Active tab: orange icon + text, bold weight
- Inactive tab: muted gray icon + text, medium weight
- Tapping tab switches page instantly (IndexedStack)

### Non-Functional
- Smooth color transition animation on tap
- Match Pencil design pixel-perfectly
- Under 200 lines per file

## Related Code Files

### Files to Create
- `lib/features/home/controllers/main-shell-controller.dart` — Tab index state
- `lib/features/home/views/main-shell-screen.dart` — Scaffold + IndexedStack + BottomNavBar
- `lib/features/home/widgets/bottom-nav-bar.dart` — Custom nav bar widget
- `lib/features/home/bindings/main-shell-binding.dart` — DI for shell + all tab controllers

### Files to Modify
- `pubspec.yaml` — Add lucide_icons dependency
- `lib/core/constants/app_sizes.dart` — Add navBarHeight constant

## Implementation Steps

### 1. Add lucide_icons package
```bash
cd app_flowering/flowering && flutter pub add lucide_icons
```

### 2. Add nav bar size constant to AppSizes
```dart
// In app_sizes.dart — Component Sizes section
static const double navBarHeight = 80;
static const double navIconSize = 22;
static const double navFontSize = 10;
static const double navItemWidth = 64;
static const double navItemGap = 4;
```

### 3. Create MainShellController
File: `lib/features/home/controllers/main-shell-controller.dart`

```dart
class MainShellController extends GetxController {
  final selectedIndex = 0.obs; // Chat = default

  void changePage(int index) {
    selectedIndex.value = index;
  }
}
```

### 4. Create BottomNavBar widget
File: `lib/features/home/widgets/bottom-nav-bar.dart`

Custom Container-based widget matching Pencil spec:
- 4 nav items: Chat (MessageCircle), Read (BookOpen), Vocabulary (Languages), Profile (User)
- Uses AppColors.primary for active, AppColors.textTertiary for inactive
- Container with BoxDecoration: white bg, BorderRadius.only(topLeft/topRight: 20), BoxShadow
- Top border via Border(top: BorderSide(color: AppColors.borderLight))
- Row with mainAxisAlignment: spaceAround
- Each item: Column(icon + SizedBox(4) + text)
- GestureDetector/InkWell on each item → controller.changePage(index)
- AnimatedDefaultTextStyle + AnimatedTheme for smooth transitions

### 5. Create MainShellScreen
File: `lib/features/home/views/main-shell-screen.dart`

```dart
class MainShellScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainShellController>();
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.selectedIndex.value,
        children: [
          ChatHomeScreen(),   // index 0
          ReadScreen(),       // index 1
          VocabularyScreen(), // index 2
          ProfileScreen(),    // index 3
        ],
      )),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
```

### 6. Create MainShellBinding
File: `lib/features/home/bindings/main-shell-binding.dart`

```dart
class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<MainShellController>(MainShellController(), permanent: true);
    // Tab controllers registered lazily — each screen handles its own
  }
}
```

## Todo List
- [x] Add lucide_icons to pubspec.yaml
- [x] Add nav constants to AppSizes
- [x] Create MainShellController
- [x] Create BottomNavBar widget matching Pencil design
- [x] Create MainShellScreen with IndexedStack
- [x] Create MainShellBinding
- [x] Verify compilation with `flutter analyze`

## Success Criteria
- [x] Bottom nav renders with 4 tabs
- [x] Chat tab selected by default (orange)
- [x] Tapping tabs switches IndexedStack index
- [x] Visual matches Pencil design (colors, sizes, shadow, corners)

## Completed Artifacts
- lucide_icons added to pubspec.yaml
- AppSizes updated with navBarHeight (80), navIconSize (22), navFontSize (10), navItemWidth (64), navItemGap (4)
- MainShellController created with selectedIndex observable
- BottomNavBar widget created with 4 custom nav items (Chat, Read, Vocabulary, Profile)
- MainShellScreen created with IndexedStack page switching
- MainShellBinding created with permanent MainShellController registration
- Flutter analyze: 0 errors

## Next Steps
- Phase 2: Create actual tab screen content (COMPLETE)
- Phase 3: Wire routes (COMPLETE)
