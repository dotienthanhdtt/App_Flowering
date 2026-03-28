# System Architecture

## Architecture Overview

Flowering uses a **feature-first clean architecture** with Flutter and GetX for state management. The architecture prioritizes modularity, testability, and offline-first capabilities.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Presentation Layer                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │   Features (Auth, Home, Chat, Lessons, Profile)      │   │
│  │   - Views (UI Components)                            │   │
│  │   - Controllers (Business Logic)                     │   │
│  │   - Bindings (Dependency Injection)                  │   │
│  │   - Widgets (Feature-specific Components)            │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                         Domain Layer                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │   Shared Models & Business Entities                  │   │
│  │   - UserModel, MessageModel, LessonModel             │   │
│  │   - ApiErrorModel, ApiResponse                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                          Data Layer                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │   Core Services ✅                                   │   │
│  │   - ApiClient (Dio HTTP Client) ✅                   │   │
│  │   - StorageService (Hive Cache) ✅                   │   │
│  │   - AuthStorage (Token Storage) ✅                   │   │
│  │   - AudioService (Voice I/O) ✅                      │   │
│  │   - ConnectivityService (Network Status) ✅          │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Infrastructure Layer                    │
│  - Network (Dio, Interceptors)                              │
│  - Local Storage (Hive, Secure Storage)                     │
│  - Platform Services (Audio, Permissions)                   │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
lib/
├── main.dart                                           # App entry point ✅
├── app/                                                # App configuration ✅
│   ├── flowering-app-widget-with-getx.dart            # Main app widget ✅
│   ├── global-dependency-injection-bindings.dart      # Global DI ✅
│   └── routes/                                         # Navigation ✅
│       ├── app-route-constants.dart                   # Route constants ✅
│       └── app-page-definitions-with-transitions.dart # Route definitions ✅
├── core/                              # Core infrastructure
│   ├── constants/                     # App-wide constants
│   │   ├── app_colors.dart            # Color palette
│   │   ├── app_text_styles.dart       # Typography
│   │   └── api_endpoints.dart         # API URLs
│   ├── network/                       # Networking layer
│   │   ├── api_client.dart            # Dio client
│   │   ├── api_response.dart          # Response wrapper
│   │   ├── api_exceptions.dart        # Error types
│   │   └── auth_interceptor.dart      # Token injection
│   ├── services/                      # Core services
│   │   ├── storage_service.dart       # Hive operations
│   │   ├── auth_storage.dart          # Secure token storage
│   │   ├── connectivity_service.dart  # Network monitoring
│   │   └── audio_service.dart         # Audio I/O
│   ├── utils/                         # Utilities
│   │   ├── extensions.dart            # Dart extensions
│   │   └── validators.dart            # Input validation
│   └── base/                          # Base classes
│       ├── base_controller.dart       # Controller template
│       └── base_screen.dart           # Screen template
├── shared/                            # Shared resources
│   ├── widgets/                       # Reusable widgets
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_text.dart
│   │   ├── app_icon.dart
│   │   ├── loading_widget.dart
│   │   ├── loading_overlay.dart
│   │   └── error_widget.dart
│   └── models/                        # Shared models
│       ├── user_model.dart
│       └── api_error_model.dart
├── features/                          # Feature modules
│   ├── auth/                          # Authentication
│   │   ├── bindings/                  # DI bindings
│   │   ├── controllers/               # Business logic
│   │   ├── views/                     # UI screens
│   │   └── widgets/                   # Feature widgets
│   ├── subscription/                  # In-app purchases & subscriptions
│   │   ├── services/
│   │   │   ├── revenuecat-service.dart   # RevenueCat SDK wrapper
│   │   │   └── subscription-service.dart # Subscription orchestration (pending)
│   │   ├── models/                    # Subscription models
│   │   ├── bindings/                  # DI bindings
│   │   ├── controllers/               # Business logic
│   │   ├── views/                     # Subscription UI
│   │   └── widgets/                   # Feature widgets
│   ├── home/                          # Home dashboard
│   ├── chat/                          # AI chat
│   ├── lessons/                       # Lesson browser
│   ├── profile/                       # User profile
│   └── settings/                      # App settings
├── l10n/                                      # Localization ✅
│   ├── app-translations-loader.dart           # Translation map ✅
│   ├── english-translations-en-us.dart        # English strings (99 keys) ✅
│   └── vietnamese-translations-vi-vn.dart     # Vietnamese strings (99 keys) ✅
└── config/                            # Configuration
    └── env_config.dart                # Environment vars
```

## Layer Responsibilities

### 1. Presentation Layer (Features)

**Purpose:** Handle UI rendering and user interactions.

**Components:**
- **Views:** Screens extend `BaseScreen<T>` (provides Scaffold, SafeArea, loading overlay). Tab child screens and StatefulWidget screens are exempt.
- **Controllers:** All extend `BaseController` (provides `isLoading`, `errorMessage`, `apiCall()`, `showSuccess()`)
- **Bindings:** Dependency injection for controllers and services
- **Widgets:** Feature-specific reusable components (do NOT extend base classes)

**Pattern:** MVC with GetX reactive state management

**Base Class Inheritance (Mandatory):**
- Controllers: `BaseController` → never `GetxController` directly
- Screens with controller: `BaseScreen<T>` → override `buildContent()` instead of `build()`
- Tab child screens in IndexedStack: plain `StatelessWidget` (avoids nested Scaffold)
- StatefulWidget screens: exempt, add explanatory comment

**Example:**
```dart
// Feature structure
features/auth/
  ├── bindings/auth_binding.dart      # Inject AuthController
  ├── controllers/auth_controller.dart # extends BaseController
  ├── views/login_screen.dart          # extends BaseScreen<AuthController>
  └── widgets/auth_text_field.dart     # Custom input field (no base class)
```

### 2. Domain Layer (Shared Models)

**Purpose:** Define business entities and data structures.

**Components:**
- Data models with serialization
- Business logic entities
- API response/error models

**Pattern:** Plain Dart classes with JSON serialization

**Key Models:**
- `UserModel` - User profile data
- `ChatMessage` - Message data with optional translation caching
- `WordTranslationModel` - Translation data for individual words (translations, phonetics)
- `SentenceTranslationModel` - Sentence-level translation with word mappings
- `ApiErrorModel` - API error response parsing
- `ApiResponse<T>` - Generic response wrapper with code/message/data structure

### 3. Data Layer (Core Services)

**Purpose:** Manage data sources and external integrations.

**Services:**
- **ApiClient:** HTTP requests via Dio
- **StorageService:** Local cache with Hive
- **AuthStorage:** Secure token storage
- **AudioService:** Voice recording/playback
- **ConnectivityService:** Network status monitoring

**Pattern:** Singleton services registered in GetX

### Core Services (Phase 3 ✅)

#### RevenueCatService

Thin wrapper around RevenueCat SDK for in-app subscriptions and purchases.

**Purpose:** Handle RevenueCat initialization, user identification, purchase flows, and subscription state updates.

**Key Methods:**
```dart
Future<RevenueCatService> init()  // Initialize SDK with platform-specific API keys
Future<LogInResult> logIn(String userId)  // Link anonymous RC user to backend user
Future<CustomerInfo> logOut()  // Reset to anonymous user
Future<Offerings> getOfferings()  // Fetch available products/subscriptions
Future<CustomerInfo> purchasePackage(Package package)  // Handle purchase flow
Future<CustomerInfo> restorePurchases()  // Restore existing purchases
Future<CustomerInfo> getCustomerInfo()  // Get current subscription state
Stream<CustomerInfo> get customerInfoStream  // Subscribe to subscription changes
bool get isConfigured  // Check if SDK initialized successfully
```

**Features:**
- Platform-specific API keys (iOS and Android)
- Graceful handling of missing API keys (no crash, service disabled)
- Debug logging in development mode
- Reactive CustomerInfo updates via stream
- Proper error handling and resource cleanup

**Error Handling:**
- SDK initialization failures logged to console
- PlatformExceptions propagated to callers for UI handling
- Stream cleanup on service disposal

**Configuration:**
- Requires `revenueCatAppleApiKey` and `revenueCatGoogleApiKey` in environment
- Uses `purchases_flutter` v8.11.0 SDK

#### StorageService
Hive-based local storage with intelligent cache eviction.

**Boxes:**
- `lessons_cache` - Lesson content (100MB max, LRU eviction)
- `lessons_access` - Access timestamps for LRU tracking
- `chat_cache` - Chat messages (10MB max, FIFO eviction)
- `preferences` - App settings (1MB max)

**Key Methods:**
```dart
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
```

**Eviction Logic:**
- Lessons: LRU (evicts least recently accessed when exceeding 100MB)
- Chat: FIFO (evicts oldest messages when exceeding 10MB)
- Size tracking: UTF-16 estimation (2 bytes per character)

**Error Handling:**
- Hive box corruption: try-catch with box recreation
- Validation on read operations

#### AuthStorage
Token management using Hive.

**Storage Keys:**
- `access_token` - JWT access token
- `refresh_token` - JWT refresh token
- `user_id` - Current user identifier

**Key Methods:**
```dart
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
```

**Security Note:** Uses Hive for token storage (acceptable for mobile per plan). Can be upgraded to flutter_secure_storage if higher security needed.

#### ConnectivityService
Real-time network status monitoring with reactive state.

**Observable State:**
```dart
final _isOnline = true.obs;
bool get isOnline => _isOnline.value;
```

**Features:**
- Stream subscription to connectivity changes
- Automatic online/offline detection
- Triggers sync when back online
- Proper stream cleanup in onClose()

**Key Methods:**
```dart
Future<ConnectivityService> init();
Future<bool> checkConnection();
```

#### AudioService
Audio recording and playback with permission handling.

**Observable State:**
```dart
final isRecording = false.obs;
final isPlaying = false.obs;
final recordingDuration = Duration.zero.obs;
final playbackPosition = Duration.zero.obs;
final playbackDuration = Duration.zero.obs;
```

**Recording Configuration:**
- Encoder: AAC-LC
- Bitrate: 128kbps
- Sample rate: 44.1kHz
- Output: Temp directory with timestamp

**Key Methods:**
```dart
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
Future<void> setPlaybackRate(double rate);
```

**Resource Management:**
- Timer cleanup on stop/cancel
- Proper disposal of recorder and player
- Stream subscription cleanup
- Memory leak fixes applied

#### TranslationService
Word and sentence translation via backend API with caching.

**Observable State:**
```dart
final isTranslating = false.obs;
final lastTranslatedWord = ''.obs;
```

**Key Methods:**
```dart
// Word translation
Future<WordTranslationModel?> toggleTranslation({
  required String messageId,
  required String word,
});

// Cache management
Future<WordTranslationModel?> getTranslation(String word);
Future<void> saveTranslation(String word, WordTranslationModel translation);
Future<void> clearTranslationCache();
```

**Caching Strategy:**
- Translations cached in StorageService with LRU eviction
- Cache key: word hash (lowercase)
- Reduces repeated API calls for same word
- 24-hour cache expiration (implementation may vary)

**API Contract:**
- Endpoint: `POST /ai/translate`
- Request: `{messageId: UUID, word: String}`
- Response: `{translations: [String], phoneticSimilar: String, phoneticOriginal: String}`

### 4. Infrastructure Layer

**Purpose:** Low-level platform integrations.

**Components:**
- Network interceptors (auth, logging, retry)
- Storage adapters (Hive type adapters)
- Platform channels (native code)

## State Management Strategy

### GetX Reactive State

**Reactive Variables (.obs):**
```dart
// Use for simple UI state
final isLoading = false.obs;
final userName = ''.obs;
```

**GetBuilder:**
```dart
// Use for complex state or lists
GetBuilder<ChatController>(
  builder: (controller) => ListView.builder(...)
)
```

**Workers:**
```dart
// React to state changes
ever(userName, (value) => print('Name changed: $value'));
debounce(searchQuery, (_) => search(), time: Duration(seconds: 1));
```

## Network Architecture

### Dio Configuration

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

### Interceptor Chain

**Order:** Retry → Auth → Logging

1. **RetryInterceptor:** Retry network/server errors with exponential backoff
   - Max retries: 3
   - Delay: 1s, 2s, 4s (exponential)
   - Retries: timeouts, connection errors, 5xx errors
   - Skips: 4xx errors, cancelled requests

2. **AuthInterceptor:** JWT token injection and automatic refresh
   - Type: `QueuedInterceptor` (prevents concurrent refresh)
   - Injects: `Authorization: Bearer <token>` header
   - On 401: refresh token → retry original request
   - On refresh failure: clear tokens → redirect to login
   - Uses separate Dio instance for refresh to avoid loops

3. **LoggingInterceptor:** Request/response logging (dev mode only)
   - Logs: method, path, status code
   - Format: `→ POST /auth/login`, `← 200 /auth/login`, `✗ 401 /user/profile`

### Error Handling

**Exception Mapping:**
```dart
try {
  final response = await apiClient.get('/endpoint');
} on NetworkException catch (e) {
  // No internet connection
} on TimeoutException catch (e) {
  // Request timeout
} on UnauthorizedException catch (e) {
  // Session expired
} on ValidationException catch (e) {
  // Field validation errors: e.errors
} on ServerException catch (e) {
  // 5xx server error
} on ApiException catch (e) {
  // Generic API error
  showSnackbar(e.userMessage);
}
```

**DioException Mapping:**
- `DioExceptionType.connectionTimeout` → `TimeoutException`
- `DioExceptionType.connectionError` → `NetworkException`
- Status 401 → `UnauthorizedException`
- Status 403 → `ForbiddenException`
- Status 404 → `NotFoundException`
- Status 422 → `ValidationException`
- Status 5xx → `ServerException`
- Others → `ApiErrorException`

### API Contract

**JSON Key Naming Convention:** All API request/response JSON keys use `snake_case` (as of 2026-03-28).

**Key Migration Reference:**
- **AuthResponse:** `accessToken` → `access_token`, `refreshToken` → `refresh_token`
- **UserModel:** `displayName` → `name`, `avatarUrl` → `profile_picture`, added `email_verified`, `updated_at`
- **OnboardingLanguage:** `isNativeAvailable`/`isLearningAvailable` → `is_active`, `flagUrl` → `flag_url`, `nativeName` → `native_name`
- **OnboardingSession:** `sessionToken` → `session_id`, `turnNumber` → `turn_count`, `reply` → `response`, added `max_turns`, `expires_at`
- **SubscriptionModel:** `expiresAt` → `current_period_start`/`current_period_end`, `isActive` → `is_active`, `cancelAtPeriodEnd` → `cancel_at_period_end`
- **WordTranslationModel:** `partOfSpeech` → `part_of_speech`, `vocabularyId` → `vocabulary_id`
- **SentenceTranslationModel:** `messageId` → `message_id`, `translation` → `translated_content`

**Model Pattern:** All models use manual `fromJson`/`toJson` with snake_case JSON keys. Dart properties remain camelCase. See `docs/code-standards.md` → "JSON Serialization" for implementation details.

**Backward Compatibility:** Models include fallback reads for cached data with old camelCase keys, enabling safe migration without cache wipes.

---

### API Response Format

**Server Response:**
```json
{
  "code": 1,
  "message": "Success",
  "data": {
    "id": "123",
    "name": "John"
  }
}
```

**Client Wrapper:**
```dart
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code == 1;
  bool get isError => code != 1;
}
```

**Usage:**
```dart
final response = await apiClient.get<UserModel>(
  ApiEndpoints.profile,
  fromJson: (json) => UserModel.fromJson(json),
);

if (response.isSuccess) {
  final user = response.data!;
} else {
  showError(response.message);
}
```

### Token Refresh Flow

```
1. Request → 401 Unauthorized
2. AuthInterceptor detects 401
3. Check _isRefreshing flag
4. If refreshing: queue request
5. If not: set flag, call refresh endpoint
6. Receive new access + refresh tokens
7. Save tokens via AuthStorage
8. Update request header with new token
9. Retry original request
10. Clear _isRefreshing flag

On refresh failure:
- Clear all tokens
- Navigate to login screen
- Show "Session expired" message
```

### File Upload

**Multipart Upload:**
```dart
await apiClient.uploadFile(
  ApiEndpoints.uploadAvatar,
  filePath: '/path/to/image.jpg',
  fieldName: 'avatar',
  data: {'user_id': userId},
  onSendProgress: (sent, total) {
    print('Upload: ${(sent / total * 100).toStringAsFixed(0)}%');
  },
);
```

## Storage Architecture

### Hive Boxes

| Box Name | Purpose | Max Size | Eviction |
|----------|---------|----------|----------|
| `auth` | Access/refresh tokens, user ID | 10KB | Manual |
| `lessons_cache` | Lesson content | 100MB | LRU |
| `chat_cache` | Chat message history | 10MB | FIFO |
| `preferences` | App settings | 1MB | Manual |

### Secure Storage

**Token Storage:**
- Access token: AuthStorage (Hive 'auth' box)
- Refresh token: AuthStorage (Hive 'auth' box)
- User ID: AuthStorage (Hive 'auth' box)

**Storage Pattern:**
- Tokens: Separate Hive box from cache (prevents accidental cache eviction)
- Cache: Separate boxes for lessons (LRU 100MB) and chat (FIFO 10MB)
- Acceptable for mobile; can upgrade to flutter_secure_storage if needed for higher security

## Audio Architecture

### Voice Input Flow

```
User Press → Request Permission → Start Recording →
Convert to WAV → Send to API → Receive Response → Play Audio
```

### Audio Service Responsibilities

- Microphone permission handling
- Audio recording with record package
- Audio playback with audioplayers package
- Format conversion (if needed)
- Error handling (permission denied, codec issues)

## Offline-First Strategy

### Sync Mechanism

1. **Optimistic UI:** Update UI immediately, sync in background
2. **Message Queue:** Queue actions when offline
3. **Conflict Resolution:** Last-write-wins for simple cases
4. **Sync Trigger:** On connectivity change, app foreground

### Cache Strategy

**Lessons:**
- Cache all accessed lessons
- LRU eviction when exceeding 100MB
- Refresh on app start if online

**Chat:**
- Keep last 10MB of messages
- FIFO eviction for old messages
- Sync unsynced messages on reconnect

## Security Architecture

### Authentication Flow

```
1. User Login → POST /auth/login
2. Receive access + refresh tokens
3. Store tokens in AuthStorage (Hive 'auth' box)
4. Inject access token in API requests (AuthInterceptor)
5. On 401 → Refresh token → Retry request
6. On refresh failure → Logout user
```

### Token Refresh

```dart
// AuthInterceptor handles this automatically
if (response.statusCode == 401) {
  await refreshToken();
  return retry(request);
}
```

### Data Protection

- Tokens in AuthStorage (separate from cache)
- Cache in Hive with eviction limits (lessons LRU 100MB, chat FIFO 10MB)
- HTTPS-only communication
- Certificate pinning (future enhancement)

## Dependency Injection

### Global Services (app_bindings.dart)

```dart
Get.lazyPut(() => ApiClient());
Get.lazyPut(() => StorageService());
Get.lazyPut(() => AuthStorage());
Get.lazyPut(() => ConnectivityService());
Get.lazyPut(() => AudioService());
```

**Service Initialization:**
All services extend `GetxService` and implement `init()` method:
```dart
final storage = Get.find<StorageService>();
await storage.init();
```

### Feature Bindings

```dart
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
  }
}
```

## Navigation Architecture (Phase 5-6.5 ✅)

### Bottom Navigation Bar (Phase 6.5 ✅)

**Implementation:**
- **Widget:** `BottomNavBar` in `lib/shared/widgets/bottom-nav-bar.dart`
- **Container:** `MainShellScreen` in `lib/features/home/views/main-shell-screen.dart`
- **Strategy:** IndexedStack for efficient tab switching

**Navigation Tabs (4 total):**
| Tab | Label | Screen | Route |
|-----|-------|--------|-------|
| Chat | `nav_chat` | ChatHomeScreen | `/home?tab=0` |
| Read | `nav_read` | ReadScreen | `/home?tab=1` |
| Vocabulary | `nav_vocabulary` | VocabularyScreen | `/home?tab=2` |
| Profile | `nav_profile` | ProfileScreen | `/home?tab=3` |

**Design Specifications:**
```dart
// Colors
activeTabColor: #FF7A27 (Warm Orange)
inactiveTabColor: #9C9585 (Gray)
backgroundColor: #FFFDF7 (Cream White)

// Dimensions
height: 80px
cornerRadius: 20px (top corners only)
padding: Responsive (16-24px horizontal)

// Icons
Library: lucide_icons
Size: 24-28px (scalable)
```

**Page Switching Logic:**
```dart
// MainShellScreen uses IndexedStack
IndexedStack(
  index: selectedTab.value,
  children: [
    ChatHomeScreen(),
    ReadScreen(),
    VocabularyScreen(),
    ProfileScreen(),
  ],
)
```

**State Management:**
- GetX controller tracks `selectedTab` observable (0-3)
- Tab switching triggers controller update
- Screen state preserved across tab switches (no rebuild)
- Navigation labels localized (EN & VI)

---

## Navigation Architecture (Phase 5 ✅)

### Route Management

GetX routing with named routes and global bindings configured.

**Routes Defined (9 total):**
```dart
// app-route-constants.dart
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const chat = '/chat';
  static const lessons = '/lessons';
  static const lessonDetail = '/lessons/:id';
  static const profile = '/profile';
  static const settings = '/settings';
}
```

**Page Configuration:**
```dart
// app-page-definitions-with-transitions.dart
GetPage(
  name: AppRoutes.splash,
  page: () => const SplashScreen(),
  transition: Transition.fade,
  transitionDuration: const Duration(milliseconds: 300),
)
```

### Navigation Transitions

All transitions use `rightToLeft` with 300ms duration for consistent UX.

### Global Dependency Injection

**AppBindings (5 Core Services):**
```dart
// global-dependency-injection-bindings.dart
Get.lazyPut(() => ApiClient());
Get.lazyPut(() => StorageService());
Get.lazyPut(() => AuthStorage());
Get.lazyPut(() => ConnectivityService());
Get.lazyPut(() => AudioService());
```

Services initialized in dependency order during app startup.

## Localization Architecture (Phase 5 ✅)

### Translation Structure

**Languages:** EN, VI
**Total Keys:** 99 per language

**Translation Files:**
- `app-translations-loader.dart` - GetX translations map
- `english-translations-en-us.dart` - English strings
- `vietnamese-translations-vi-vn.dart` - Vietnamese strings

**Categories:**
- Common (app_name, ok, cancel, retry, etc.)
- Auth (login, register, password, email, etc.)
- Home (dashboard, progress, stats, etc.)
- Chat (new_chat, voice_input, send_message, etc.)
- Lessons (browse, start, complete, bookmark, etc.)
- Profile (edit, logout, settings, language, etc.)
- Errors (network_error, timeout, unauthorized, etc.)

### Usage

```dart
Text('app_name'.tr)  // Translate key
Text('welcome_user'.trParams({'name': userName}))  // With params
Get.updateLocale(const Locale('vi', 'VN'))  // Switch language
```

## Material3 Theme (Phase 5 ✅)

**Color Scheme - Warm Neutral Palette:**
- Primary: #FF7A27 (Warm Orange) - Main action color
- Background: #FFFDF7 (Cream White) - Surface and canvas
- Text Primary: #292F36 (Charcoal) - Body text
- Text Secondary: #699A6B (Sage Green) - Secondary text
- Accent Colors: Blue (#5B7FD9), Green (#CAFFBF), Lavender (#B8C5E8), Rose (#FDCAE1)
- Semantic: Success #CAFFBF, Warning #FFD6A5, Error #FF4444, Info #A0C4FF

**System Configuration:**
- Material3 enabled (`useMaterial3: true`)
- Seed color generation from primary
- Portrait-only orientation
- Transparent status bar with dark icons

## Performance Considerations

### Memory Management

- Dispose controllers in `onClose()`
- Dispose workers/streams
- Clear image cache periodically
- Use `GetX SmartManagement.full`

### Rendering Optimization

- Use `const` constructors
- ListView.builder for long lists
- Debounce search inputs
- Lazy load images with cached_network_image

### Build Optimization

- Tree shaking enabled
- Obfuscation in release builds
- Split debug info
- Minimize app bundle size

## Technology Stack Summary

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.10.3+ |
| Language | Dart 3.10.3+ |
| State Management | GetX 4.6.6 |
| Networking | Dio 5.4.0 |
| Cache Storage | Hive 2.2.3 |
| Token Storage | Hive (AuthStorage) |
| Audio Recording | record 5.0.4 |
| Audio Playback | audioplayers 5.2.1 |
| In-App Subscriptions | purchases_flutter 8.11.0 |
| Localization | intl 0.19.0 |
| Typography | google_fonts 6.1.0 |
| Connectivity | connectivity_plus 6.0.3 |

## Design Patterns Used

- **MVC:** Model-View-Controller for features
- **Singleton:** Core services
- **Repository:** Data access abstraction
- **Factory:** Model creation
- **Observer:** GetX reactive state
- **Dependency Injection:** GetX bindings
- **Strategy:** Offline sync strategies
