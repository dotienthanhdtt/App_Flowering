# Codebase Summary

## Project Overview

**Name:** Flowering
**Type:** Flutter Mobile Application
**Description:** AI-powered language learning app with Vietnamese/English support
**Framework:** Flutter 3.10.3+
**Architecture:** Feature-first clean architecture with GetX state management

## Technology Stack

### Core Framework
- **Flutter SDK:** ^3.10.3
- **Dart:** ^3.10.3
- **State Management:** GetX 4.6.6

### Networking & Storage
- **HTTP Client:** Dio 5.4.0
- **Local Cache:** Hive 2.2.3, Hive Flutter 1.1.0
- **Secure Storage:** flutter_secure_storage (planned for Phase 3)

### Audio & Media
- **Audio Recording:** record 5.0.4
- **Audio Playback:** audioplayers 5.2.1
- **Image Caching:** cached_network_image 3.3.1
- **SVG Support:** flutter_svg 2.0.9

### Localization & UI
- **Internationalization:** intl 0.19.0
- **Typography:** google_fonts 6.1.0
- **Icons:** cupertino_icons 1.0.8

### Utilities
- **Environment Config:** flutter_dotenv 5.1.0
- **Network Status:** connectivity_plus 6.0.3
- **UUID Generation:** uuid 4.3.3

### Development Tools
- **Linting:** flutter_lints 6.0.0
- **Code Generation:** hive_generator 2.0.1, build_runner 2.4.8

## Project Structure

```
flowering/
├── lib/
│   ├── main.dart                                             # App entry point ✅
│   ├── app/                                                  # App-level configuration ✅
│   │   ├── flowering-app-widget-with-getx.dart              # Main app widget ✅
│   │   ├── global-dependency-injection-bindings.dart        # Global DI (5 services) ✅
│   │   └── routes/
│   │       ├── app-route-constants.dart                     # Route constants (9 routes) ✅
│   │       └── app-page-definitions-with-transitions.dart   # Route definitions ✅
│   │
│   ├── core/                              # Core infrastructure
│   │   ├── constants/
│   │   │   ├── app_colors.dart            # Color palette ✅
│   │   │   ├── app_text_styles.dart       # Typography ✅
│   │   │   └── api_endpoints.dart         # API URLs ✅
│   │   ├── network/
│   │   │   ├── api_client.dart            # Dio client ✅
│   │   │   ├── api_response.dart          # Response wrapper ✅
│   │   │   ├── api_exceptions.dart        # Error types ✅
│   │   │   ├── auth_interceptor.dart      # Token management ✅
│   │   │   └── retry_interceptor.dart     # Retry logic ✅
│   │   ├── services/
│   │   │   ├── storage_service.dart       # Hive operations ✅
│   │   │   ├── auth_storage.dart          # Token storage ✅
│   │   │   ├── connectivity_service.dart  # Network monitor ✅
│   │   │   └── audio_service.dart         # Audio I/O ✅
│   │   ├── utils/
│   │   │   ├── extensions.dart            # Dart extensions (pending)
│   │   │   └── validators.dart            # Input validation (pending)
│   │   └── base/
│   │       ├── base_controller.dart       # Controller template (pending)
│   │       └── base_screen.dart           # Screen template (pending)
│   │
│   ├── shared/                            # Shared resources
│   │   ├── widgets/                       # Reusable UI components (pending)
│   │   │   ├── app_button.dart
│   │   │   ├── app_text_field.dart
│   │   │   ├── app_text.dart
│   │   │   ├── app_icon.dart
│   │   │   ├── loading_widget.dart
│   │   │   ├── loading_overlay.dart
│   │   │   └── error_widget.dart
│   │   └── models/                        # Domain models (pending)
│   │       ├── user_model.dart
│   │       └── api_error_model.dart
│   │
│   ├── features/                          # Feature modules
│   │   ├── auth/                          # Authentication (pending)
│   │   │   ├── bindings/
│   │   │   ├── controllers/
│   │   │   ├── views/
│   │   │   └── widgets/
│   │   ├── home/                          # Home dashboard (pending)
│   │   ├── chat/                          # AI chat (pending)
│   │   ├── lessons/                       # Lesson browser (pending)
│   │   ├── profile/                       # User profile (pending)
│   │   └── settings/                      # App settings (pending)
│   │
│   ├── l10n/                                      # Internationalization ✅
│   │   ├── app-translations-loader.dart           # GetX translations ✅
│   │   ├── english-translations-en-us.dart        # English (99 keys) ✅
│   │   └── vietnamese-translations-vi-vn.dart     # Vietnamese (99 keys) ✅
│   │
│   └── config/
│       └── env_config.dart                # Environment vars ✅
│
├── assets/
│   ├── logos/                             # Logo assets (pending)
│   ├── icons/                             # Icon assets (pending)
│   └── images/                            # Image assets (pending)
│
├── .env.dev                               # Dev environment ✅
├── .env.prod                              # Prod environment ✅
├── pubspec.yaml                           # Dependencies ✅
└── README.md                              # Project readme

✅ = Implemented
(pending) = Folder/file created, implementation pending
```

## Current Implementation Status

### ✅ Completed (Phase 1)

#### 1. Project Structure
All folders created following feature-first architecture.

#### 2. Dependencies Configuration (pubspec.yaml)
Complete dependency setup with all required packages.

#### 3. Environment Configuration
- `.env.dev` - Development API configuration
- `.env.prod` - Production API configuration
- `EnvConfig` class for accessing environment variables

#### 4. Core Constants

**app_colors.dart** - Pencil Warm Neutral Palette:
```dart
- Primary: #FF7A27 (Warm Orange)
- Neutrals:
  - Background/Surface: #FFFDF7 (Cream White)
  - Text Primary: #292F36 (Charcoal)
  - Text Secondary: #699A6B (Sage Green)
  - Text Tertiary: #A3A9AA (removed textHint)
  - Border: #A3A9AA (renamed from divider)
- Semantic:
  - Success: #CAFFBF (Mint Green)
  - Warning: #FFD6A5 (Peach)
  - Error: #FF4444
  - Info: #A0C4FF (Sky Blue)
- Accent Groups (new):
  - Blue: Brand accent group
  - Green: Success accent group
  - Lavender: Alternative accent group
  - Rose: Alternative accent group
- Light Semantic Variants (new):
  - Success Light: Light success background
  - Error Light: Light error background
- Surface Variants (new):
  - Surface variant for secondary backgrounds
- Chat:
  - User Bubble: #FF7A27 (Warm Orange)
  - AI Bubble: #FFFDF7 (Cream White)
```

**app_text_styles.dart** - Typography System:
```dart
- Headings: h1 (32px), h2 (24px), h3 (20px)
- Body: bodyLarge (16px), bodyMedium (14px), bodySmall (12px)
- Components: button (15px), caption (12px), label (13px w600)
- Font: Outfit (changed from Inter)
```

**api_endpoints.dart** - API Routes:
```dart
- Auth: /auth/login, /auth/register, /auth/refresh, /auth/logout
- User: /user/profile
- Lessons: /lessons, /lessons/:id
- Chat: /chat/messages, /chat/send, /chat/voice
- Progress: /progress, /progress/stats
```

### ✅ Completed (Phase 2)

#### Core Network Layer
- ApiResponse wrapper with code/message/data structure
- ApiException types with DioException mapping
- AuthInterceptor with QueuedInterceptor for thread-safe token refresh
- RetryInterceptor with exponential backoff (max 3 retries)
- ApiClient singleton with GET/POST/PUT/DELETE/uploadFile methods

### ✅ Completed (Phase 3)

#### Core Services Layer
- StorageService with LRU eviction for lessons (100MB) and FIFO for chat (10MB)
- AuthStorage using Hive for token management
- ConnectivityService with online/offline detection
- AudioService for recording/playback with proper cleanup
- Error handling for all Hive and audio operations
- Memory leak fixes in audio service
- path_provider dependency added

### ✅ Completed (Phase 4)

#### Base Classes & Shared Widgets
- **BaseController** (`lib/core/base/base_controller.dart`) - Controller template with apiCall wrapper
- **BaseScreen** (`lib/core/base/base_screen.dart`) - Screen wrapper with loading overlay
- **Shared Widgets** (`lib/shared/widgets/`):
  - AppButton (4 variants), AppTextField (with validation), AppText (8 variants)
  - AppIcon, LoadingWidget, LoadingOverlay, AppErrorWidget
- **Shared Models** (`lib/shared/models/`):
  - UserModel, ApiErrorModel
- **Utilities** (`lib/core/utils/`):
  - Validators (email, password, required, minLength)
  - Extensions (String, DateTime, Duration)

### ✅ Completed (Phase 5)

#### Routing Configuration
- GetX named routing with 9 routes
- Route constants in `app-route-constants.dart`
- Page-to-route mapping with transitions in `app-page-definitions-with-transitions.dart`
- Global bindings for 5 core services
- Material3 theme with Orange color scheme
- System UI configuration (portrait, transparent status bar)

**Routes:**
- `/` - Splash screen
- `/login` - Login screen
- `/register` - Register screen
- `/home` - Home dashboard
- `/chat` - AI chat
- `/lessons` - Lesson browser
- `/lessons/:id` - Lesson detail
- `/profile` - User profile
- `/settings` - App settings

**Transitions:** All use `rightToLeft` at 300ms

#### Localization (i18n)
- EN/VI language support
- 99 translation keys per language
- Categories: Common, Auth, Home, Chat, Lessons, Profile, Errors
- GetX translation system with `.tr` extension
- Language switching support

**Translation Files:**
- `app-translations-loader.dart` - Translation map
- `english-translations-en-us.dart` - English strings
- `vietnamese-translations-vi-vn.dart` - Vietnamese strings

#### Global Dependencies
Services registered in `global-dependency-injection-bindings.dart`:
- ApiClient
- StorageService
- AuthStorage
- ConnectivityService
- AudioService

#### App Configuration
- Main app widget with GetX integration
- Material3 theme enabled
- Portrait-only orientation
- Transparent status bar
- Service initialization flow in main.dart

### 🔲 Pending Implementation

#### Phases 6-10: Features (0%)
- Authentication
- Home
- Chat
- Lessons
- Profile/Settings

### Core Services Layer (Phase 3)

#### 1. lib/core/services/storage_service.dart

**Purpose:** Hive-based storage with LRU eviction for lessons and FIFO for chat

**Implementation:**
```dart
class StorageService extends GetxService {
  // Boxes: lessons_cache, lessons_access, chat_cache, preferences
  // Limits: 100MB lessons, 10MB chat, 1MB preferences

  Future<StorageService> init(); // Initialize all boxes

  // LRU lessons cache
  String? getLesson(String key);
  Future<void> saveLesson(String key, String value);

  // FIFO chat cache
  String? getChatMessage(String key);
  Future<void> saveChatMessage(String key, String value);

  // Preferences
  T? getPreference<T>(String key);
  Future<void> setPreference<T>(String key, T value);

  // Cache management
  int get totalCacheSize;
  Future<void> clearAllCaches();
}
```

**Key Features:**
- Automatic LRU eviction when lessons exceed 100MB
- FIFO eviction for chat messages (10MB limit)
- Size tracking via UTF-16 estimation
- Error handling with box recreation on corruption

#### 2. lib/core/services/auth_storage.dart

**Purpose:** Secure token storage using Hive

**Implementation:**
```dart
class AuthStorage extends GetxService {
  Future<AuthStorage> init();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveUserId(String userId);
  String? getUserId();

  bool get isLoggedIn;
  Future<void> clearTokens();
}
```

**Security Note:** Uses Hive for token storage (acceptable for mobile per plan). Can be upgraded to flutter_secure_storage if needed.

#### 3. lib/core/services/connectivity_service.dart

**Purpose:** Real-time network status monitoring

**Implementation:**
```dart
class ConnectivityService extends GetxService {
  final _isOnline = true.obs;
  bool get isOnline => _isOnline.value;

  Future<ConnectivityService> init();
  Future<bool> checkConnection();

  // Stream subscription for connectivity changes
  // Triggers sync when back online
}
```

**Features:**
- Reactive observable for connectivity status
- Automatic reconnection detection
- Stream subscription with proper cleanup

#### 4. lib/core/services/audio_service.dart

**Purpose:** Audio recording and playback with permission handling

**Implementation:**
```dart
class AudioService extends GetxService {
  final isRecording = false.obs;
  final isPlaying = false.obs;
  final recordingDuration = Duration.zero.obs;

  Future<AudioService> init();

  // Recording
  Future<bool> hasRecordPermission();
  Future<String?> startRecording();
  Future<String?> stopRecording();
  Future<void> cancelRecording();

  // Playback
  Future<void> playFile(String path);
  Future<void> playUrl(String url);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
}
```

**Features:**
- AAC-LC encoding at 128kbps
- Recording to temp directory with timestamp
- Stream-based playback position tracking
- Proper resource cleanup in onClose()
- Memory leak fixes applied

### Core Network Layer (Phase 2)

#### 1. lib/core/network/api_response.dart

**Purpose:** Standard API response wrapper

**Structure:**
```dart
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code == 1;
  bool get isError => code != 1;

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT);
  factory ApiResponse.success({T? data, String message = 'Success'});
  factory ApiResponse.error({int code = 0, required String message});
}
```

**Response Codes:**
- 1: Success
- 0: General error
- -1: Validation error
- 401: Unauthorized
- 403: Forbidden
- 404: Not found
- 500: Server error

#### 2. lib/core/network/api_exceptions.dart

**Purpose:** Custom exception types with user-friendly messages

**Exception Hierarchy:**
- `ApiException` (base class)
  - `NetworkException` - Connection failed
  - `TimeoutException` - Request timeout
  - `UnauthorizedException` - 401 errors
  - `ForbiddenException` - 403 errors
  - `NotFoundException` - 404 errors
  - `ServerException` - 5xx errors
  - `ValidationException` - 422 with field errors
  - `ApiErrorException` - Generic API errors

**Key Function:**
```dart
ApiException mapDioException(DioException error)
```
Maps Dio exceptions to typed API exceptions with appropriate user messages.

#### 3. lib/core/network/auth_interceptor.dart

**Purpose:** JWT token injection and automatic refresh

**Implementation:**
- Extends `QueuedInterceptor` for thread-safe token refresh
- Injects Bearer token on all requests (except refresh endpoint)
- On 401: refreshes token, retries original request
- Uses separate Dio instance for refresh to avoid interceptor loops
- Prevents concurrent refresh with `_isRefreshing` flag
- Triggers logout on refresh failure

**Token Refresh Flow:**
1. Request fails with 401
2. Check if already refreshing
3. Call refresh endpoint with refresh token
4. Save new tokens via AuthStorage
5. Retry original request with new access token
6. On failure: clear tokens and redirect to login

#### 4. lib/core/network/retry_interceptor.dart

**Purpose:** Automatic retry with exponential backoff

**Configuration:**
- Max retries: 3
- Initial delay: 1s
- Backoff: exponential (1s, 2s, 4s)

**Retry Conditions:**
- Connection timeout
- Send timeout
- Receive timeout
- Connection errors
- 5xx server errors

**Skip Retry:**
- 4xx client errors (except handled by auth interceptor)
- Request cancellation

#### 5. lib/core/network/api_client.dart

**Purpose:** Singleton Dio HTTP client with configured interceptors

**Configuration:**
```dart
BaseOptions(
  baseUrl: EnvConfig.apiBaseUrl,
  connectTimeout: Duration(seconds: 15),
  receiveTimeout: Duration(seconds: 30),
  sendTimeout: Duration(seconds: 15),
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
)
```

**Interceptor Chain:**
1. RetryInterceptor (handles network/server errors)
2. AuthInterceptor (handles token refresh)
3. LoggingInterceptor (dev builds only)

**Available Methods:**
- `get<T>()` - GET request
- `post<T>()` - POST request
- `put<T>()` - PUT request
- `delete<T>()` - DELETE request
- `uploadFile<T>()` - Multipart file upload

**Usage Pattern:**
```dart
final apiClient = Get.find<ApiClient>();
try {
  final response = await apiClient.get<UserModel>(
    ApiEndpoints.profile,
    fromJson: (data) => UserModel.fromJson(data),
  );
  if (response.isSuccess) {
    final user = response.data;
  }
} on ApiException catch (e) {
  // Handle typed exceptions
  print(e.userMessage);
}
```

### Legacy Files

#### 1. lib/config/env_config.dart

**Purpose:** Environment configuration wrapper

**Implementation:**
```dart
class EnvConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get env => dotenv.env['ENV'] ?? 'development';
  static bool get isDev => env == 'development';
  static bool get isProd => env == 'production';
}
```

**Usage:** Access via `EnvConfig.apiBaseUrl`, `EnvConfig.isDev`

#### 2. lib/core/constants/app_colors.dart

**Purpose:** Centralized color definitions

**Key Colors:**
- Primary Vibrant Orange for branding and primary actions
- Secondary Sage Green for growth/nature theme
- Cream White backgrounds for warm, Gen Z aesthetic
- Mint Green and Peach for success/warning states
- Full complementary palette (Sky Blue, Soft Pink)
- Chat-specific colors for message bubbles

**Pattern:** Private constructor prevents instantiation, static const for compile-time constants

#### 3. lib/core/constants/app_text_styles.dart

**Purpose:** Typography system

**Design System:**
- Hierarchical headings (h1, h2, h3)
- Body text variants (large, medium, small)
- Component-specific styles (button, caption, label)
- Consistent font family (Inter)
- Proper font weights and sizes

**Integration:** Uses `AppColors` for text colors

#### 4. lib/core/constants/api_endpoints.dart

**Purpose:** API route definitions

**Categories:**
- Authentication endpoints
- User management
- Lesson operations
- Chat functionality
- Progress tracking

**Pattern:** Static const for routes, static method for parameterized routes

#### 5. lib/main.dart

**Purpose:** App entry point

**Current Implementation:**
- Initializes Flutter bindings
- Loads environment-specific .env file
- Initializes Hive
- Launches GetMaterialApp

**Note:** Minimal implementation, will be expanded in Phase 5

## Environment Configuration

### Development (.env.dev)
```
API_BASE_URL=https://dev-api.flowering.app
ENV=development
```

### Production (.env.prod)
```
API_BASE_URL=https://api.flowering.app
ENV=production
```

**Usage:** Load via `flutter run --dart-define=ENV=dev`

## Architecture Patterns

### State Management
- **Pattern:** GetX reactive state management
- **Controllers:** Extend `GetxController`
- **Reactive State:** `.obs` variables for simple state
- **Complex State:** `GetBuilder` for lists/complex objects
- **DI:** GetX bindings for dependency injection

### Data Flow
```
View → Controller → Service → API/Storage
     ← Controller ← Service ← Response
```

### Feature Structure
Each feature module contains:
- **bindings/**: Dependency injection setup
- **controllers/**: Business logic and state
- **views/**: UI screens
- **widgets/**: Feature-specific components

### Offline Strategy
- **Cache:** Hive for offline data persistence
- **Sync:** Background sync when online
- **Queue:** Offline action queue for API calls
- **Strategy:** LRU for lessons, FIFO for chat

## Design System

### Color Scheme - Pencil Warm Neutral Palette
- **Brand Primary:** Warm Orange (#FF7A27)
- **Neutral:** Cream White (#FFFDF7) for backgrounds/surfaces, Charcoal (#292F36) for primary text, Tertiary text (#A3A9AA)
- **Semantic:** Mint Green (#CAFFBF) for success, Peach (#FFD6A5) for warning, Red (#FF4444) for error, Sky Blue (#A0C4FF) for info
- **Accent Groups:** Blue, Green, Lavender, Rose (new)
- **Light Variants:** Success light, Error light (new)
- **Surface Variants:** Surface variant for secondary backgrounds (new)

### Typography
- **Font Family:** Outfit (sans-serif, changed from Inter)
- **Scale:** 12px to 32px
- **Weights:** 400 (regular), 500 (medium), 600 (semibold), 700 (bold)
- **Usage:** Consistent application via `AppTextStyles`

### Component Design Specs
- **Buttons:** 48px height (down from 56px), pill radius (updated), 15px text (down from 18px), orange shadow on primary, new secondary (primarySoft bg), new outline (borderStrong border)
- **Text Fields:** 12px border radius (down from 16px), 16px horizontal padding (down from 20px), 1.5px border width (down from 2px)
- **Touch Targets:** Minimum 44x44

### Layout Principles
- **Spacing:** 4px base unit (8, 12, 16, 24, 32)
- **Touch Targets:** Minimum 44x44
- **Max Width:** 600px for content areas
- **Padding:** Consistent edge padding (16-24px)

## API Integration Strategy

### Authentication Flow
1. Login → Receive access + refresh tokens
2. Store tokens in flutter_secure_storage
3. Inject access token via AuthInterceptor
4. On 401 → Refresh token → Retry request
5. On refresh failure → Logout

### Endpoint Categories

**Auth Endpoints:**
- `POST /auth/login` - User authentication
- `POST /auth/register` - User registration
- `POST /auth/refresh` - Token refresh
- `POST /auth/logout` - Session termination

**User Endpoints:**
- `GET /user/profile` - Fetch user data
- `PUT /user/profile` - Update user data

**Lesson Endpoints:**
- `GET /lessons` - List all lessons
- `GET /lessons/:id` - Get lesson details

**Chat Endpoints:**
- `GET /chat/messages` - Fetch chat history
- `POST /chat/send` - Send text message
- `POST /chat/voice` - Send voice message

**Progress Endpoints:**
- `GET /progress` - User learning progress
- `GET /progress/stats` - Learning statistics

## Performance Considerations

### Memory Management
- **Controllers:** Dispose in `onClose()`
- **Workers:** Cleanup reactive listeners
- **Images:** Use cached_network_image
- **Lists:** ListView.builder for efficiency

### Build Optimization
- **const:** Use const constructors where possible
- **Tree Shaking:** Enabled in release builds
- **Code Splitting:** Feature-based lazy loading
- **Asset Optimization:** Compress images, use SVG

### Storage Limits
- **Lessons Cache:** 100MB (LRU eviction)
- **Chat Messages:** 10MB (FIFO eviction)
- **User Data:** 1MB
- **Settings:** 100KB

## Security Measures

### Data Protection
- **Tokens:** flutter_secure_storage (OS keychain)
- **Cache:** Hive for non-sensitive data only
- **Communication:** HTTPS-only
- **Validation:** Server-side + client-side

### Storage Security
- **DO NOT** store tokens in Hive
- **DO NOT** log sensitive data
- **DO** validate all API responses
- **DO** sanitize user inputs

## Testing Strategy (Planned)

### Unit Tests
- Controller business logic
- Service layer operations
- Utility functions
- Model serialization

### Widget Tests
- UI component rendering
- User interaction handling
- State updates

### Integration Tests
- API communication
- Storage operations
- Feature workflows

## Build Configuration

### Development
```bash
flutter run --dart-define=ENV=dev
```

### Production
```bash
flutter build apk --release --dart-define=ENV=prod
```

## Dependencies Breakdown

### Critical Dependencies (P1)
- GetX: State management and DI
- Dio: HTTP networking
- Hive: Local storage
- flutter_dotenv: Environment config
- path_provider: File paths for audio

### Feature Dependencies (P2)
- record/audioplayers: Voice chat
- google_fonts: Typography
- connectivity_plus: Network monitoring

### UI Enhancement (P3)
- flutter_svg: Vector graphics
- cached_network_image: Image optimization

## Known Technical Debt

1. **Typography Inconsistency:** Plan mentions Open Sans, code uses Inter
2. **Auth Token Storage:** Currently using Hive (acceptable for mobile), can upgrade to flutter_secure_storage
3. **Permission Handler:** Basic permission check exists, full UX flow deferred to feature implementation
4. **Localization:** Translation files empty (Phase 5)
5. **Unit Tests:** 70+ test cases identified, not yet implemented

## Next Implementation Steps

1. **Immediate (Phase 5):**
   - Configure GetX routing
   - Define app routes and pages
   - Implement EN/VI localization
   - Set up navigation transitions

2. **Short-term (Phase 5):**
   - Configure GetX routing
   - Set up EN/VI localization
   - Define app routes

## Code Quality Metrics

### Current Status
- **Compile Errors:** 0
- **Linting Warnings:** 0 (on implemented files)
- **Test Coverage:** 0% (no tests yet)
- **Documentation:** 100% (for implemented files)

### Targets
- **Test Coverage:** > 70%
- **Code Quality:** All linting rules passing
- **Performance:** < 500ms screen load
- **Memory:** < 150MB usage

## References

- **Main Plan:** `/plans/260205-1700-flutter-ai-language-app/plan.md`
- **Phase Details:** `/plans/260205-1700-flutter-ai-language-app/phase-*.md`
- **Architecture:** `/docs/system-architecture.md`
- **Code Standards:** `/docs/code-standards.md`
- **Roadmap:** `/docs/development-roadmap.md`
