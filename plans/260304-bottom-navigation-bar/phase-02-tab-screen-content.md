# Phase 2: Tab Screen Content

## Context
- [Plan Overview](plan.md)
- [Phase 1](phase-01-dependencies-and-navigation-shell.md)

## Overview
- **Priority**: P1
- **Status**: completed
- **Description**: Create content screens for all 4 tabs with real UI matching design patterns. Each screen gets its own controller and binding. All screens implemented with controllers and translation keys.

## Key Insights
- Existing `chat/` feature has onboarding chat — chat home screen goes alongside it
- Existing `lessons/` dir is empty — repurpose for Read tab
- Existing `profile/` dir is empty — repurpose for Profile tab
- Need new `vocabulary/` feature directory
- All screens follow BaseController pattern
- Translation keys already exist for many labels (chat, lessons, profile, settings)

## Related Code Files

### Files to Create

#### Chat Home (Tab 0)
- `lib/features/chat/controllers/chat-home-controller.dart`
- `lib/features/chat/views/chat-home-screen.dart`
- `lib/features/chat/widgets/chat-conversation-tile.dart`

#### Read (Tab 1)
- `lib/features/lessons/controllers/read-controller.dart`
- `lib/features/lessons/views/read-screen.dart`
- `lib/features/lessons/bindings/read-binding.dart`

#### Vocabulary (Tab 2)
- `lib/features/vocabulary/` — new feature dir
- `lib/features/vocabulary/controllers/vocabulary-controller.dart`
- `lib/features/vocabulary/views/vocabulary-screen.dart`
- `lib/features/vocabulary/bindings/vocabulary-binding.dart`

#### Profile (Tab 3)
- `lib/features/profile/controllers/profile-controller.dart`
- `lib/features/profile/views/profile-screen.dart`
- `lib/features/profile/bindings/profile-binding.dart`

### Files to Modify
- `lib/l10n/english-translations-en-us.dart` — Add nav + tab screen keys
- `lib/l10n/vietnamese-translations-vi-vn.dart` — Add nav + tab screen keys

## Implementation Steps

### 1. Add Translation Keys

Add to both EN/VI translation files:
```dart
// Bottom Navigation
'nav_chat': 'Chat',          // 'Trò chuyện'
'nav_read': 'Read',          // 'Đọc'
'nav_vocabulary': 'Vocabulary', // 'Từ vựng'
'nav_profile': 'Profile',    // 'Hồ sơ'

// Chat Home
'chat_home_title': 'Conversations',    // 'Cuộc trò chuyện'
'chat_home_empty': 'No conversations yet', // 'Chưa có cuộc trò chuyện nào'
'chat_home_start': 'Start a new chat',   // 'Bắt đầu trò chuyện mới'

// Read
'read_title': 'Reading',              // 'Bài đọc'
'read_trial_lessons': 'Trial Lessons', // 'Bài học thử'
'read_empty': 'No lessons available',  // 'Chưa có bài học'

// Vocabulary
'vocabulary_title': 'Vocabulary',      // 'Từ vựng'
'vocabulary_search': 'Search words...', // 'Tìm từ...'
'vocabulary_empty': 'No words learned yet', // 'Chưa học từ nào'
'vocabulary_review': 'Review',         // 'Ôn tập'
```

### 2. Create Chat Home Screen (Tab 0)

**ChatHomeController** (`chat/controllers/chat-home-controller.dart`):
- Extends BaseController
- `conversations` reactive list (empty initially — will connect to API later)
- `startNewChat()` method → placeholder for now

**ChatHomeScreen** (`chat/views/chat-home-screen.dart`):
- SafeArea with Column layout
- Header: greeting text + "New Chat" button
- Body: ListView of conversation tiles (or empty state)
- Uses AppColors.background as bg

**ChatConversationTile** (`chat/widgets/chat-conversation-tile.dart`):
- Row: avatar + Column(title, subtitle) + timestamp
- Styled with AppColors, AppTextStyles
- onTap → will push to chat detail later

### 3. Create Read Screen (Tab 1)

**ReadController** (`lessons/controllers/read-controller.dart`):
- Extends BaseController
- `sections` reactive list (mock data for now)

**ReadScreen** (`lessons/views/read-screen.dart`):
- SafeArea with CustomScrollView
- Header: "Reading" title + search icon
- Section titles + card grid layout (matching screen 13 Pencil design)
- Cards with rounded corners, images, progress indicators
- Empty state when no content

### 4. Create Vocabulary Screen (Tab 2)

```bash
mkdir -p lib/features/vocabulary/{controllers,views,widgets,bindings}
```

**VocabularyController** (`vocabulary/controllers/vocabulary-controller.dart`):
- Extends BaseController
- `words` reactive list
- `searchQuery` reactive string
- `filteredWords` computed list

**VocabularyScreen** (`vocabulary/views/vocabulary-screen.dart`):
- SafeArea with Column
- Search bar (using existing Input/Search design pattern)
- Word list or empty state
- Each word: term + translation + category badge

### 5. Create Profile Screen (Tab 3)

**ProfileController** (`profile/controllers/profile-controller.dart`):
- Extends BaseController
- `user` reactive (null initially)
- `logout()` method

**ProfileScreen** (`profile/views/profile-screen.dart`):
- SafeArea with SingleChildScrollView
- User header: avatar + name + email
- Stats row: streak, words learned, study time, accuracy
- Settings section: language, notifications, about
- Logout button at bottom

## Todo List
- [x] Add translation keys (EN + VI)
- [x] Create ChatHomeController
- [x] Create ChatHomeScreen with conversation list / empty state
- [x] Create ChatConversationTile widget
- [x] Create ReadController
- [x] Create ReadScreen with section cards
- [x] Create vocabulary feature directory
- [x] Create VocabularyController
- [x] Create VocabularyScreen with search + word list
- [x] Create ProfileController
- [x] Create ProfileScreen with user info + settings
- [x] Verify compilation with `flutter analyze`

## Success Criteria
- [x] All 4 tab screens render without errors
- [x] Each screen has appropriate empty state
- [x] Translation keys work in both EN/VI
- [x] Screens follow existing design patterns (AppColors, AppTextStyles, AppSizes)
- [x] Each file under 200 lines

## Completed Artifacts
- Translation keys added to english-translations-en-us.dart and vietnamese-translations-vi-vn.dart
- ChatHomeController created with conversations list
- ChatHomeScreen created with header and conversation list UI
- ChatConversationTile widget created for conversation items
- ReadController created with sections reactive list
- ReadScreen created with section cards layout
- Vocabulary feature directory created (controllers, views, bindings, widgets)
- VocabularyController created with words list and search filtering
- VocabularyScreen created with search bar and word list
- ProfileController created with user data and logout method
- ProfileScreen created with user info, stats, settings sections
- All files under 200 lines
- Flutter analyze: 0 errors

## Next Steps
- Phase 3: Wire everything in routes, remove placeholders, polish (COMPLETE)
