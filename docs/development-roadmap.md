# Development Roadmap

## Project Information

**Project:** Flowering - AI Language Learning App
**Framework:** Flutter 3.10.3+
**Architecture:** Feature-first with GetX
**Start Date:** 2026-02-05
**Target Completion:** 2026-02-12 (7 days)
**Total Effort:** 18 hours

## Roadmap Overview

```
Phase 1: Setup ████████████ 100% (1h) ✅ COMPLETED
Phase 2: Network ████████████ 100% (2h) ✅ COMPLETED
Phase 3: Services ████████████ 100% (2h) ✅ COMPLETED
Phase 4: Base/Widgets ████████████ 100% (2h) ✅ COMPLETED
Phase 5: Routes/i18n ████████████ 100% (1.5h) ✅ COMPLETED
Phase 6: Onboarding & Auth ████████████ 100% (6h) ✅ COMPLETED (screens 01-14)
Phase 6.5: Bottom Navigation ████████████ 100% (1h) ✅ COMPLETED
Phase 6.7: Text→AppText Refactor ████████████ 100% (3h) ✅ COMPLETED
Phase 7: Home Dashboard ░░░░░░░░░░░░ 0% (1.5h) 🔲 Pending
Phase 8: Chat ░░░░░░░░░░░░ 0% (2.5h) 🔲 Pending
Phase 9: Lessons ░░░░░░░░░░░░ 0% (2h) 🔲 Pending
Phase 10: Profile/Settings ░░░░░░░░░░░░ 0% (1.5h) 🔲 Pending
```

**Overall Progress:** 100% of foundation + onboarding + refactoring (21.5h / 25h completed — all user acquisition, app shell, and typography system consolidated)

## Phase Details

### Phase 1: Project Setup & Dependencies ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 1 hour
**Completion Date:** 2026-02-05
**Assignee:** Developer

**Deliverables:**
- ✅ Folder structure (feature-first architecture)
- ✅ Dependencies installed (GetX, Dio, Hive, audio, UI packages)
- ✅ Environment configuration (.env.dev, .env.prod)
- ✅ Core constants (app_colors.dart, app_text_styles.dart, api_endpoints.dart)
- ✅ EnvConfig setup
- ✅ Project compiles successfully

**Key Achievements:**
- Feature-first folder structure established
- 13 dependencies added (GetX, Dio, Hive, audio packages, UI utilities)
- Environment separation configured
- Color palette and typography standards defined
- API endpoints documented
- Build verification successful

**Artifacts:**
- `/lib` folder structure with all feature directories
- `pubspec.yaml` with complete dependencies
- `.env.dev` and `.env.prod` configuration files
- Core constants files in `/lib/core/constants/`
- `EnvConfig` class for environment management

---

### Phase 2: Core Network Layer ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 2 hours
**Completion Date:** 2026-02-05
**Dependencies:** Phase 1 ✅
**Priority:** P1 - Critical

**Deliverables:**
- ✅ `api_client.dart` - Singleton Dio client with interceptor chain
- ✅ `api_response.dart` - Generic response wrapper with code/message/data
- ✅ `api_exceptions.dart` - 8 exception types with DioException mapper
- ✅ `auth_interceptor.dart` - QueuedInterceptor for thread-safe token refresh
- ✅ `retry_interceptor.dart` - Exponential backoff retry (max 3, delays: 1s/2s/4s)

**Key Achievements:**
- Implemented complete HTTP client with GET/POST/PUT/DELETE/uploadFile methods
- Token refresh flow with automatic retry on 401
- Exception hierarchy with user-friendly messages
- Retry mechanism for network/timeout/server errors
- Logging interceptor for development debugging
- All files compile without errors

**Implementation Details:**
- **ApiResponse:** Server returns `{code, message, data}`, client wraps with typed response
- **Exception Types:** Network, Timeout, Unauthorized, Forbidden, NotFound, Server, Validation, ApiError
- **AuthInterceptor:** Uses QueuedInterceptor to prevent concurrent refresh, separate Dio for refresh endpoint
- **RetryInterceptor:** Exponential backoff on network errors and 5xx, skips 4xx client errors
- **ApiClient:** Singleton via GetX service, configurable timeouts (connect: 15s, receive: 30s)

**Artifacts:**
- `/lib/core/network/api_client.dart` (160 LOC)
- `/lib/core/network/api_response.dart` (50 LOC)
- `/lib/core/network/api_exceptions.dart` (120 LOC)
- `/lib/core/network/auth_interceptor.dart` (100 LOC)
- `/lib/core/network/retry_interceptor.dart` (80 LOC)

**Success Criteria Met:**
- ✅ API client makes typed requests with automatic deserialization
- ✅ 401 triggers token refresh, then retries original request
- ✅ Network errors categorized (Network, Timeout, Server, etc.)
- ✅ All responses wrapped in ApiResponse<T>
- ✅ Comprehensive error handling with user messages
- ✅ Thread-safe token refresh prevents race conditions

**Risks Mitigated:**
- ✅ Token refresh race conditions → QueuedInterceptor prevents concurrent refresh
- ✅ Infinite refresh loop → Separate Dio instance for refresh endpoint
- ✅ Memory leaks → Lightweight Dio instances for retry, no interceptors

---

### Phase 3: Core Services ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 2 hours
**Completion Date:** 2026-02-05
**Dependencies:** Phase 2 ✅
**Priority:** P1 - Critical

**Deliverables:**
- ✅ `storage_service.dart` - Hive box management (220 LOC)
- ✅ `auth_storage.dart` - Secure token storage (65 LOC)
- ✅ `connectivity_service.dart` - Network status monitoring (62 LOC)
- ✅ `audio_service.dart` - Voice recording and playback (251 LOC)
- ✅ Hive type adapters for models
- ✅ Permission handling for microphone
- ✅ Error handling for Hive operations
- ✅ Memory leak fixes in audio service

**Key Achievements:**
- Implemented LRU eviction for lessons (100MB limit)
- Implemented FIFO eviction for chat (10MB limit)
- Token storage using Hive (acceptable for mobile)
- Real-time connectivity detection with reactive state
- Audio recording with AAC-LC encoding at 128kbps
- Proper resource cleanup and memory management
- All services compile without errors

**Implementation Details:**
- **StorageService:** 4 Hive boxes with automatic size tracking and eviction
- **AuthStorage:** Token CRUD operations with isLoggedIn check
- **ConnectivityService:** Stream-based connectivity monitoring
- **AudioService:** Recording to temp directory, playback from file or URL
- **Error Handling:** Try-catch with box recreation on corruption
- **Memory Management:** Stream subscriptions properly disposed

**Artifacts:**
- `/lib/core/services/storage_service.dart` (220 LOC)
- `/lib/core/services/auth_storage.dart` (65 LOC)
- `/lib/core/services/connectivity_service.dart` (62 LOC)
- `/lib/core/services/audio_service.dart` (251 LOC)

**Success Criteria Met:**
- ✅ Hive boxes properly initialized
- ✅ Tokens stored securely (using Hive)
- ✅ Real-time connectivity status available
- ✅ Audio recording works with permission handling
- ✅ Services registered globally in GetX
- ✅ LRU eviction works for lessons
- ✅ FIFO eviction works for chat
- ✅ Error handling comprehensive
- ✅ Memory leaks fixed

**Risks Mitigated:**
- ✅ Hive data corruption → Try-catch with box recreation
- ✅ Memory leaks → Stream subscriptions properly disposed
- ⚠️ Permission denial → Basic check exists, full UX flow deferred

**Dependencies Added:**
- `path_provider` - For audio file storage paths

---

### Phase 4: Base Classes & Shared Widgets ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 2 hours
**Completion Date:** 2026-02-05
**Dependencies:** Phase 3 ✅
**Priority:** P1 - Critical

**Deliverables:**
- ✅ `base_controller.dart` - Controller with apiCall wrapper (88 LOC)
- ✅ `base_screen.dart` - Screen template with loading overlay (98 LOC)
- ✅ `app_button.dart` - 4 button variants (135 LOC)
- ✅ `app_text_field.dart` - TextField with validation (145 LOC)
- ✅ `app_text.dart` - 8 typography variants (47 LOC)
- ✅ `app_icon.dart` - Icon wrapper with tap handling (27 LOC)
- ✅ `loading_widget.dart` - Animated pulsating glow (102 LOC)
- ✅ `loading_overlay.dart` - Blocks interaction during loading (47 LOC)
- ✅ `error_widget.dart` - Error display with retry (48 LOC)
- ✅ `user_model.dart` - User data model with JSON (66 LOC)
- ✅ `api_error_model.dart` - API error parsing (38 LOC)
- ✅ `validators.dart` - Input validators (66 LOC)
- ✅ `extensions.dart` - String/DateTime/Duration extensions (82 LOC)

**Key Achievements:**
- BaseController provides common apiCall wrapper with loading/error handling
- BaseScreen wraps content with loading overlay and error states
- 4 button variants: primary, secondary, outline, text
- TextField with password toggle, validation, error messages
- 8 text variants: h1-h3, bodyLarge/Medium/Small, button, caption
- Validators: email, password, required, minLength
- Extensions: capitalize, isValidEmail, timeAgo, humanDuration
- All widgets follow design system (AppColors, AppTextStyles)
- All files compile without errors

**Success Criteria Met:**
- ✅ BaseController reduces boilerplate in feature controllers
- ✅ Loading/error states handled automatically
- ✅ Widgets strictly follow design system
- ✅ Components highly reusable and configurable
- ✅ Consistent styling enforced across app
- ✅ Input validation ready for forms

---

### Phase 5: Routing & Localization ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 1.5 hours
**Completion Date:** 2026-02-05
**Dependencies:** Phase 4 ✅
**Priority:** P2 - High

**Deliverables:**
- ✅ `app-route-constants.dart` - 9 route constants
- ✅ `app-page-definitions-with-transitions.dart` - Route-to-page mapping with bindings
- ✅ `app-translations-loader.dart` - GetX translation map
- ✅ `english-translations-en-us.dart` - English translations (99 keys)
- ✅ `vietnamese-translations-vi-vn.dart` - Vietnamese translations (99 keys)
- ✅ `flowering-app-widget-with-getx.dart` - Main app configuration
- ✅ `global-dependency-injection-bindings.dart` - Global DI for 5 services

**Key Achievements:**
- Implemented 9 named routes (splash, login, register, home, chat, lessons, lessonDetail, profile, settings)
- Configured global bindings for ApiClient, StorageService, AuthStorage, ConnectivityService, AudioService
- Created EN/VI translation files with 99 keys each covering all app sections
- Set up Material3 theme with Orange primary color (#FF6B35)
- Configured rightToLeft transitions at 300ms for all routes
- Portrait-only orientation lock
- Transparent status bar with dark icons
- Service initialization flow in main.dart

**Success Criteria Met:**
- ✅ Named routes working (Get.toNamed('/route'))
- ✅ Smooth transitions (300ms rightToLeft)
- ✅ EN/VI switching ready (.tr extension)
- ✅ Translation categories complete (Common, Auth, Home, Chat, Lessons, Profile, Errors)
- ✅ Global services initialized before app starts
- ✅ Material3 theme active

**Artifacts:**
- `/lib/app/routes/app-route-constants.dart` (25 LOC)
- `/lib/app/routes/app-page-definitions-with-transitions.dart` (95 LOC)
- `/lib/app/global-dependency-injection-bindings.dart` (35 LOC)
- `/lib/app/flowering-app-widget-with-getx.dart` (48 LOC)
- `/lib/l10n/app-translations-loader.dart` (15 LOC)
- `/lib/l10n/english-translations-en-us.dart` (105 LOC)
- `/lib/l10n/vietnamese-translations-vi-vn.dart` (105 LOC)
- `/lib/main.dart` (updated with service init)

---

### Phase 6: Onboarding & Authentication ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 6 hours total (2h first half + 4h second half)
**Completion Date:** 2026-02-28
**Dependencies:** Phase 5 ✅
**Priority:** P1 - Critical

#### First Half (Screens 01-06) ✅ COMPLETED

**Deliverables:**
- ✅ `splash_screen.dart` - Loading indicator screen
- ✅ `onboarding_welcome_1/2/3_screen.dart` - 3 welcome screens with feature highlights
- ✅ `onboarding_language_1/2_screen.dart` - Native and target language selection
- ✅ `onboarding_controller.dart` - State and progression management (`permanent: true`)
- ✅ `onboarding_binding.dart` - Dependency injection
- ✅ `onboarding_model.dart` - Data structure for selections
- ✅ 5 routes added (splash + 4 onboarding welcome/language routes)

**API Integration:**
- `GET /users/me` - Fetch current user profile
- `PUT /users/me` - Update user profile with selected languages and display name
- `GET /languages?type=native|learning` - Fetch language lists (Phase 02)

**Configuration Changes:**
- `.env.dev` API base URL: `https://dev.broduck.me`
- Initial app route: `/splash`

#### Second Half Phase 01 (Scaffolding) ✅ COMPLETED

**Deliverables:**
- ✅ Models: `OnboardingSession`, `OnboardingProfile`, `Scenario`, `AuthResponse`
- ✅ `OnboardingLanguage` restructured with `id`, `flagUrl`, `fromJson()`, `toJson()`
- ✅ 6 route constants (scenario-gift, login-gate, signup, forgot-password, otp, new-password)
- ✅ Social auth packages: `google_sign_in`, `sign_in_with_apple`
- ✅ 99+ translation keys (EN + VI)

#### Second Half Phase 02 (Language API Integration) ✅ COMPLETED

**Deliverables:**
- ✅ `OnboardingLanguageService` - Parallel fetch `GET /languages?type=native|learning`
- ✅ Controller observables: `nativeLanguages`, `learningLanguages`, `isLoadingLanguages`
- ✅ UUID-based selection: `selectedNativeLanguageId`, `selectedLearningLanguageId`
- ✅ Loading skeletons and error/retry states (screens 05-06)
- ✅ `_LanguageFlag` widget with `CachedNetworkImage` + emoji fallback
- ✅ 24-hour cache, offline fallback

#### Second Half Phase 03 (AI Chat Integration) ✅ COMPLETED

**Deliverables:**
- ✅ **Screen 07:** AI Chat intro - Flora AI conversation
  - `POST /onboarding/chat` - Send chat messages
  - Streaming response handling
  - Back button cancellation
- ✅ **Screen 08:** Scenario Gift - AI-generated scenario card
  - `POST /onboarding/start` - Initiate scenario
  - Scenario metadata display (title, description, icon, color)
  - Gift animation

#### Second Half Phase 04 (Auth UI) ✅ COMPLETED

**Deliverables:**
- ✅ **Screen 09:** LoginGate bottom sheet - Modal sign-up/login prompt
- ✅ **Screen 10:** Signup screen
  - `POST /auth/register`
  - Email + password + confirm validation
  - AuthResponse token storage
- ✅ **Screen 11:** Login screen
  - `POST /auth/login`
  - Email + password fields
  - Token refresh, persistent session
  - `AuthController` for session management

#### Second Half Phase 05 (Forgot Password) ✅ COMPLETED

**Deliverables:**
- ✅ **ForgotPasswordController** - 3-step password reset manager
  - `currentStep` observable (email → OTP → password)
  - `requestForgotPassword()` - `POST /auth/forgot-password`
  - `verifyOtp()` - Validate OTP code
  - `resetPassword()` - `POST /auth/reset-password`
- ✅ **Screen 12:** Forgot Password email input
  - Email validation
  - Loading state
- ✅ **Screen 13:** OTP Verification (6-digit input)
  - `OtpInputField` custom widget (6 boxes)
  - Auto-advance on last digit
  - Paste support (extracts first 6)
  - Backspace deletion
  - 47-second countdown timer
  - Resend button
- ✅ **Screen 14:** New Password entry
  - Password + confirm fields
  - Password requirements (8+ chars, uppercase, lowercase, number, special)
  - `POST /auth/reset-password` with OTP token
- ✅ **OtpInputField** widget - Reusable 6-digit OTP component

**API Endpoints (Complete Suite):**
- `GET /languages?type=native|learning` - Language lists
- `GET /users/me` - User profile
- `PUT /users/me` - Update profile
- `POST /onboarding/chat` - Flora AI messages
- `POST /onboarding/start` - Scenario generation
- `POST /auth/register` - User signup
- `POST /auth/login` - User login
- `POST /auth/forgot-password` - Initiate password reset
- `POST /auth/reset-password` - Complete password reset

**Routes (14 total):**
- `/splash` → initialization
- `/onboarding/welcome` → 3 welcome screens
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

**Files Created/Modified:**
- `/lib/features/onboarding/` - Screens 01-08 complete
- `/lib/features/auth/` - Screens 09-14 complete
- `/lib/features/auth/controllers/forgot_password_controller.dart` - 3-step flow
- `/lib/features/auth/widgets/otp_input_field.dart` - 6-box OTP widget
- `/lib/features/onboarding/services/onboarding_language_service.dart` - API + caching
- `api_endpoints.dart` - Updated with all auth/onboarding routes

**Success Criteria Met:**
- ✅ All screens 01-14 render without errors
- ✅ Navigation smooth across all flows
- ✅ API integration complete (9 endpoints)
- ✅ Authentication tokens stored securely
- ✅ Password reset workflow functional
- ✅ OTP handling with countdown and resend
- ✅ Offline language fallback working
- ✅ 24-hour language cache implemented
- ✅ Translation keys complete (EN + VI)

---

### Phase 6.5: Bottom Navigation Bar ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 1 hour
**Completion Date:** 2026-03-04
**Dependencies:** Phase 6 ✅
**Priority:** P1 - Critical

**Deliverables:**
- ✅ `bottom-nav-bar.dart` - Custom bottom navigation widget (4-tab layout)
- ✅ `main-shell-screen.dart` - App shell with IndexedStack page switching
- ✅ Placeholder screens: ChatHomeScreen, ReadScreen, VocabularyScreen, ProfileScreen
- ✅ Vocabulary feature directory structure
- ✅ Translation keys for navigation labels (EN & VI)
- ✅ lucide_icons package for modern icons

**Key Achievements:**
- Implemented 4-tab bottom navigation bar with custom styling
- Orange (#FF7A27) active state, gray (#9C9585) inactive state
- 80px fixed height with 20px corner radius matching Pencil design
- MainShellScreen manages tab state and page switching
- IndexedStack prevents screen rebuilds during tab switching
- All translation keys added for navigation labels (EN & VI)

**Design Specifications:**
- **Active Tab Color:** #FF7A27 (Warm Orange)
- **Inactive Tab Color:** #9C9585 (Gray)
- **Bar Background:** #FFFDF7 (Cream White)
- **Height:** 80px
- **Corner Radius:** 20px (top corners)
- **Icons:** lucide_icons library

**Navigation Tabs:**
1. Chat - ChatHomeScreen
2. Read - ReadScreen
3. Vocabulary - VocabularyScreen
4. Profile - ProfileScreen

**Files Created/Modified:**
- `/lib/shared/widgets/bottom-nav-bar.dart` - New widget
- `/lib/features/home/views/main-shell-screen.dart` - New app shell
- `/lib/features/chat/views/chat-home-screen.dart` - New placeholder
- `/lib/features/read/views/read-screen.dart` - New placeholder
- `/lib/features/vocabulary/views/vocabulary-screen.dart` - New placeholder
- `/lib/features/vocabulary/` - New feature directory
- Translation keys updated (EN & VI)

**Success Criteria Met:**
- ✅ Bottom navigation renders with correct styling
- ✅ All 4 tabs functional and navigable
- ✅ Tab switching smooth with no memory leaks
- ✅ Active/inactive states display correctly
- ✅ Integration with existing routing works
- ✅ Localization keys complete for all nav labels
- ✅ Design system specifications followed

**Integration Points:**
- Replaces previous home route implementation
- Sits between auth flow and feature screens
- Maintains controller state across tab switches
- Uses GetX for reactive state management

---

### Phase 6.7: Text→AppText Refactoring ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 3 hours
**Completion Date:** 2026-03-09
**Dependencies:** Phase 6 ✅
**Priority:** P1 - Quality/Consistency

**Deliverables:**
- ✅ `AppText` widget enhanced with `button` variant and optional override params
- ✅ 100+ raw `Text(` replaced with `AppText(` across 30 files
- ✅ Base widget rule added to CLAUDE.md
- ✅ All `flutter analyze` checks passing
- ✅ All test suite passing (5/5)

**Key Achievements:**
- Unified typography system across entire app
- Enforced Outfit font usage via AppText base widget
- Improved design system compliance
- Established pattern for future text widgets
- No breaking changes, full backward compatibility
- Zero visual regressions

**Files Modified:**
- `lib/shared/widgets/app_text.dart` - Enhanced widget (50 LOC)
- 30 feature and shared widget files - Text replacement batch
- `CLAUDE.md` - Added base widget rule

**Refactoring Details:**
- **Scope:** 100+ raw Text widgets across ~30 files
- **Batches:** Shared widgets (4) → Auth (8) → Chat (9) → Onboarding (8) → Other (4)
- **Exclusions Respected:**
  - TextSpan inside RichText/SelectableText
  - Emoji-only Text widgets (flag emojis)
  - Text inside AppText internals
- **Quality:** All style params mapped correctly, no guessing

**Technical Decisions:**
- **Selective Replacement:** Only language-bearing text replaced
- **Style Merging:** Variant + override approach for flexibility
- **Backward Compatibility:** All new params optional
- **Import Consistency:** Relative paths per convention

**Success Criteria Met:**
- ✅ 100+ Text widgets converted to AppText
- ✅ Consistent Outfit font enforced
- ✅ All translations preserved (.tr)
- ✅ All color overrides correct
- ✅ Zero compile errors
- ✅ Zero test failures
- ✅ All code review issues fixed
- ✅ No visual regressions

**Test Results:**
- ✅ flutter analyze: PASS (zero errors/warnings)
- ✅ flutter test: 5/5 PASS
- ✅ Code review: APPROVED

---

### Phase 7: Home Dashboard 🔲 PENDING

**Status:** 🔲 Pending
**Duration:** 1.5 hours
**Dependencies:** Phase 6 ✅
**Priority:** P2 - High

**Objectives:**
- Create home dashboard screen
- Display learning statistics
- Show quick action cards
- Implement navigation to features

**Deliverables:**
- [ ] `home_controller.dart` - Home logic
- [ ] `home_binding.dart` - Dependency injection
- [ ] `home_screen.dart` - Dashboard UI
- [ ] Statistics cards widgets
- [ ] Quick action navigation

**Success Criteria:**
- Dashboard displays user stats
- Navigation to chat, lessons, profile works
- Smooth animations and transitions
- Offline stats still visible

**API Endpoints:**
- GET `/progress/stats`
- GET `/user/profile`

---

### Phase 8: Chat Feature 🔲 PENDING

**Status:** 🔲 Pending
**Duration:** 2.5 hours
**Dependencies:** Phase 7
**Priority:** P1 - Critical

**Objectives:**
- Implement AI chat interface
- Add voice input/output support
- Create message persistence
- Build offline message queue

**Deliverables:**
- [ ] `chat_controller.dart` - Chat logic
- [ ] `chat_binding.dart` - Dependency injection
- [ ] `chat_screen.dart` - Chat UI
- [ ] `message_model.dart` - Message data model
- [ ] Message bubble widgets
- [ ] Voice recording button
- [ ] Text-to-speech integration
- [ ] Offline queue implementation

**Success Criteria:**
- Real-time text chat works
- Voice recording and playback functional
- Messages persist locally (Hive)
- Offline messages queue and sync
- Smooth scrolling chat list

**API Endpoints:**
- GET `/chat/messages`
- POST `/chat/send`
- POST `/chat/voice`

---

### Phase 9: Lessons Feature 🔲 PENDING

**Status:** 🔲 Pending
**Duration:** 2 hours
**Dependencies:** Phase 8
**Priority:** P2 - High

**Objectives:**
- Create lesson browser
- Implement lesson detail view
- Add lesson caching (LRU)
- Track lesson progress

**Deliverables:**
- [ ] `lessons_controller.dart` - Lessons logic
- [ ] `lessons_binding.dart` - Dependency injection
- [ ] `lessons_screen.dart` - Lesson browser UI
- [ ] `lesson_detail_screen.dart` - Lesson content view
- [ ] `lesson_model.dart` - Lesson data model
- [ ] LRU cache implementation
- [ ] Progress tracking

**Success Criteria:**
- Users can browse lessons
- Lessons load offline after first access
- LRU eviction when cache exceeds 100MB
- Progress tracked per lesson
- Bookmarking works

**API Endpoints:**
- GET `/lessons`
- GET `/lessons/:id`

---

### Phase 10: Profile & Settings 🔲 PENDING

**Status:** 🔲 Pending
**Duration:** 1.5 hours
**Dependencies:** Phase 9
**Priority:** P3 - Medium

**Objectives:**
- Create user profile screen
- Implement settings page
- Add language preference toggle
- Build logout functionality

**Deliverables:**
- [ ] `profile_controller.dart` - Profile logic
- [ ] `settings_controller.dart` - Settings logic
- [ ] `profile_screen.dart` - Profile UI
- [ ] `settings_screen.dart` - Settings UI
- [ ] Profile edit functionality
- [ ] Language switcher (EN/VI)
- [ ] Logout with token cleanup

**Success Criteria:**
- User can view/edit profile
- Language switching persists
- Settings saved locally
- Logout clears all secure data
- Profile picture support (future)

**API Endpoints:**
- GET `/user/profile`
- PUT `/user/profile`

---

## Milestones

### Milestone 1: Foundation (Phases 1-3) ✅ COMPLETED

**Target:** 2026-02-06
**Status:** 100% Complete
**Completion Date:** 2026-02-05

**Criteria:**
- ✅ Project setup complete
- ✅ Network layer functional
- ✅ Core services operational

---

### Milestone 2: Core Features (Phases 4-5) ✅ COMPLETED

**Target:** 2026-02-07
**Status:** 100% Complete
**Completion Date:** 2026-02-05

**Criteria:**
- ✅ Base classes and widgets ready
- ✅ Routing configured
- ✅ Localization working

---

### Milestone 3: Onboarding & Authentication (Phase 6) ✅ COMPLETED

**Target:** 2026-02-28
**Status:** 100% Complete (Screens 01-14)
**Completion Date:** 2026-02-28

**Criteria:**
- ✅ Splash screen implemented
- ✅ Welcome screens complete (screens 02-04)
- ✅ Language selection screens complete (screens 05-06)
- ✅ AI Chat intro screen (screen 07) - `POST /onboarding/chat`
- ✅ Scenario Gift screen (screen 08) - `POST /onboarding/start`
- ✅ LoginGate bottom sheet (screen 09)
- ✅ Signup screen (screen 10) - `POST /auth/register`
- ✅ Login screen (screen 11) - `POST /auth/login`
- ✅ Forgot password flow (screens 12-14):
  - Email input screen (12)
  - OTP verification with 6-box input (13)
  - New password entry (14)
- ✅ API integration complete (9 endpoints)
- ✅ Language service with caching and offline fallback
- ✅ OTP countdown timer and resend functionality
- ✅ Password validation and reset workflow

---

### Milestone 3.5: Code Quality & Typography ✅ COMPLETED

**Target:** 2026-03-09
**Status:** 100% Complete
**Completion Date:** 2026-03-09

**Criteria:**
- ✅ Text→AppText refactoring complete
- ✅ All 100+ widgets converted
- ✅ Typography system unified
- ✅ Base widget rule documented

---

### Milestone 4: Core Features (Phases 7-8) 🔲 Pending

**Target:** 2026-03-05
**Status:** 0% Complete
**Remaining:** 4 hours

**Criteria:**
- Home dashboard complete
- Chat feature complete

---

### Milestone 5: Learning Features (Phases 9-10) 🔲 Pending

**Target:** 2026-03-12
**Status:** 0% Complete
**Remaining:** 3.5 hours

**Criteria:**
- Lessons feature complete
- Profile and settings complete

---

## Success Metrics

### Phase 1 Metrics ✅

- **Code Quality:** ✅ No compile errors, clean build
- **Test Coverage:** N/A (setup phase)
- **Performance:** ✅ Project compiles in < 30s
- **Documentation:** ✅ All constants documented

### Overall Project Metrics (Target)

- **Code Coverage:** > 70%
- **Build Success Rate:** 100%
- **Average Screen Load:** < 500ms
- **Memory Usage:** < 150MB
- **App Size:** < 50MB

---

## Risks & Mitigation

| Risk | Phase | Impact | Probability | Mitigation |
|------|-------|--------|-------------|------------|
| Token refresh race condition | 2 | High | Medium | Use QueuedInterceptor |
| Hive data corruption | 3 | High | Low | Validation on read, backups |
| Permission denial (audio) | 3 | Medium | Low | Graceful text-only fallback |
| Backend API changes | 6-10 | Medium | Low | Version API, maintain backwards compat |
| Offline sync conflicts | 8-9 | Medium | Medium | Last-write-wins strategy |

---

## Change Log

### 2026-03-09 (Phase 6.7 Complete — Text→AppText Refactoring)

**Phase 6.7 Completion Summary:**
- ✅ **AppText Enhancement:** Added `button` variant and optional override params
- ✅ **Bulk Replacement:** 100+ raw Text widgets converted to AppText across 30 files
- ✅ **Batched Execution:** Shared widgets → Auth → Chat → Onboarding → Other
- ✅ **Quality Gates:** flutter analyze PASS, all tests PASS (5/5)
- ✅ **Code Review:** All issues fixed and approved
- ✅ **Base Widget Rule:** Added to CLAUDE.md for future guidance

**Refactoring Results:**
- ✅ Shared widgets batch: 4 files updated
- ✅ Auth feature batch: 8 files updated
- ✅ Chat feature batch: 9 files updated
- ✅ Onboarding feature batch: 8 files updated
- ✅ Other features batch: 4 files updated
- ✅ Zero breaking changes
- ✅ Zero visual regressions
- ✅ All translations (.tr) preserved
- ✅ All color overrides correct

**Quality Metrics:**
- ✅ Codebase: 100% AppText usage for UI text (except RichText/emoji)
- ✅ Design system: Outfit font enforcement across 100+ widgets
- ✅ Maintainability: Centralized typography control
- ✅ Future-proofing: Pattern established for new widgets

**Next Step:** Implement Phase 7 (Home Dashboard)

---

### 2026-02-28 (Phase 6 Complete — All Onboarding & Auth Screens 01-14)

**Phase 06 Completion Summary:**
- ✅ **Screens 01-06 (First Half):** Splash, welcome, language selection with language API
- ✅ **Screens 07-08 (Phase 02):** AI chat integration + scenario gift
- ✅ **Screens 09-11 (Phase 04):** LoginGate, signup, login with auth endpoints
- ✅ **Screens 12-14 (Phase 06):** Complete forgot password flow

**Language API Integration (Phase 02):**
- ✅ `OnboardingLanguageService` — parallel `GET /languages?type=native|learning`
- ✅ 24-hour cache via `StorageService.preferences`
- ✅ Offline fallback to static lists
- ✅ UUID-based selection tracking
- ✅ Loading skeletons and error states
- ✅ `CachedNetworkImage` with emoji fallback

**AI Chat Integration (Phase 03):**
- ✅ Screen 07: `POST /onboarding/chat` for Flora AI messages
- ✅ Screen 08: `POST /onboarding/start` for scenario generation
- ✅ Streaming response handling
- ✅ Back button cancellation

**Auth Screens (Phase 04):**
- ✅ Screen 09: LoginGate modal bottom sheet
- ✅ Screen 10: Signup with `POST /auth/register`
- ✅ Screen 11: Login with `POST /auth/login`
- ✅ Token storage in `AuthStorage`
- ✅ Persistent `AuthController` for session management

**Forgot Password Flow (Phase 06):**
- ✅ `ForgotPasswordController` — 3-step password reset manager
- ✅ Screen 12: Email input → `POST /auth/forgot-password`
- ✅ Screen 13: OTP verification with:
  - 6-box `OtpInputField` widget
  - Auto-advance on last digit
  - Paste support
  - Backspace deletion
  - 47-second countdown timer
  - Resend button
- ✅ Screen 14: New password → `POST /auth/reset-password`
- ✅ Password validation (8+, uppercase, lowercase, number, special char)

**Models & Routes:**
- ✅ `OnboardingSession`, `OnboardingProfile`, `Scenario`, `AuthResponse`
- ✅ 14 routes configured (splash + 13 onboarding/auth screens)
- ✅ All transitions: rightToLeft 300ms

**API Endpoints (9 total):**
- GET `/languages?type=native|learning`
- GET `/users/me`, PUT `/users/me`
- POST `/onboarding/chat`, POST `/onboarding/start`
- POST `/auth/register`, POST `/auth/login`
- POST `/auth/forgot-password`, POST `/auth/reset-password`

**Files Created:**
- `/lib/features/onboarding/views/` — Screens 01-08
- `/lib/features/auth/views/` — Screens 09-14
- `/lib/features/auth/controllers/forgot_password_controller.dart`
- `/lib/features/auth/widgets/otp_input_field.dart`
- `/lib/features/onboarding/services/onboarding_language_service.dart`

**Next Step:** Implement Phase 7 (Home Dashboard)

### 2026-02-05

**Phase 5 Completed:**
- ✅ Implemented GetX routing with 9 named routes
- ✅ Created route constants (splash, login, register, home, chat, lessons, lessonDetail, profile, settings)
- ✅ Configured route-to-page mapping with rightToLeft transitions (300ms)
- ✅ Set up global dependency injection for 5 core services
- ✅ Created EN/VI translation files with 99 keys each
- ✅ Implemented translation categories (Common, Auth, Home, Chat, Lessons, Profile, Errors)
- ✅ Configured Material3 theme with Orange primary (#FF6B35)
- ✅ Set portrait-only orientation
- ✅ Configured transparent status bar with dark icons
- ✅ Implemented service initialization flow in main.dart
- ✅ All files compile successfully

**Milestone Progress:**
- ✅ Milestone 1 complete (Phases 1-3)
- ✅ Milestone 2 complete (Phases 4-5)
- ✅ 8.5 hours of work completed
- ✅ 47% overall project progress

**Phase 4 Completed:**
- ✅ Implemented BaseController with apiCall wrapper (88 LOC)
- ✅ Created BaseScreen with loading overlay (98 LOC)
- ✅ Built 4 button variants (primary, secondary, outline, text)
- ✅ Implemented AppTextField with password toggle and validation
- ✅ Created 8 text variants (h1-h3, body, button, caption)
- ✅ Added AppIcon with tap handling
- ✅ Built LoadingWidget with animated pulsating glow
- ✅ Created LoadingOverlay to block interaction
- ✅ Implemented AppErrorWidget with retry button
- ✅ Added UserModel with JSON serialization
- ✅ Created ApiErrorModel for error parsing
- ✅ Built validators (email, password, required, minLength)
- ✅ Added extensions (String, DateTime, Duration)
- ✅ All widgets follow design system strictly
- ✅ All files compile successfully

**Phase 2 Completed:**
- ✅ Implemented ApiClient singleton with GET/POST/PUT/DELETE/uploadFile
- ✅ Created ApiResponse wrapper with code/message/data structure
- ✅ Built 8 exception types with DioException mapper
- ✅ Implemented AuthInterceptor with QueuedInterceptor for token refresh
- ✅ Added RetryInterceptor with exponential backoff
- ✅ All network layer files compile successfully

**Phase 3 Completed:**
- ✅ Implemented StorageService with LRU/FIFO eviction (220 LOC)
- ✅ Created AuthStorage for token management (65 LOC)
- ✅ Built ConnectivityService with reactive state (62 LOC)
- ✅ Implemented AudioService with recording/playback (251 LOC)
- ✅ Added error handling to all Hive operations
- ✅ Fixed memory leaks in audio service
- ✅ Added path_provider dependency
- ✅ All services compile without errors

**Milestone Progress:**
- ✅ Milestone 1 complete (Phases 1-3)
- ✅ Milestone 2 complete (Phases 4-5)
- ✅ 8.5 hours of work completed
- ✅ 47% overall project progress

**Next Steps:**
- Begin Phase 6: Authentication Feature
- Target Milestone 3 completion by 2026-02-09

**Phase 1 Completed:**
- ✅ Created complete folder structure (feature-first)
- ✅ Added all required dependencies to pubspec.yaml
- ✅ Configured environment files (.env.dev, .env.prod)
- ✅ Created core constants (colors, typography, endpoints)
- ✅ Implemented EnvConfig for environment management
- ✅ Verified successful compilation

**Dependencies Added:**
- State Management: GetX 4.6.6
- Networking: Dio 5.4.0
- Storage: Hive 2.2.3, hive_flutter 1.1.0
- Audio: record 5.0.4, audioplayers 5.2.1
- Localization: intl 0.19.0
- Environment: flutter_dotenv 5.1.0
- UI: google_fonts 6.1.0, flutter_svg 2.0.9, cached_network_image 3.3.1
- Connectivity: connectivity_plus 6.0.3
- Utils: uuid 4.3.3

**Design Decisions:**
- Primary color: Orange (#FF6B35)
- Typography: Google Fonts Inter (Note: Plan suggests Open Sans, code uses Inter)
- Architecture: Feature-first with GetX
- Offline-first strategy confirmed

---

## Next Steps

**Immediate (Next Session):**
1. Start Phase 7: Home Dashboard
2. Create dashboard UI with user stats
3. Implement quick action cards
4. Set up navigation to chat, lessons, profile
5. Display learning progress

**Short-term (This Week):**
- Complete Phase 7 (Home Dashboard)
- Begin Phase 8 (Chat Feature)
- Reach Milestone 4 by 2026-03-05

**Long-term:**
- Complete all features by 2026-03-12
- Conduct integration testing
- Prepare for deployment

**Completed in Session:**
- ✅ Phase 6: All 14 onboarding/auth screens implemented
- ✅ Forgot password flow with OTP verification
- ✅ Language API integration with caching
- ✅ AI chat intro screen with Flora integration
- ✅ Scenario gift screen generation
- ✅ Authentication endpoints (register, login, password reset)

---

## Notes

- Typography inconsistency: Plan mentions Open Sans but code uses Inter
- Phase 5 completed same day as Phase 4
- All routing using rightToLeft transitions for consistency
- 99 translation keys per language covering all app sections
- Material3 theme enabled for modern UI
- Portrait-only orientation enforced
- Ready to proceed with Phase 6 implementation
