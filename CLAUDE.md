# CLAUDE.md — Flowering Flutter App

## Project

AI-powered language learning Flutter app. GetX state management, Dio HTTP, Hive storage, offline-first.

## Commands

```bash
flutter run --dart-define=ENV=dev          # Dev build
flutter run --dart-define=ENV=prod --release  # Prod build
flutter test                               # All tests
flutter analyze                            # Static analysis
flutter pub run build_runner build --delete-conflicting-outputs  # Hive codegen
flutter clean && flutter pub get           # Clean rebuild
```

## Architecture

### Feature Structure

```
lib/features/{feature}/
├── bindings/      # GetX dependency injection
├── controllers/   # Business logic (extend BaseController)
├── views/         # Screens (extend BaseScreen)
└── widgets/       # Feature-specific components
```

### Dependency Flow

```
View → Controller → Service → Network/Storage
         ↑
      Binding (DI registration)
```

### Service Init Order (in `main.dart`)

AuthStorage → StorageService → ConnectivityService → AudioService → ApiClient

## Mandatory Constraints

### Base Class Inheritance

| Layer | MUST extend | NOT | Provides |
|---|---|---|---|
| Controllers | `BaseController` (`lib/core/base/`) | `GetxController` | `isLoading`, `errorMessage`, `apiCall()`, `showSuccess()` |
| Screens w/ controller | `BaseScreen<T>` | `StatelessWidget` | Loading overlay, SafeArea, Scaffold |
| Screens w/o controller | `BaseStatelessScreen` | `StatelessWidget` | SafeArea, Scaffold |

- Override `buildContent()` not `build()` for screen body
- Do NOT redeclare `isLoading` or `errorMessage` — use inherited ones
- Always call `super.onInit()` / `super.onClose()` when overriding lifecycle

**Exemptions:** shared widgets, tab children in IndexedStack (no nested Scaffold), StatefulWidgets needing State lifecycle (add comment why)

### Required Base Widgets

Always use these instead of raw Flutter widgets:

| Use | Instead of | Why |
|---|---|---|
| `AppText` | `Text` | Consistent Inter font typography |
| `AppButton` | `ElevatedButton`/`TextButton` | Consistent styling |
| `AppTextField` | `TextField` | Consistent styling |
| `LoadingWidget` | `CircularProgressIndicator` | Consistent branded loading (full-screen/section) |
| `PullToRefreshList` | `RefreshIndicator` | Gradual LoadingWidget reveal on pull-to-refresh |

If a shared widget doesn't exist, create it in `lib/shared/widgets/`.

**BaseScreen vs Shared Widgets:** `BaseScreen` = universal behaviors (Scaffold, SafeArea, LoadingOverlay). Feature-specific behaviors (pull-to-refresh, pagination) = opt-in shared widgets. Don't add to BaseScreen unless it applies to ALL screens.

### Translation

All user-facing text MUST use `.tr` — add keys to both:
- `lib/l10n/english-translations-en-us.dart`
- `lib/l10n/vietnamese-translations-vi-vn.dart`

```dart
AppText('key'.tr)                                    // Simple
AppText('welcome_user'.trParams({'name': userName}))  // Parameterized
```

### Reuse Constants

Colors, sizes, text styles, API endpoints → `lib/core/constants/`

## Key Patterns

### API Calls (via BaseController)

```dart
await apiCall(
  () => apiClient.get<UserModel>(ApiEndpoints.profile, fromJson: UserModel.fromJson),
  onSuccess: (data) => currentUser.value = data,
);
```

Server response: `{"code": 1, "message": "...", "data": {...}}` — `code: 1` = success, `0` = error.

### State Management

| Pattern | When | Example |
|---|---|---|
| `.obs` + `Obx()` | Simple values, frequent updates | `final name = ''.obs;` |
| `GetBuilder` + `update()` | Lists, complex objects, perf-critical | `List<Message> messages = [];` |

### Storage (Hive)

| Box | Max size | Eviction |
|---|---|---|
| `lessons_cache` | 100MB | LRU |
| `chat_cache` | 10MB | FIFO |
| `preferences` | 1MB | Manual |

Tokens: `AuthStorage` → keys: `access_token`, `refresh_token`, `user_id`. Auto-injected via `AuthInterceptor`.

### Environment

```dart
import 'package:flowering/config/env_config.dart';
final apiUrl = EnvConfig.apiBaseUrl;  // Loaded from .env.dev or .env.prod
```

## File Rules

- **One public class per file** — extract private widgets to separate files
- **Max 200 lines per file** — split into widgets/ or utility modules
- **snake_case.dart** file names; class name matches file: `AiAvatar` → `ai_avatar.dart`
- **Import order:** Flutter/Dart → external packages → internal (relative paths)
- Services registered in `global-dependency-injection-bindings.dart`

## Adding a New Feature (Checklist)

1. Create `lib/features/{name}/{bindings,controllers,views,widgets}/`
2. Controller extends `BaseController`, screen extends `BaseScreen<T>`
3. Add route in `app/routes/app-route-constants.dart`
4. Add page in `app/routes/app-page-definitions-with-transitions.dart`
5. Add translations to both l10n files
6. Register dependencies in binding file

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Review lessons at session start

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Run `flutter analyze` and `flutter test` before declaring done
- Ask yourself: "Would a staff engineer approve this?"

### 5. Autonomous Bug Fixing
- When given a bug report: just fix it — don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Go fix failing CI tests without being told how

### 6. Task Management
1. Write plan to `tasks/todo.md` with checkable items
2. Check in with user before starting implementation
3. Mark items complete as you go
4. Update `tasks/lessons.md` after corrections

### Core Principles
- **Simplicity First**: Make every change as simple as possible. Minimal code impact.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

## Documentation

Detailed docs in `docs/`: `system-architecture.md`, `code-standards.md`, `codebase-summary.md`, `development-roadmap.md`, `project-overview-pdr.md`
