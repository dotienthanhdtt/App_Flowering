# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flowering is an AI-powered language learning Flutter application using GetX for state management, featuring offline-first capabilities, voice input/output, and a feature-first clean architecture.

## Essential Commands

### Development

```bash
# Run app (development environment)
flutter run --dart-define=ENV=dev

# Run app (production environment)
flutter run --dart-define=ENV=prod --release

# Hot reload during development
# Press 'r' in terminal while app is running

# Hot restart
# Press 'R' in terminal while app is running
```

### Building

```bash
# Generate Hive adapters (after model changes)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous code generation
flutter pub run build_runner watch --delete-conflicting-outputs

# Clean build
flutter clean && flutter pub get
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test_file.dart

# Run tests with coverage
flutter test --coverage

# Run widget tests specifically
flutter test test/app/
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/ test/

# Get dependencies
flutter pub get
```

## Architecture Principles

### Feature-First Structure

Each feature module follows this exact pattern:

```
features/{feature}/
├── bindings/        # Dependency injection
├── controllers/     # Business logic (GetX controllers)
├── views/           # UI screens (StatelessWidget)
└── widgets/         # Feature-specific components
```

### Dependency Flow

```
View → Controller → Service → Network/Storage
  ↑         ↓
  └── Binding ──┘
```

**Key Rules:**
- Views NEVER call services directly - always through controllers
- Controllers use `Get.find<Service>()` to access services
- Services are singletons registered in `global-dependency-injection-bindings.dart`
- All async initialization happens in service `init()` methods
- Add // TODO if task need I to complete
- Re use ui component in lib/shared/widgets, using those component to build layout. In a view screen if any layout duplicate many time please create component for this layout
- All user-facing text in `AppText` must use `.tr` for translation (e.g., `AppText('key'.tr)`) — add keys to `lib/l10n/english-translations-en-us.dart` and `lib/l10n/vietnamese-translations-vi-vn.dart`
- Color, size, text style, api_endpoint re use in lib/core/constants
- Always use base widgets from `lib/shared/widgets/` instead of raw Flutter widgets:
  - `AppText` instead of `Text` (ensures consistent Inter font typography)
  - `AppButton` instead of `ElevatedButton`/`TextButton`
  - `AppTextField` instead of `TextField`
- If widget not exit then create one and add to `lib/shared/widgets`

### Base Class Inheritance (Mandatory)

All feature controllers and screens MUST inherit from the base classes in `lib/core/base/`:

**Controllers:**
- All controllers in `features/*/controllers/` MUST extend `BaseController` (not `GetxController` directly)
- `BaseController` provides: `isLoading`, `errorMessage`, `apiCall()`, `showSuccess()`, `clearError()`
- Do NOT redeclare `isLoading` or `errorMessage` -- use inherited ones from `BaseController`
- Always call `super.onInit()` / `super.onClose()` when overriding lifecycle

**Screens (views):**
- Screens with a controller: extend `BaseScreen<ControllerType>` -- gets automatic loading overlay, SafeArea, Scaffold
  - Override `buildContent()` instead of `build()` for screen body
  - Override `buildAppBar()`, `buildFab()`, `buildBottomNav()` as needed
  - Override `backgroundColor`, `useSafeArea`, `showLoadingOverlay` getters to customize
- Screens without a controller: extend `BaseStatelessScreen` -- same pattern minus loading overlay
- StatefulWidget screens (rare): exempt from base class, document why in a comment

**Exemptions:**
- Shared widgets (`shared/widgets/`, `features/*/widgets/`) -- these are composable components, NOT screens
- Tab child screens embedded in IndexedStack -- these should NOT use BaseScreen (would create nested Scaffolds); use plain StatelessWidget with just content, no Scaffold
- StatefulWidget screens that need `State` lifecycle (e.g., animation controllers, PageController) -- exempt but add comment explaining why

### State Management Pattern

**Use `.obs` reactive variables for:**
- Simple values (bool, String, int)
- Single widget updates
- Frequently changing state

```dart
final isLoading = false.obs;
final userName = ''.obs;

// In view
Obx(() => Text(controller.userName.value))
```

**Use `GetBuilder` for:**
- Complex objects and lists
- Multiple widget updates
- Performance-critical sections

```dart
List<Message> messages = [];

// In view
GetBuilder<ChatController>(
  builder: (controller) => ListView.builder(...)
)
```

### Service Initialization Order

Services must be initialized in dependency order in `main.dart`:

```
1. AuthStorage (tokens)
2. StorageService (cache)
3. ConnectivityService (network monitoring)
4. AudioService (voice I/O)
5. ApiClient (depends on AuthStorage)
```

## Critical Architectural Components

### API Client Pattern

All network requests go through the centralized `ApiClient`:

```dart
// GET with type-safe response
final response = await apiClient.get<UserModel>(
  ApiEndpoints.profile,
  fromJson: (data) => UserModel.fromJson(data),
);

// Handle response
if (response.isSuccess && response.data != null) {
  currentUser.value = response.data!;
} else {
  showError(response.message);
}
```

**Server response format:**
```json
{
  "code": 1,          // 1 = success, 0 = error
  "message": "...",
  "data": {...}
}
```

### Exception Handling Hierarchy

The codebase uses typed exceptions for granular error handling:

```dart
try {
  await apiClient.post(...);
} on NetworkException catch (e) {
  // No internet connection
} on TimeoutException catch (e) {
  // Request timeout
} on UnauthorizedException catch (e) {
  // Session expired (auto-handled by AuthInterceptor)
} on ValidationException catch (e) {
  // Field validation errors - use e.errors map
} on ServerException catch (e) {
  // 5xx server errors
} on ApiException catch (e) {
  // Generic API error with userMessage
}
```

### Storage Strategy

**Hive boxes with intelligent eviction:**
- `lessons_cache`: 100MB max, LRU eviction
- `chat_cache`: 10MB max, FIFO eviction
- `preferences`: 1MB max, manual eviction

**Token storage:**
- Uses `AuthStorage` (Hive-based)
- Keys: `access_token`, `refresh_token`, `user_id`
- Auto-injection via `AuthInterceptor`

### BaseController Pattern

> **Rule:** Never extend `GetxController` directly in feature controllers. Always use `BaseController`.

All controllers should extend `BaseController` for consistent error handling:

```dart
class AuthController extends BaseController {
  Future<void> login() async {
    await apiCall(
      () => _apiClient.post(...),
      onSuccess: (result) {
        // Handle success
      },
      onError: (error) {
        // Custom error handling
      },
    );
  }
}
```

## File Organization Rules

### One Class Per File (Strict)
Each `.dart` file must contain **exactly one public class**. Never put multiple widgets, controllers, or models in the same file.
- Extract every widget (even small/private ones) into its own file
- Name the file after the class: `AiAvatar` → `ai_avatar.dart`
- Private helper widgets (`_Foo`) must become public classes in separate files

### Maximum File Size
Keep individual files under **200 lines**. When exceeded:
- Extract widgets to separate files in `widgets/` directory
- Split controllers into multiple files by responsibility
- Create utility modules for helper functions

### Naming Conventions

**Files:** `snake_case.dart`
```
✅ auth_controller.dart
❌ AuthController.dart
```

**Classes:** `PascalCase`
```dart
class AuthController extends GetxController {}
class UserModel {}
```

**Variables/Functions:** `camelCase`
```dart
final userName = ''.obs;
void sendMessage() {}
```

**Private:** `_camelCase`
```dart
final String _apiKey = 'secret';
void _handleError() {}
```

### Import Organization

```dart
// 1. Flutter/Dart packages
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 2. External packages
import 'package:dio/dio.dart';

// 3. Internal imports (relative paths)
import '../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
```

## Environment Configuration

The app uses environment files loaded via `flutter_dotenv`:

```
.env.dev   # Development config
.env.prod  # Production config
```

**Loading:**
```bash
flutter run --dart-define=ENV=dev    # Loads .env.dev
flutter run --dart-define=ENV=prod   # Loads .env.prod
```

**Access:**
```dart
import 'package:flowering/config/env_config.dart';

final apiUrl = EnvConfig.apiBaseUrl;
final isDev = EnvConfig.isDev;
```

## Localization Workflow

**Translation files:**
- `l10n/english-translations-en-us.dart` - English (99 keys)
- `l10n/vietnamese-translations-vi-vn.dart` - Vietnamese (99 keys)

**Usage:**
```dart
Text('app_name'.tr)  // Simple translation
Text('welcome_user'.trParams({'name': userName}))  // With parameters
```

**Language switching:**
```dart
Get.updateLocale(const Locale('vi', 'VN'));
```

## Testing Strategy

### Unit Tests
Test controllers in isolation using mock services:

```dart
void main() {
  group('AuthController', () {
    late AuthController controller;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      Get.put<ApiClient>(mockApiClient);
      controller = AuthController();
    });

    tearDown(() {
      Get.reset();
    });

    test('login success sets user', () async {
      // Test implementation
    });
  });
}
```

### Widget Tests
Use `GetMaterialApp` for testing widgets with GetX:

```dart
await tester.pumpWidget(
  GetMaterialApp(
    home: LoginScreen(),
    initialBinding: BindingsBuilder(() {
      Get.put<AuthController>(MockAuthController());
    }),
  ),
);
```

## Common Development Workflows

### Adding a New Feature

1. Create feature directory structure:
```bash
mkdir -p lib/features/new_feature/{bindings,controllers,views,widgets}
```

2. Create files following naming convention:
```
bindings/new_feature_binding.dart
controllers/new_feature_controller.dart
views/new_feature_screen.dart
```

3. Add route in `app/routes/app-route-constants.dart`

4. Add page definition in `app/routes/app-page-definitions-with-transitions.dart`

### Adding a New API Endpoint

1. Add constant to `core/constants/api_endpoints.dart`:
```dart
static const String newEndpoint = '/api/new';
```

2. Create/update model in `shared/models/`:
```dart
class NewModel {
  factory NewModel.fromJson(Map<String, dynamic> json) {...}
  Map<String, dynamic> toJson() {...}
}
```

3. Use in controller:
```dart
final response = await apiClient.get<NewModel>(
  ApiEndpoints.newEndpoint,
  fromJson: (data) => NewModel.fromJson(data),
);
```

### Adding New Translations

1. Add key to both language files:
```dart
// english-translations-en-us.dart
'new_key': 'English text',

// vietnamese-translations-vi-vn.dart
'new_key': 'Văn bản tiếng Việt',
```

2. Use in code:
```dart
Text('new_key'.tr)
```

## Performance Best Practices

### Memory Management
```dart
class ChatController extends GetxController {
  late Worker _messageWorker;
  StreamSubscription? _subscription;

  @override
  void onInit() {
    super.onInit();
    _messageWorker = ever(messages, (_) => _sync());
    _subscription = stream.listen(...);
  }

  @override
  void onClose() {
    // CRITICAL: Always dispose resources
    _messageWorker.dispose();
    _subscription?.cancel();
    super.onClose();
  }
}
```

### Build Optimization
```dart
// Use const constructors
const SizedBox(height: 16)
const Icon(Icons.home)

// Use ListView.builder for lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// Extract complex widgets to methods
Widget _buildHeader() {
  return Container(...);
}
```

## Security Considerations

**Never commit:**
- `.env.dev` or `.env.prod` files (add to `.gitignore`)
- API keys or tokens in code
- User credentials in logs

**Always:**
- Store tokens in `AuthStorage` (Hive-based secure storage)
- Validate user input before API calls
- Use HTTPS-only endpoints
- Handle authentication errors gracefully

## Documentation References

Detailed documentation is available in `docs/`:
- `system-architecture.md` - Complete architecture overview
- `code-standards.md` - Coding conventions and patterns
- `codebase-summary.md` - Current implementation status
- `development-roadmap.md` - Project timeline and milestones
- `project-overview-pdr.md` - Product requirements

## Common Issues and Solutions

### Build Runner Issues
```bash
# If build_runner fails
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### GetX Dependency Issues
```bash
# If Get.find() throws not found error
# Ensure service is registered in global-dependency-injection-bindings.dart
# and initialized in main.dart's initializeServices()
```

### Hot Reload Not Working
```bash
# Full restart required after:
# - Changing pubspec.yaml
# - Modifying main.dart
# - Updating environment files
# - Adding new assets
```

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
