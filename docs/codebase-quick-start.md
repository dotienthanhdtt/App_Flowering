# Codebase Quick Start Guide

## Project Info
- **Name:** Flowering - AI Language Learning App
- **Framework:** Flutter 3.10.3+ with GetX 4.6.6
- **Status:** Phase 6 complete (March 11, 2026)
- **Architecture:** Feature-first clean architecture
- **Localization:** English & Vietnamese (99+ keys per language)

## Key Stats
- **Implemented:** 106 Dart files across 7 feature modules
- **Routes:** 16 named routes with transitions
- **Screens:** 14 screens (8 onboarding, 5 auth, 1 shell)
- **Services:** 5 core services (API, Storage, Auth, Connectivity, Audio)
- **Tests:** 7 infrastructure tests (0% feature coverage)
- **Design:** Warm neutral palette with Warm Orange (#FF7A27) primary

## Core Features Completed
1. **Authentication** - Login, signup, forgot password, OTP, password reset
2. **Onboarding** - Splash, welcome, language selection, AI chat intro, scenario gift
3. **Navigation** - Bottom nav with 4 tabs (Chat, Read, Vocabulary, Profile)
4. **Chat** - Grammar correction, message bubbles, translation support
5. **Localization** - Full EN/VI support with 99+ translation keys

## Quick Commands
```bash
# Development
flutter run --dart-define=ENV=dev

# Code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Testing
flutter test

# Linting
flutter analyze
```

## Directory Structure Highlights
```
lib/
├── app/                 # App config, routing, DI
├── core/                # Network, services, constants, base classes
├── shared/              # Reusable widgets and models
├── features/            # 7 feature modules (auth, onboarding, chat, etc.)
└── l10n/                # 99+ translation keys (EN & VI)
```

## Critical Architecture Rules

### Base Class Enforcement (MANDATORY)
- **Controllers:** ALL extend `BaseController` (never `GetxController` directly)
- **Screens:** All screens with controllers extend `BaseScreen<T>`
- **Exemptions:** Tab children (IndexedStack), StatefulWidget screens

### API Pattern
```dart
// All requests go through ApiClient singleton
final response = await apiClient.get<UserModel>(
  ApiEndpoints.endpoint,
  fromJson: (data) => UserModel.fromJson(data),
);

if (response.isSuccess) {
  // Handle success
} else {
  // Handle error via exception types
}
```

### State Management
- **Simple values:** Use `.obs` (bool, String, int)
- **Complex objects:** Use `GetBuilder`
- **Disposal:** Always implement `onClose()` with proper cleanup

### Token Storage
- **Uses:** AuthStorage (Hive-based 'auth' box)
- **Pattern:** Separate from cache storage (lessons/chat boxes)
- **Access:** Via `AuthInterceptor` automatic header injection

## Common Workflows

### Add New Feature
1. Create `lib/features/feature_name/` with structure
2. Add binding, controller, screen
3. Register route in `app-route-constants.dart`
4. Define page in `app-page-definitions-with-transitions.dart`

### Add New Endpoint
1. Add constant to `core/constants/api_endpoints.dart`
2. Create/update model in `shared/models/`
3. Call via `apiClient` with proper error handling
4. Add any new translation keys

### Add Localization
1. Add keys to both language files:
   - `l10n/english-translations-en-us.dart`
   - `l10n/vietnamese-translations-vi-vn.dart`
2. Use in code: `'key'.tr`

## Key Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| get | 4.6.6 | State management, DI, routing |
| dio | 5.4.0 | HTTP networking |
| hive | 2.2.3 | Local storage with eviction |
| record | 6.2.0 | Audio recording |
| audioplayers | 5.2.1 | Audio playback |
| flutter_dotenv | 5.1.0 | Environment config |
| google_fonts | 6.1.0 | Typography (Inter font) |

## Design System
| Token | Value |
|-------|-------|
| Primary | #FF7A27 (Warm Orange) |
| Background | #FFFDF7 (Cream White) |
| Text Primary | #292F36 (Charcoal) |
| Success | #CAFFBF (Mint) |
| Error | #FF4444 (Red) |
| Font | Inter 12-32px |
| Min Touch Target | 44x44 |

## Common Issues

### "Get.find() not found"
- Ensure service is registered in `global-dependency-injection-bindings.dart`
- Services must be initialized in `main.dart` before use

### Build errors after model changes
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Hot reload not working
- Full restart required after pubspec.yaml, main.dart, or .env changes

## Next Implementation Phases
- **Phase 7:** Home dashboard with learning stats
- **Phase 8:** Full chat interface with history
- **Phase 9:** Lessons browser with offline caching
- **Phase 10:** Profile and settings pages

## Documentation Files
- `project-overview-pdr.md` - Product requirements
- `system-architecture.md` - Architecture details
- `code-standards.md` - Coding conventions
- `development-roadmap.md` - Timeline and milestones
- `project-changelog.md` - Detailed change history
- `codebase-summary.md` - Implementation status

---
Last updated: 2026-03-11
