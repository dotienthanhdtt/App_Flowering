# Project Changelog

## Version 1.0.0 - In Development

### [2026-02-05] Phase 1: Project Setup & Dependencies ✅ COMPLETED

#### Added
- **Project Structure**
  - Created feature-first folder architecture under `/lib`
  - Established core directories: `app/`, `core/`, `shared/`, `features/`, `l10n/`, `config/`
  - Created feature folders: `auth/`, `home/`, `chat/`, `lessons/`, `profile/`, `settings/`
  - Each feature includes: `bindings/`, `controllers/`, `views/`, `widgets/` subdirectories

- **Dependencies** (pubspec.yaml)
  - State Management: `get ^4.6.6`
  - Networking: `dio ^5.4.0`
  - Local Storage: `hive ^2.2.3`, `hive_flutter ^1.1.0`
  - Audio: `record ^5.0.4`, `audioplayers ^5.2.1`
  - Localization: `intl ^0.19.0`
  - Environment: `flutter_dotenv ^5.1.0`
  - UI: `google_fonts ^6.1.0`, `flutter_svg ^2.0.9`, `cached_network_image ^3.3.1`
  - Connectivity: `connectivity_plus ^6.0.3`
  - Utils: `uuid ^4.3.3`
  - Dev Dependencies: `flutter_lints ^6.0.0`, `hive_generator ^2.0.1`, `build_runner ^2.4.8`

- **Core Constants**
  - `lib/core/constants/app_colors.dart` - Complete color palette with primary (#FF6B35), secondary, neutrals, semantic colors
  - `lib/core/constants/app_text_styles.dart` - Typography system using Google Fonts Inter
  - `lib/core/constants/api_endpoints.dart` - API endpoint definitions for auth, user, lessons, chat, progress

- **Configuration**
  - `lib/config/env_config.dart` - Environment configuration wrapper for dotenv
  - `.env.dev` - Development environment variables (API_BASE_URL, ENV)
  - `.env.prod` - Production environment variables

- **Assets Structure**
  - Created `assets/logos/` directory
  - Created `assets/icons/` directory
  - Created `assets/images/` directory
  - Registered asset paths in pubspec.yaml

#### Changed
- Updated `pubspec.yaml` project description to "AI Language Learning App"
- Configured Flutter assets to include .env files

#### Technical Decisions
- **Architecture:** Feature-first clean architecture with GetX
- **Color Scheme:** Orange primary (#FF6B35), teal secondary (#2EC4B6)
- **Typography:** Google Fonts Inter (Note: Plan mentioned Open Sans but implementation uses Inter)
- **State Management:** GetX for dependency injection and reactive state
- **Storage Strategy:** Hive for cache, flutter_secure_storage for tokens (to be implemented)
- **Environment:** Separate dev/prod configurations via dotenv

#### Build Verification
- ✅ `flutter pub get` completed successfully
- ✅ No dependency conflicts
- ✅ Project compiles without errors
- ✅ All folder structure verified

---

### [2026-02-05] Phase 2: Core Network Layer ✅ COMPLETED

#### Added
- **Network Infrastructure**
  - `lib/core/network/api_client.dart` - Singleton Dio HTTP client with interceptor chain
  - `lib/core/network/api_response.dart` - Generic response wrapper supporting code/message/data structure
  - `lib/core/network/api_exceptions.dart` - 8 exception types with DioException mapper
  - `lib/core/network/auth_interceptor.dart` - QueuedInterceptor for thread-safe token refresh
  - `lib/core/network/retry_interceptor.dart` - Exponential backoff retry mechanism

- **API Client Features**
  - HTTP Methods: `get<T>()`, `post<T>()`, `put<T>()`, `delete<T>()`, `uploadFile<T>()`
  - Automatic request/response type conversion with `fromJson` callbacks
  - Multipart file upload with progress tracking
  - Configurable timeouts: connect (15s), receive (30s), send (15s)

- **Exception Types**
  - `NetworkException` - Connection failures
  - `TimeoutException` - Request timeouts
  - `UnauthorizedException` - 401 errors, session expired
  - `ForbiddenException` - 403 errors, no permission
  - `NotFoundException` - 404 errors, resource not found
  - `ServerException` - 5xx server errors
  - `ValidationException` - 422 with field-level error map
  - `ApiErrorException` - Generic API errors with server messages

- **Interceptor Chain**
  - **RetryInterceptor**: Automatic retry with exponential backoff (1s, 2s, 4s) for network/timeout/5xx errors
  - **AuthInterceptor**: JWT token injection, automatic refresh on 401, logout on refresh failure
  - **LoggingInterceptor**: Request/response logging in dev mode (→ POST /endpoint, ← 200, ✗ 401)

- **Token Management**
  - Bearer token auto-injection on all requests
  - 401 detection triggers refresh flow
  - Separate Dio instance for refresh to prevent interceptor loops
  - Thread-safe refresh with `QueuedInterceptor` prevents concurrent refresh calls
  - Automatic token clear and logout redirect on refresh failure

#### Changed
- Network layer structure from placeholder to full implementation
- Dio configuration with production-ready timeouts and headers
- Error handling from basic try-catch to typed exception hierarchy

#### Technical Decisions
- **QueuedInterceptor:** Prevents race conditions during concurrent 401 responses
- **Separate Refresh Dio:** Avoids infinite loops by using interceptor-free instance for token refresh
- **Exponential Backoff:** Retry delays increase exponentially (1s → 2s → 4s) to reduce server load
- **User-Friendly Messages:** All exceptions include both technical (`message`) and user-facing (`userMessage`) text
- **Typed Responses:** ApiResponse<T> with `fromJson` callback for automatic deserialization
- **Skip Refresh Path:** Refresh endpoint bypasses auth interceptor to prevent circular refresh

#### Security Enhancements
- Tokens injected via interceptor, not manually
- Refresh token only sent to refresh endpoint
- Automatic token clearing on authentication failure
- No sensitive data in debug logs

#### Build Verification
- ✅ All network files compile without errors
- ✅ No circular dependencies
- ✅ Proper exception hierarchy
- ✅ Thread-safe token refresh verified

---

### [2026-02-05] Phase 5: Routing & Localization ✅ COMPLETED

#### Added
- **Routing Configuration**
  - `lib/app/routes/app-route-constants.dart` - 9 named route constants
  - `lib/app/routes/app-page-definitions-with-transitions.dart` - Route-to-page mapping with transitions
  - Routes: splash (/), login, register, home, chat, lessons, lessonDetail (:id param), profile, settings
  - All routes use rightToLeft transition at 300ms

- **Global Dependency Injection**
  - `lib/app/global-dependency-injection-bindings.dart` - Global DI for core services
  - Services: ApiClient, StorageService, AuthStorage, ConnectivityService, AudioService
  - Service initialization flow in main.dart before app launch
  - Dependency order: storage → auth → connectivity → audio → api

- **Localization (i18n)**
  - `lib/l10n/app-translations-loader.dart` - GetX translation map
  - `lib/l10n/english-translations-en-us.dart` - English translations (99 keys)
  - `lib/l10n/vietnamese-translations-vi-vn.dart` - Vietnamese translations (99 keys)
  - Translation categories: Common (14), Auth (16), Home (12), Chat (15), Lessons (18), Profile (13), Errors (11)

- **App Configuration**
  - `lib/app/flowering-app-widget-with-getx.dart` - Main app widget with GetX
  - Material3 theme with Orange primary color (#FF6B35)
  - GetX translations integration
  - Default locale: en_US
  - Fallback locale: en_US

- **System Configuration** (main.dart)
  - Portrait-only orientation lock (portraitUp, portraitDown)
  - System UI overlay: transparent status bar, dark icons
  - Environment-based .env loading (dev/prod)
  - Hive initialization
  - Service initialization before runApp

#### Changed
- `lib/main.dart` - Added service initialization flow and system UI configuration
- App structure from placeholder to production-ready with full routing and i18n

#### Technical Decisions
- **Route Naming:** Kebab-case with descriptive names for readability
- **Transitions:** Standardized rightToLeft at 300ms for consistent UX
- **Translation Keys:** Organized by feature domain for maintainability
- **Material3:** Enabled for modern design language
- **Orientation:** Portrait-only for language learning focus
- **Service Init:** Sequential initialization to handle dependencies properly

#### Build Verification
- ✅ All routing files compile without errors
- ✅ All translation files compile without errors
- ✅ App launches successfully with GetX routing
- ✅ Service initialization completes without errors
- ✅ Material3 theme applies correctly

---

### [2026-02-05] Phase 4: Base Classes & Shared Widgets ✅ COMPLETED

#### Added
- **Base Classes**
  - `lib/core/base/base_controller.dart` - Base controller with apiCall wrapper, loading/error state
  - `lib/core/base/base_screen.dart` - Screen wrapper with loading overlay and error handling

- **Shared Widgets** (`lib/shared/widgets/`)
  - `app_button.dart` - Button component with 4 variants (primary, secondary, outline, text)
  - `app_text_field.dart` - TextField with password toggle, validation, error messages
  - `app_text.dart` - Styled text with 8 typography variants (h1-h3, body, button, caption)
  - `app_icon.dart` - Icon wrapper with tap handling
  - `loading_widget.dart` - Animated pulsating glow loading indicator
  - `loading_overlay.dart` - Blocks interaction during async operations
  - `error_widget.dart` - Error display with retry button

- **Shared Models** (`lib/shared/models/`)
  - `user_model.dart` - User data model with JSON serialization and copyWith
  - `api_error_model.dart` - API error parsing model

- **Utilities** (`lib/core/utils/`)
  - `validators.dart` - Input validators (email, password, required, minLength)
  - `extensions.dart` - String/DateTime/Duration extensions (capitalize, timeAgo, humanDuration)

#### Features
- **BaseController:**
  - `apiCall<T>()` wrapper with automatic loading/error handling
  - Success/error snackbar helpers
  - Reduces boilerplate in feature controllers

- **AppButton:**
  - 4 variants with consistent styling
  - Loading state with spinner
  - Icon support
  - Full-width or auto-width
  - 52px default height, 12px border radius

- **AppTextField:**
  - Password visibility toggle
  - Validation support with error display
  - Label and hint text
  - Keyboard type configuration
  - Max lines control

- **Validators:**
  - Email format validation
  - Password strength (min 8, letter + number)
  - Required field check
  - Minimum length validation

- **Extensions:**
  - String: capitalize(), isValidEmail
  - DateTime: timeAgo(), isToday, isYesterday
  - Duration: humanDuration() (e.g., "2h 30m")

#### Technical Decisions
- **Design System Enforcement:** All widgets strictly use AppColors and AppTextStyles
- **Validation Pattern:** Validators return null for success, String for error message
- **Loading State:** BaseScreen uses Stack with LoadingOverlay to block interaction
- **Error Handling:** BaseController catches ApiException and shows user-friendly messages
- **Typography Variants:** 8 text styles for consistent UI hierarchy
- **Button Variants:** 4 styles for different interaction contexts

#### Build Verification
- ✅ All base classes compile without errors
- ✅ All widgets follow design system
- ✅ Validators tested with common inputs
- ✅ Extensions work with edge cases
- ✅ Models serialize/deserialize correctly

---

### [2026-02-05] Phase 3: Core Services ✅ COMPLETED

#### Added
- **Storage Service**
  - `lib/core/services/storage_service.dart` - Hive box management with LRU/FIFO eviction
  - 4 boxes: lessons_cache (100MB, LRU), chat_messages (10MB, FIFO), user_data (1MB), app_settings (100KB)
  - Size tracking and automatic eviction
  - Error handling with box recreation on corruption

- **Auth Storage**
  - `lib/core/services/auth_storage.dart` - Secure token storage using Hive
  - Token CRUD operations (save, get, clear)
  - User ID persistence
  - `isLoggedIn` check

- **Connectivity Service**
  - `lib/core/services/connectivity_service.dart` - Network status monitoring
  - Real-time connectivity detection with reactive state
  - Stream subscription with proper cleanup

- **Audio Service**
  - `lib/core/services/audio_service.dart` - Voice recording and playback
  - Recording: AAC-LC encoding at 128kbps
  - Playback: File or URL support
  - Permission handling
  - Memory leak fixes

#### Dependencies Added
- `path_provider` - For audio file storage paths

#### Technical Decisions
- **LRU Eviction:** Lessons cache evicts least recently accessed when exceeding 100MB
- **FIFO Eviction:** Chat cache evicts oldest messages when exceeding 10MB
- **Token Storage:** Using Hive (acceptable for mobile per plan)
- **Audio Format:** AAC-LC for compression and quality balance
- **Size Tracking:** UTF-16 estimation (2 bytes per character)

#### Build Verification
- ✅ All services compile without errors
- ✅ Hive boxes properly initialized
- ✅ Memory leaks fixed in audio service
- ✅ Stream subscriptions properly disposed

---

## Upcoming Changes

### [2026-02-09] Design System Update: Flowering Gen Z Aesthetic ✅ COMPLETED

#### Changed
- **Color Palette** - Complete redesign to Flowering Gen Z Aesthetic
  - Primary: #FF6B35 → #FF9500 (Vibrant Orange)
  - Primary Light: #FF8F66 → #FFD6A5 (Peach)
  - Primary Dark: #E55A2B → #E68600
  - Secondary: #2EC4B6 → #699A6B (Sage Green)
  - Secondary Light: #5DD9CD → #CAFFBF (Mint Green)
  - Secondary Dark: #20A99D → #4E7A50
  - Background/Surface: #FAFAFA → #FFFDF7 (Cream White)
  - Text Primary: #1A1A1A → #292F36 (Charcoal)
  - Text Secondary: #6B7280 → #699A6B (Sage Green)
  - Text Hint: #9CA3AF → #A3A9AA
  - Divider: #E5E7EB → #A3A9AA
  - Success: #22C55E → #CAFFBF (Mint Green)
  - Warning: #F59E0B → #FFD6A5 (Peach)
  - Error: #EF4444 → #FF4444
  - Info: #3B82F6 → #A0C4FF (Sky Blue)
  - User Bubble: #FF6B35 → #FF9500
  - AI Bubble: #F3F4F6 → #FFFDF7

- **New Complementary Colors Added**
  - Peach: #FFD6A5
  - Mint: #CAFFBF
  - Sky Blue: #A0C4FF
  - Soft Pink: #FDCAE1

- **AppButton Component** (`lib/shared/widgets/app_button.dart`)
  - Default height: 52px → 56px
  - Horizontal padding: 24px → 32px
  - Border radius: 12px → 28px (pill-shaped buttons)

- **AppTextField Component** (`lib/shared/widgets/app_text_field.dart`)
  - Border radius: 12px → 16px
  - Horizontal padding: 16px → 20px
  - Border width: 1px → 2px (consistent across all states)

- **AppTextStyles** (`lib/core/constants/app_text_styles.dart`)
  - Button text size: 16px → 18px

#### Technical Decisions
- **Design Language:** Gen Z aesthetic with warm, vibrant colors replacing generic palette
- **Button Shape:** Pill-shaped (28px radius) for modern, friendly appearance
- **Border Consistency:** 2px borders across all text field states for visual clarity
- **Color Psychology:** Sage Green for growth/nature theme, Vibrant Orange for energy/action

#### Build Verification
- ✅ All color constants updated without errors
- ✅ All component specs match design file
- ✅ No breaking changes to existing APIs
- ✅ Documentation updated to reflect changes

---

### Phase 6: Authentication Feature (Next)
- Login/register screens with validation
- Auth controller and bindings
- Token management integration
- User session handling

### Phase 7-10: Feature Implementations (Planned)
- Home dashboard
- AI chat with voice support
- Lessons browser with offline caching
- Profile and settings

---

## Known Issues

None currently - Phase 1 completed successfully.

---

## Notes

- Typography inconsistency detected: Implementation plan mentions Open Sans, but current code uses Inter. Team should clarify preferred font.
- Environment separation successfully configured for dev/prod
- All dependencies pinned to specific versions for stability
- Asset folders created but no assets added yet (logo pending)
- No security dependencies added in Phase 1 (flutter_secure_storage planned for Phase 3)

---

## Breaking Changes

None - Initial release.

### [2026-02-26] Design System Sync: Pencil Warm Neutral Palette Update

#### Changed
- **Color Palette**
  - Primary color: #FF9500 → #FF7A27 (Vibrant Orange → Warm Orange)
  - Removed Gen Z aesthetic secondary colors (Sage Green, Mint, Sky Blue, Soft Pink groups)
  - Renamed text colors: `textHint` → `textTertiary`, `divider` → `border`
  - Added new accent groups: Blue, Green, Lavender, Rose
  - Added light semantic variants: Success Light, Error Light
  - Added surface variants for secondary backgrounds
  - Chat bubble primary: #FF9500 → #FF7A27

- **Typography System**
  - Font family: Inter → Outfit
  - Button text size: 18px → 15px
  - Label specification: Updated to 13px weight 600

- **Component Design Specifications**
  - Button height: 56px → 48px
  - Button border radius: Updated to pill-shaped radius
  - Button enhancements: Added orange shadow on primary, new secondary (primarySoft bg), new outline (borderStrong border)
  - Text input border radius: 16px → 12px
  - Text input horizontal padding: 20px → 16px
  - Text input border width: 2px → 1.5px
  - Text input error state: Now uses errorLight fill

#### Impact
- Updated Material3 theme seed color to #FF7A27
- All design documentation synchronized with Pencil design system
- No breaking changes to API or functionality
- Updated 3 documentation files for consistency

---

## Migration Guide

Not applicable - Initial version.

---

## Contributors

- Development Team - Phase 1 implementation (2026-02-05)

---

## References

- Main Plan: `/plans/260205-1700-flutter-ai-language-app/plan.md`
- Phase 1 Details: `/plans/260205-1700-flutter-ai-language-app/phase-01-project-setup.md`
- Architecture Documentation: `/docs/system-architecture.md`
- Code Standards: `/docs/code-standards.md`
