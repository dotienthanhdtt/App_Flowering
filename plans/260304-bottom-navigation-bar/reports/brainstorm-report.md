# Brainstorm: Bottom Navigation Bar

## Problem Statement

The Flowering Flutter app currently has no bottom navigation after login. The `/home` route shows a placeholder. Need to implement a 4-tab bottom navigation bar matching the Pencil design, with Chat as the default tab, plus content for each tab screen.

## Design Spec (from Pencil MCP Component Frame)

### 4-Tab Navbar

| # | Tab | Lucide Icon | Active | Inactive |
|---|-----|-------------|--------|----------|
| 1 | Chat | `message-circle` | `#FF7A27`, w600 | `#9C9585`, w500 |
| 2 | Read | `book-open` | `#FF7A27`, w600 | `#9C9585`, w500 |
| 3 | Vocabulary | `languages` | `#FF7A27`, w600 | `#9C9585`, w500 |
| 4 | Profile | `user` | `#FF7A27`, w600 | `#9C9585`, w500 |

### Navbar Styling
- Background: `#FFFFFF`, corner radius `[20, 20, 0, 0]`
- Shadow: blur 12, `#19191908`, y-offset -2
- Border: inside, `#F0ECDA`, thickness 1
- Height: 80px, padding `[8, 16, 24, 16]`
- Layout: `space_around`
- Font: Outfit 10px, icons 22x22, gap 4px, item width 64px

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Page switching | IndexedStack | Preserves state, instant tab switching |
| Sub-page nav | Full-screen push | Simpler, no nested navigators |
| Chat screen | New screen | Separate from onboarding chat |
| Default tab | Chat (index 0) | User requirement |

## Recommended Architecture

### File Structure

```
lib/features/
├── main-shell/
│   ├── bindings/main-shell-binding.dart
│   ├── controllers/main-shell-controller.dart
│   ├── views/main-shell-screen.dart
│   └── widgets/
│       └── bottom-nav-bar.dart
├── chat-home/
│   ├── bindings/chat-home-binding.dart
│   ├── controllers/chat-home-controller.dart
│   ├── views/chat-home-screen.dart
│   └── widgets/
│       ├── chat-conversation-tile.dart
│       └── new-chat-fab.dart
├── read/
│   ├── bindings/read-binding.dart
│   ├── controllers/read-controller.dart
│   ├── views/read-screen.dart
│   └── widgets/
├── vocabulary/
│   ├── bindings/vocabulary-binding.dart
│   ├── controllers/vocabulary-controller.dart
│   ├── views/vocabulary-screen.dart
│   └── widgets/
├── profile/
│   ├── bindings/profile-binding.dart
│   ├── controllers/profile-controller.dart
│   ├── views/profile-screen.dart
│   └── widgets/
```

### Key Components

#### 1. MainShellController
- `selectedIndex` = `0.obs` (Chat default)
- `changePage(int index)` method
- No nested navigation — sub-pages push full-screen via `Get.toNamed()`

#### 2. MainShellScreen
```
Scaffold(
  body: IndexedStack(
    index: controller.selectedIndex.value,
    children: [
      ChatHomeScreen(),
      ReadScreen(),
      VocabularyScreen(),
      ProfileScreen(),
    ],
  ),
  bottomNavigationBar: BottomNavBar(),
)
```

#### 3. Custom BottomNavBar Widget
- Custom widget (NOT Flutter's built-in BottomNavigationBar) to match Pencil design exactly
- Uses `lucide_icons` package for icon matching
- Animated color transitions on tap

### Tab Screen Content

#### Chat Tab (index 0, default)
- Header with greeting + scenario count badge
- List of chat conversations (scenario-based)
- FAB for starting new conversation
- Each tile: scenario name, last message, timestamp, avatar
- Tap → pushes full-screen chat screen (new, not onboarding chat)

#### Read Tab (index 1)
- Section-based reading content
- Cards with scenario lessons (matching screen 13 design)
- Trial lessons + categorized content
- Progress indicators on cards
- Tap → pushes lesson detail screen

#### Vocabulary Tab (index 2)
- Search bar at top
- Word list with translations
- Filter by category/topic
- Tap → word detail with examples, audio
- Review/practice button

#### Profile Tab (index 3)
- Avatar + user info header
- Stats cards (streak, XP, words learned, etc.)
- Settings link
- Subscription status
- Logout button

### Route Changes

```dart
// Replace placeholder /home with MainShellScreen
GetPage(
  name: AppRoutes.home,
  page: () => const MainShellScreen(),
  binding: MainShellBinding(),  // loads all tab bindings
)
```

### MainShellBinding
Registers all tab controllers lazily — only the Chat controller initializes eagerly since it's the default tab.

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Memory with IndexedStack (4 pages) | Lazy-load heavy content within each tab |
| lucide_icons package availability | Verify package exists; fallback to Cupertino/Material icons |
| Chat tab vs onboarding chat confusion | Separate feature folders, clear naming |
| Navigation state loss on full-screen push | Controller state persists via GetX permanent registration |

## Dependencies
- `lucide_icons` Flutter package (for icon matching)
- Existing: `get`, `dio`, `hive`

## Success Criteria
- [ ] Bottom nav bar matches Pencil design pixel-perfectly
- [ ] Chat tab is default on app launch
- [ ] All 4 tabs render with content
- [ ] Tab switching preserves state (scroll position, input)
- [ ] Sub-pages push full-screen correctly
- [ ] Active/inactive states animate smoothly
- [ ] Works on both iOS and Android
