# Flowering Flutter App - Documentation Index

Welcome to the Flowering Flutter documentation. This directory contains comprehensive documentation for the AI-powered language learning app.

**Last Updated:** April 20, 2026
**Current Phase:** 6.12 (Critical Fixes) Complete; Phase 7 (Home Language Switcher) In Progress (50%)
**Status:** All infrastructure, user acquisition, session persistence, and critical fixes complete; home language UI in progress

## Quick Navigation

### For New Developers
Start here to get up to speed:
1. **[codebase-quick-start.md](./codebase-quick-start.md)** - 5-minute overview with essential info
2. **[code-standards.md](./code-standards.md)** - Code conventions and patterns
3. **[CLAUDE.md](../CLAUDE.md)** - Architecture principles and workflows

### For Project Management
Track progress and understand scope:
1. **[development-roadmap.md](./development-roadmap.md)** - Timeline, phases, and milestones
2. **[project-changelog.md](./project-changelog.md)** - Detailed history of changes
3. **[project-overview-pdr.md](./project-overview-pdr.md)** - Product requirements and acceptance criteria

### For Architecture & Design
Deep dive into system design:
1. **[system-architecture.md](./system-architecture.md)** - Complete architecture documentation
2. **[codebase-summary.md](./codebase-summary.md)** - Implementation status and details

## Documentation Files

| File | Purpose | Lines | Status |
|------|---------|-------|--------|
| [project-overview-pdr.md](./project-overview-pdr.md) | Product vision, requirements, constraints, success metrics | 186 | ✅ Current |
| [codebase-summary.md](./codebase-summary.md) | Codebase structure, tech stack, implementation status | 672 | ✅ Current |
| [code-standards.md](./code-standards.md) | Code conventions, patterns, best practices | 940 | ✅ Current |
| [system-architecture.md](./system-architecture.md) | Complete architecture, layers, patterns, integrations | 832 | ✅ Current |
| [development-roadmap.md](./development-roadmap.md) | Phases, timeline, effort, deliverables, milestones | 1,119 | ✅ Current |
| [project-changelog.md](./project-changelog.md) | Detailed change history, version tracking | 877 | ✅ Current |
| [codebase-quick-start.md](./codebase-quick-start.md) | Quick reference for developers (NEW) | 185 | ✅ New |

**Total Documentation:** 4,811 lines of comprehensive documentation

## Key Project Information

### Technology Stack
- **Framework:** Flutter 3.10.3+ with Dart 3.10.3+
- **State Management:** GetX 4.6.6 (dependency injection, routing, reactive state)
- **Networking:** Dio 5.4.0 (HTTP client with interceptors)
- **Storage:** Hive 2.2.3 (local cache with eviction), AuthStorage (token management)
- **Audio:** flutter_tts 4.2.5 (TTS), speech_to_text 7.3.0 (STT), record 6.2.0 (iOS recording)
- **UI:** Flutter Material3, google_fonts (Inter typography), lucide_icons

### Architecture Pattern
Feature-first clean architecture with 4 layers:
1. **Presentation** - Views (screens) and Controllers (business logic)
2. **Domain** - Models and business entities
3. **Data** - Services (API client, storage, connectivity, audio)
4. **Infrastructure** - Network interceptors, Hive adapters, platform services

### Design System
- **Primary Color:** Warm Orange (#FF7A27)
- **Background:** Cream White (#FFFDF7)
- **Text Primary:** Charcoal (#292F36)
- **Typography:** Inter font family with consistent styles
- **Accent Colors:** Blue, Green, Lavender, Rose groups

## Current Implementation Status

### Complete (Phase 1-6.12)
- Project setup and dependencies
- Network layer (ApiClient, interceptors, error handling, retry logic)
- Core services (Storage, Auth, Connectivity, Audio, Language Context, Cache Invalidation)
- Base classes (BaseController, BaseScreen, BaseStatelessScreen)
- Routing (16 routes with transitions)
- Localization (99+ keys per language: EN, VI)
- **Onboarding flow:** 8 screens with session rehydration and checkpoint persistence
- **Authentication:** 5 screens (login, signup, forgot password, OTP, new password) with Firebase error mapping
- **Navigation:** 4-tab bottom navigation (Chat, Read, Vocabulary, Profile)
- **Chat feature:** Grammar correction, translation support, message bubbles, TTS/STT, session rehydration
- **Multi-language support:** Active language context, cache scoping, language switching without data loss
- **Critical fixes:** Token refresh race conditions, API contract alignment (camelCase→snake_case), error disclosure mitigation

### In Progress & Pending (Phase 7-10)
- **Phase 7 (50% complete):** Home dashboard UI with language switcher button and language picker sheet
- Expanded chat with full history and persistence
- Lessons browser with offline caching
- Profile and settings pages
- Comprehensive test coverage (target >70%)

## Critical Architecture Rules

### Mandatory Base Class Inheritance
All controllers MUST extend `BaseController` (never `GetxController`):
```dart
class AuthController extends BaseController {
  // Provides: isLoading, errorMessage, apiCall(), showSuccess()
}
```

All screens with controllers MUST extend `BaseScreen<T>`:
```dart
class LoginScreen extends BaseScreen<AuthController> {
  @override
  Widget buildContent(BuildContext context) {
    // Override buildContent, not build()
  }
}
```

### Storage Architecture
- **Tokens:** AuthStorage (Hive 'auth' box) - separate from cache
- **Cache:** StorageService with eviction:
  - Lessons: 100MB LRU eviction
  - Chat: 10MB FIFO eviction
  - Preferences: 1MB manual eviction

### API Pattern
All requests through centralized ApiClient with automatic:
- JWT token injection (AuthInterceptor)
- Automatic token refresh on 401
- Retry with exponential backoff (up to 3 times)
- Exception mapping (8 typed exception classes)

Server responses wrapped in ApiResponse<T>:
```json
{
  "code": 1,
  "message": "Success",
  "data": { /* typed object */ }
}
```

## Quick Commands

### Development
```bash
# Run with dev environment
flutter run --dart-define=ENV=dev

# Generate code (Hive adapters)
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Project Structure
```
lib/
├── main.dart                  # App entry point
├── app/                       # Configuration, routing, DI
├── core/                      # Network, services, constants, base classes
├── shared/                    # Reusable widgets and models
├── features/                  # 7 feature modules
├── l10n/                      # Localization (99+ keys)
└── config/                    # Environment configuration
```

## Common Workflows

### Add New Endpoint
1. Add constant to `core/constants/api_endpoints.dart`
2. Create/update model in `shared/models/`
3. Call via `apiClient` with type safety and error handling

### Add Translation
1. Add keys to both language files:
   - `l10n/english-translations-en-us.dart`
   - `l10n/vietnamese-translations-vi-vn.dart`
2. Use in code: `'key'.tr`

### Create New Feature
1. Create `lib/features/feature_name/` with structure
2. Implement binding (DI), controller, screen, widgets
3. Register in routing configuration
4. Add translation keys as needed

## Design System Reference

### Colors
| Color | Usage | Hex |
|-------|-------|-----|
| Warm Orange | Primary action, active states | #FF7A27 |
| Cream White | Background, surfaces | #FFFDF7 |
| Charcoal | Primary text | #292F36 |
| Sage Green | Secondary text, accents | #699A6B |
| Mint Green | Success indicator | #CAFFBF |
| Peach | Warning indicator | #FFD6A5 |
| Red | Error indicator | #FF4444 |
| Sky Blue | Info indicator | #A0C4FF |

### Typography
| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| h1 | 32px | Bold | Screen titles |
| h2 | 24px | Bold | Section headers |
| h3 | 20px | SemiBold | Subsection headers |
| bodyLarge | 16px | Regular | Body text |
| bodyMedium | 14px | Regular | Secondary text |
| button | 15px | SemiBold | Button labels |

## Known Limitations & Debt

1. **Test Coverage:** Currently 0% feature tests (7 infrastructure tests exist)
   - Target: >70% coverage for Phase 7+

2. **Feature Placeholders:** Chat, Read, Vocabulary, Profile are shells
   - Ready for Phase 7+ implementation

3. **Permission UX:** Basic microphone permission check exists
   - Full flow deferred to Phase 8 (chat expansion)

4. **Cache Eviction:** Simple LRU/FIFO implementation
   - Can be enhanced with more sophisticated algorithms

## Troubleshooting

### "Get.find() not found"
- Ensure service registered in `global-dependency-injection-bindings.dart`
- Service must be initialized before use

### Build errors after model changes
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Hot reload not working
Hot restart required after:
- pubspec.yaml changes
- main.dart changes
- .env file changes

## Contact & Support

For documentation issues or questions:
1. Check the specific documentation file relevant to your question
2. Review [code-standards.md](./code-standards.md) for patterns
3. Reference [system-architecture.md](./system-architecture.md) for design decisions
4. See [codebase-quick-start.md](./codebase-quick-start.md) for quick answers

## Documentation Updates

This documentation is actively maintained alongside development:
- Update roadmap when phases begin/complete
- Update changelog with significant changes
- Verify consistency before major releases
- Add new sections as architecture evolves

---

**Last Reviewed:** 2026-04-15
**Next Review:** When Phase 7 begins
**Maintainer:** Development Team
**Status:** All documentation current and consistent
