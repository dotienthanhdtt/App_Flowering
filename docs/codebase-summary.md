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

### Authentication
- **Google Sign In:** google_sign_in
- **Apple Sign In:** sign_in_with_apple

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
│   │       ├── app-route-constants.dart                     # Route constants (21 routes) ✅
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
│   │   ├── onboarding/                    # Onboarding flow ✅ (screens 01-08)
│   │   │   ├── bindings/                  # DI setup ✅
│   │   │   ├── controllers/               # State management ✅
│   │   │   ├── views/                     # Screens 01-08 ✅
│   │   │   ├── widgets/                   # Custom widgets ✅
│   │   │   ├── models/                    # OnboardingLanguage, Session, etc. ✅
│   │   │   └── services/                  # Language API service ✅
│   │   ├── auth/                          # Authentication ✅ (Screens 09-14)
│   │   │   ├── bindings/                  # DI setup ✅
│   │   │   ├── controllers/               # Login, signup, forgot password ✅
│   │   │   ├── views/                     # Auth screens ✅
│   │   │   └── widgets/                   # OTP input widget ✅
│   │   ├── home/                          # App shell ✅
│   │   │   ├── bindings/                  # DI setup (pending)
│   │   │   ├── controllers/               # Shell controller (pending)
│   │   │   └── views/
│   │   │       └── main-shell-screen.dart # Bottom nav container ✅
│   │   ├── chat/                          # Chat feature ✅
│   │   │   ├── bindings/                  # DI setup (pending)
│   │   │   ├── controllers/               # Chat logic (pending)
│   │   │   └── views/
│   │   │       └── chat-home-screen.dart  # Placeholder screen ✅
│   │   ├── read/                          # Reading feature ✅
│   │   │   ├── bindings/                  # DI setup (pending)
│   │   │   ├── controllers/               # Read logic (pending)
│   │   │   └── views/
│   │   │       └── read-screen.dart       # Placeholder screen ✅
│   │   ├── vocabulary/                    # Vocabulary feature ✅
│   │   │   ├── bindings/                  # DI setup (pending)
│   │   │   ├── controllers/               # Vocab management (pending)
│   │   │   ├── views/
│   │   │   │   └── vocabulary-screen.dart # Placeholder screen ✅
│   │   │   └── widgets/                   # Vocab components (pending)
│   │   ├── profile/                       # User profile ✅
│   │   │   ├── bindings/                  # DI setup (pending)
│   │   │   ├── controllers/               # Profile logic (pending)
│   │   │   └── views/
│   │   │       └── profile-screen.dart    # Placeholder screen ✅
│   │   ├── lessons/                       # Lesson browser (pending)
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
- User: /users/me (GET/PUT), /user/profile
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
  - **BottomNavBar** - Custom 4-tab navigation bar with active/inactive states ✅ (Phase 6.5)
    - Colors: Orange (#FF7A27) active, Gray (#9C9585) inactive
    - Height: 80px, Corner radius: 20px (top)
    - Integrated with MainShellScreen
- **Shared Models** (`lib/shared/models/`):
  - UserModel, ApiErrorModel
- **Utilities** (`lib/core/utils/`):
  - Validators (email, password, required, minLength)
  - Extensions (String, DateTime, Duration)

### ✅ Completed (Phase 5)

#### Routing Configuration
- GetX named routing with 14 routes
- Route constants in `app-route-constants.dart`
- Page-to-route mapping with transitions in `app-page-definitions-with-transitions.dart`
- Global bindings for 5 core services + onboarding binding
- Material3 theme with Warm Orange color scheme (#FF7A27)
- System UI configuration (portrait, transparent status bar)
- Initial route changed from `/login` to `/splash`

**Routes (21 total):**

| Constant | Path | Screen |
|---|---|---|
| `splash` | `/` | Splash / initialization |
| `onboardingWelcome` | `/onboarding/welcome` | Welcome screen 1 |
| `onboardingWelcome2` | `/onboarding/welcome-2` | Welcome screen 2 |
| `onboardingWelcome3` | `/onboarding/welcome-3` | Welcome screen 3 |
| `onboardingNativeLanguage` | `/onboarding/native-language` | Native language selection |
| `onboardingLearningLanguage` | `/onboarding/learning-language` | Learning language selection |
| `onboardingScenarioGift` | `/onboarding/scenario-gift` | AI scenario gift screen (screen 08) |
| `onboardingLoginGate` | `/onboarding/login-gate` | Login gate bottom sheet |
| `login` | `/login` | Login screen |
| `register` | `/register` | Register screen |
| `signup` | `/signup` | Sign-up screen |
| `forgotPassword` | `/forgot-password` | Forgot password |
| `otpVerification` | `/otp-verification` | OTP verification |
| `newPassword` | `/new-password` | New password entry |
| `home` | `/home` | **MainShellScreen (app shell with bottom nav)** ✅ |
| `chat` | `/home?tab=0` | ChatHomeScreen (via nav bar) |
| `read` | `/home?tab=1` | ReadScreen (via nav bar) |
| `vocabulary` | `/home?tab=2` | VocabularyScreen (via nav bar) |
| `profile` | `/home?tab=3` | ProfileScreen (via nav bar) |
| `lessons` | `/lessons` | Lesson browser (future) |
| `settings` | `/settings` | App settings (future) |

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

### ✅ Completed (Phase 6.5 - Bottom Navigation Bar)

#### Main App Shell & Bottom Navigation
- **MainShellScreen** - App shell container with bottom navigation
  - IndexedStack-based page switching
  - Maintains screen state across tab switches
  - Routes to 4 main feature screens
  - Integrated with GetX routing as `/home` route

- **BottomNavBar Widget** - Custom navigation bar
  - 4-tab layout (Chat, Read, Vocabulary, Profile)
  - Active color: #FF7A27 (Warm Orange)
  - Inactive color: #9C9585 (Gray)
  - Background: #FFFDF7 (Cream White)
  - Height: 80px with 20px top corner radius
  - lucide_icons for modern iconography
  - Translation keys for all tab labels (EN & VI)

- **Feature Placeholder Screens** - Ready for implementation
  - `ChatHomeScreen` - `/home?tab=0` or via nav bar
  - `ReadScreen` - `/home?tab=1` or via nav bar
  - `VocabularyScreen` - `/home?tab=2` or via nav bar
  - `ProfileScreen` - `/home?tab=3` or via nav bar

- **Vocabulary Feature Module** - New directory structure
  - `/lib/features/vocabulary/` with bindings, controllers, views, widgets
  - Placeholder screen ready for feature implementation
  - Translation keys added (EN & VI)

- **Dependencies Added**
  - `lucide_icons` - Modern icon library for navigation icons

- **Translation Keys** (99+ keys updated to include navigation)
  - `nav_chat` - Chat tab label
  - `nav_read` - Reading tab label
  - `nav_vocabulary` - Vocabulary tab label
  - `nav_profile` - Profile tab label

**Files Created:**
- `/lib/shared/widgets/bottom-nav-bar.dart` (custom widget)
- `/lib/features/home/views/main-shell-screen.dart` (app shell)
- `/lib/features/chat/views/chat-home-screen.dart` (placeholder)
- `/lib/features/read/views/read-screen.dart` (placeholder)
- `/lib/features/vocabulary/views/vocabulary-screen.dart` (placeholder)
- `/lib/features/vocabulary/bindings/`, `controllers/`, `widgets/` directories

**Success Criteria Met:**
- ✅ Bottom navigation renders with correct styling and colors
- ✅ All 4 tabs functional and accessible
- ✅ Tab switching smooth without memory leaks
- ✅ Active/inactive states display correctly
- ✅ Integration with existing routes verified
- ✅ Screen state preserved across tab switches (IndexedStack)
- ✅ Localization keys for all navigation labels complete
- ✅ No breaking changes to authentication flow

---

### ✅ Completed (Phase 6 - First Half)

#### Onboarding Feature (Screens 01-06)
- **Splash Screen**: Loading indicator while initializing app
- **3 Welcome Screens**: Feature introduction with animations
- **2 Language Selection Screens**: Native and target language selection with API integration
- **OnboardingLanguageService**: Fetches `GET /languages?type=native|learning`, caches 24h, offline fallback
- **OnboardingController**: Manages progression with `nativeLanguages`, `learningLanguages`, `isLoadingLanguages` observables
- **OnboardingBinding**: Dependency injection with language service
- **UserModel Updates**: Added displayName, nativeLanguageId, nativeLanguageCode, nativeLanguageName, targetLanguageId, targetLanguageCode, targetLanguageName

**API Integrations:**
- `GET /users/me` - Fetch current user profile
- `PUT /users/me` - Update user profile (language preferences, display name)
- `GET /languages?type=native|learning` - Fetch available languages with UUID and flag URLs
- `CachedNetworkImage` with emoji fallback for language flags

**Service Implementation:**
- `OnboardingLanguageService`: Parallel language loading, 24h cache via `StorageService`
- Loading skeletons + error/retry states on screens 04-05
- UUID-based language selection tracking

**Configuration Updates:**
- `.env.dev` API base URL: `https://dev.broduck.me`
- Initial app route: `/splash`

### ✅ Completed (Phase 6 - Second Half, Phases 01-06)

#### Onboarding Feature (Screens 01-08) ✅ COMPLETED

**Screens 01-06 (First Half):**
- ✅ Splash Screen - Initialization loader
- ✅ 3 Welcome Screens (02-04) - Feature introduction
- ✅ Native Language Screen (05) - `GET /languages?type=native` with caching
- ✅ Learning Language Screen (06) - `GET /languages?type=learning` with UUID selection

**Screens 07-08 (Phase 02 - AI Chat Integration):**
- ✅ **Screen 07:** AI Chat introduction & real API integration - `POST /onboarding/chat`
  - Flora AI conversation flow
  - Real message sending to backend
  - Streaming response handling
  - Back button cancellation support
- ✅ **Screen 08:** Scenario Gift screen - `POST /onboarding/start`
  - AI-generated scenario card display
  - Gift icon animation
  - Scenario metadata (title, description, icon, accent color)

#### Authentication Feature (Screens 09-14) ✅ COMPLETED

**Screens 09-11 (Phase 05 - Auth UI):**
- ✅ **Screen 09:** LoginGate bottom sheet - Modal overlay prompting sign-up/login
- ✅ **Screen 10:** Signup screen - `POST /auth/register`
  - Email + password + confirm password fields
  - Form validation
  - AuthResponse handling with token storage
- ✅ **Screen 11:** Login screen - `POST /auth/login`
  - Email + password fields
  - Token refresh on successful auth
  - Persistent `AuthController` for session management

**Screens 12-14 (Phase 06 - Forgot Password Flow):**
- ✅ **ForgotPasswordController** - Separate controller managing 3-screen flow
  - `currentStep` observable (1: email, 2: OTP, 3: password)
  - `requestForgotPassword()` - POST to `/auth/forgot-password`
  - `verifyOtp()` - Validates OTP and advances to password screen
  - `resetPassword()` - POST to `/auth/reset-password` with token
- ✅ **Screen 12:** Forgot Password - Email input
  - `POST /auth/forgot-password` to initiate flow
  - Email validation
  - Spinner during request
- ✅ **Screen 13:** OTP Verification - 6-digit input
  - `OtpInputField` widget (custom 6-box input)
  - Auto-advance on last digit entry
  - Paste support (extracts first 6 digits)
  - Backspace for deletion
  - 47-second countdown timer
  - Resend OTP button
- ✅ **Screen 14:** New Password
  - Password + confirm password fields
  - `POST /auth/reset-password` with OTP token
  - Password validation (min 8 chars, uppercase, lowercase, number, special char)
- ✅ **OtpInputField** widget - Reusable 6-digit OTP component
  - Auto-advance behavior
  - Paste handling
  - Visual feedback per box
  - Cursor management

**New Models Added:**
- `OnboardingSession` - `POST /onboarding/start`, `POST /onboarding/chat` response; `sessionToken`, `turnNumber`, `isLastTurn`, `floraMessage`, `quickReplies`
- `OnboardingProfile` - `POST /onboarding/complete` response; `userId`, `scenarios`, `preferences`
- `Scenario` - AI scenario model; `id`, `title`, `description`, `icon`, `accentColor`
- `OnboardingLanguage` - Language API model; `id` (UUID), `flagUrl`, `name`, `code`; offline fallback
- `AuthResponse` - Auth endpoints response; `accessToken`, `refreshToken`, `user`

**API Integrations (Complete):**
- `GET /languages?type=native|learning` - Language lists with caching
- `POST /onboarding/chat` - Flora AI chat messages
- `POST /onboarding/start` - Scenario generation
- `POST /auth/register` - User signup
- `POST /auth/login` - User login
- `POST /auth/forgot-password` - Initiate password reset
- `POST /auth/reset-password` - Complete password reset with OTP

**Routes (14 total for onboarding + auth):**
- `/onboarding/welcome` → splash → welcome 1-3
- `/onboarding/native-language` → screen 05
- `/onboarding/learning-language` → screen 06
- `/onboarding/ai-chat-intro` → screen 07
- `/onboarding/scenario-gift` → screen 08
- `/onboarding/login-gate` → screen 09 (modal)
- `/signup` → screen 10
- `/login` → screen 11
- `/forgot-password` → screen 12
- `/otp-verification` → screen 13
- `/new-password` → screen 14

**Services:**
- `OnboardingLanguageService` - Fetches languages with 24h cache, offline fallback
- `ForgotPasswordController` - Manages 3-step password reset flow

**Packages Added:**
- `google_sign_in` - Google OAuth
- `sign_in_with_apple` - Apple Sign In

**Translation Keys:** 99+ keys per language (EN + VI) covering all screens 01-14

### 🔲 Pending Implementation

#### Phase 7 onwards: Core App Features
- Home dashboard
- Chat with AI
- Lessons browser
- Profile and settings

### Core Services Layer (Phase 3)

| Service | File | Purpose |
|---|---|---|
| `StorageService` | `lib/core/services/storage_service.dart` | Hive boxes: lessons LRU (100MB), chat FIFO (10MB), preferences (1MB) |
| `AuthStorage` | `lib/core/services/auth_storage.dart` | Token CRUD (`saveTokens`, `getAccessToken`, `isLoggedIn`, `clearTokens`) |
| `ConnectivityService` | `lib/core/services/connectivity_service.dart` | Reactive `isOnline` observable, stream-based detection |
| `AudioService` | `lib/core/services/audio_service.dart` | AAC-LC recording (128kbps), file/URL playback, permission check |

See `system-architecture.md` for full API signatures.

### Core Network Layer (Phase 2)

| File | Purpose |
|---|---|
| `api_response.dart` | `ApiResponse<T>` wrapper: `{code, message, data}`, `isSuccess` (code==1) |
| `api_exceptions.dart` | 8 typed exceptions: Network, Timeout, Unauthorized, Forbidden, NotFound, Server, Validation, ApiError |
| `auth_interceptor.dart` | `QueuedInterceptor` — Bearer injection, 401 → token refresh → retry, logout on failure |
| `retry_interceptor.dart` | Exponential backoff max 3 retries (1s/2s/4s) for network + 5xx; skips 4xx |
| `api_client.dart` | Singleton Dio: timeouts (connect 15s, receive 30s), `get/post/put/delete/uploadFile` |

See `system-architecture.md` for full interceptor flow and usage examples.

### Core Constants & Config

| File | Purpose |
|---|---|
| `lib/config/env_config.dart` | `EnvConfig.apiBaseUrl`, `EnvConfig.isDev` — loaded from `.env.dev`/`.env.prod` |
| `lib/core/constants/app_colors.dart` | Warm Orange (#FF7A27) primary, Cream White (#FFFDF7) backgrounds, accent groups (Blue/Green/Lavender/Rose) |
| `lib/core/constants/app_text_styles.dart` | Outfit font, h1-h3, bodyLarge/Medium/Small, button/caption/label |
| `lib/core/constants/api_endpoints.dart` | Static route constants; auth, user, lessons, chat, progress, onboarding |

**Environment:**
- Dev: `API_BASE_URL=https://dev.broduck.me` — run with `--dart-define=ENV=dev`
- Prod: `API_BASE_URL=https://api.flowering.app` — run with `--dart-define=ENV=prod`

## Architecture Patterns

**Data Flow:** `View → Controller → Service → API/Storage → (back)`

**State:** `.obs` for simple reactive values; `GetBuilder` for lists/complex objects.

**Offline:** Hive cache (LRU lessons 100MB / FIFO chat 10MB); sync on reconnect.

**Security:** HTTPS-only; tokens in `AuthStorage`; never log sensitive data.

See `system-architecture.md` for full patterns and `code-standards.md` for conventions.

## Design System

| Token | Value |
|---|---|
| Primary | #FF7A27 Warm Orange |
| Background | #FFFDF7 Cream White |
| Text Primary | #292F36 Charcoal |
| Text Secondary | #699A6B Sage Green |
| Border | #A3A9AA |
| Success | #CAFFBF Mint Green |
| Warning | #FFD6A5 Peach |
| Error | #FF4444 |
| Font | Outfit 12-32px |
| Button height | 48px, pill radius |
| Min touch target | 44x44 |

## Testing Strategy (Planned)

- **Unit:** Controller logic, service operations, model serialization
- **Widget:** Rendering, state updates, user interactions
- **Integration:** API communication, storage operations, feature workflows
- **Target:** >70% coverage

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

1. **Immediate (Phase 7 - Home Dashboard):**
   - Create home dashboard screen with user stats
   - Implement quick action cards
   - Add navigation to chat, lessons, profile
   - Display learning progress

2. **Short-term (Phase 8 - Chat Feature):**
   - Implement AI chat interface
   - Add voice input/output support
   - Create message persistence
   - Build offline message queue

3. **Medium-term (Phase 9-10):**
   - Implement lessons browser with offline caching
   - Create profile and settings screens
   - Add vocabulary management features
   - Implement reading comprehension tools

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
