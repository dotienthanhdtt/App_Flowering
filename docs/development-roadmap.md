# Development Roadmap

## Project Information

**Project:** Flowering - AI Language Learning App
**Framework:** Flutter 3.10.3+
**Architecture:** Feature-first with GetX
**Start Date:** 2026-02-05
**Current Status Date:** 2026-04-20
**Completion Estimate:** Phases 1-6.12 complete, Phase 7 in progress (~50%), Phases 8-10 pending

## Roadmap Overview

```
Phase 1: Setup ████████████ 100% (1h) ✅ COMPLETED 2026-02-05
Phase 2: Network ████████████ 100% (2h) ✅ COMPLETED 2026-02-05
Phase 3: Services ████████████ 100% (2h) ✅ COMPLETED 2026-02-06
Phase 4: Base/Widgets ████████████ 100% (2h) ✅ COMPLETED 2026-02-07
Phase 5: Routes/i18n ████████████ 100% (1.5h) ✅ COMPLETED 2026-02-09
Phase 6: Onboarding & Auth ████████████ 100% (6h) ✅ COMPLETED 2026-03-11
Phase 6.5: Bottom Navigation ████████████ 100% (1h) ✅ COMPLETED 2026-03-13
Phase 6.7: Text→AppText Refactor ████████████ 100% (3h) ✅ COMPLETED 2026-03-18
Phase 6.8: API JSON Migration ████████████ 100% (2h) ✅ COMPLETED 2026-03-28
Phase 6.9: Audio Architecture (TTS/STT) ████████████ 100% (1.5h) ✅ COMPLETED 2026-04-06
Phase 6.10: Onboarding Progress Resume ████████████ 100% (2h) ✅ COMPLETED 2026-04-15
Phase 6.11: Multi-Language Adaptation ████████████ 100% (1.5h) ✅ COMPLETED 2026-04-19
Phase 6.12: Critical Fixes (auth, casing, cache, controller, Firebase) ████████████ 100% (18h) ✅ COMPLETED 2026-04-19
Phase 7: Home Dashboard ██████░░░░░░ 50% (1.5h) 🔄 In Progress ~2026-04-25
Phase 8: Chat ░░░░░░░░░░░░ 0% (2.5h) 🔲 Pending ~2026-05-01
Phase 9: Lessons ░░░░░░░░░░░░ 0% (2h) 🔲 Pending ~2026-05-10
Phase 10: Profile/Settings ░░░░░░░░░░░░ 0% (1.5h) 🔲 Pending ~2026-05-20
```

**Overall Progress:** 100% of foundation + onboarding + auth + audio + persistence + multi-language + critical fixes (Phases 1-6.12 complete); Phase 7 50% complete (home language switcher UI + session rehydration)
**Completed:** 47 hours of implementation (setup, network, services, base classes, routing, i18n, 8 onboarding screens, 5 auth screens, bottom nav, API migration, TTS/STT architecture, onboarding progress resume, multi-language context + interceptors + cache invalidation, 7 critical bug fixes, home language button/picker widgets, session rehydration)
**Remaining:** Complete Phase 7 home dashboard polish, expanded chat, lessons, profile/settings (~7.5 hours estimated)

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

### Phase 6.8: Chat Grammar Correction ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 1 hour
**Completion Date:** 2026-03-10
**Dependencies:** Phase 6 ✅
**Priority:** P2 - High (Chat enhancement)

**Deliverables:**
- ✅ `grammar_correction_section.dart` - New widget for displaying corrections (NEW)
- ✅ `chat_message_model.dart` - Enhanced with `correctedText`, `showCorrection` fields
- ✅ `api_endpoints.dart` - Added `chatCorrect` endpoint constant
- ✅ `ai_chat_controller.dart` - Parallel grammar check logic with error handling
- ✅ `user_message_bubble.dart` - Integrated correction section with toggle button
- ✅ `ai_chat_screen.dart` - Wired up message object and correction callback
- ✅ `english-translations-en-us.dart` - Added 4 translation keys
- ✅ `vietnamese-translations-vi-vn.dart` - Added 4 translation keys

**Key Achievements:**
- Implemented parallel API call: grammar check runs alongside main chat request
- Non-blocking error handling: correction failure doesn't interrupt chat flow
- User-controlled UI: toggle button in bubble shows/hides suggestions
- Integrated design: correction displays inside user bubble matching design system
- Full localization: EN and VI translations for all new UI text

**API Integration:**
- `POST /ai/correct` - Grammar correction endpoint
- Called in parallel with chat message send
- Automatic error handling with graceful fallback

**Files Created:**
- `/lib/features/chat/widgets/grammar_correction_section.dart` (NEW)

**Files Modified:**
- `/lib/features/chat/models/chat_message_model.dart`
- `/lib/core/constants/api_endpoints.dart`
- `/lib/features/chat/controllers/ai_chat_controller.dart`
- `/lib/features/chat/widgets/user_message_bubble.dart`
- `/lib/features/chat/views/ai_chat_screen.dart`
- `/lib/l10n/english-translations-en-us.dart`
- `/lib/l10n/vietnamese-translations-vi-vn.dart`

**Technical Decisions:**
- **Parallel Calls:** Grammar check doesn't block chat send (improves UX)
- **Error Resilience:** API failure logged but doesn't propagate to user
- **UI Pattern:** Toggle in bubble keeps interface clean and user-controlled
- **Data Model:** Immutable message fields + reactive `showCorrection` for state

**Success Criteria Met:**
- ✅ Correction API called in parallel on every user message
- ✅ Correction UI shows in bubble only when errors found
- ✅ No visual change when no corrections needed
- ✅ Hide/Show toggle works smoothly
- ✅ API failures don't break chat functionality
- ✅ Zero compile errors
- ✅ App runs normally with feature active

---

### Phase 6.9: Audio Architecture (TTS & STT) ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 1.5 hours
**Completion Date:** 2026-04-06
**Dependencies:** Phase 3 (StorageService) ✅
**Priority:** P1 - Critical (Chat voice I/O)

**Deliverables:**
- ✅ Abstract provider pattern (contracts) for TTS, STT, audio recording
- ✅ `flutter_tts` provider implementation (`FlutterTtsProvider`)
- ✅ `speech_to_text` provider implementation (`SpeechToTextProvider`)
- ✅ `record` package provider implementation (`RecordAudioProvider`)
- ✅ `TtsService` (GetxService) with queue-based auto-play
- ✅ `VoiceInputService` (GetxService) with platform-aware recording + STT
- ✅ Data models: `TtsEvent`, `SttResult`, `VoiceInputResult`
- ✅ Global dependency injection for all audio services
- ✅ New dependencies: `flutter_tts: ^4.2.5`, `speech_to_text: ^7.3.0`

**Key Achievements:**
- Replaced monolithic `AudioService` (283 LOC) with modular provider pattern
- Implemented TTS auto-play with user preference persistence
- Platform-specific STT: iOS records audio for backend transcription, Android STT only
- Audio session conflict prevention: TTS auto-stops before STT starts
- 55s timeout on STT (safety margin before Apple's 60s limit)
- Amplitude tracking and duration monitoring for voice input
- Queue-based TTS with up to 10 pending messages

**Architecture:**
```
lib/core/services/audio/
├── models/
│   ├── tts-event.dart
│   ├── stt-result.dart
│   └── voice-input-result.dart
├── contracts/
│   ├── tts-provider-contract.dart
│   ├── stt-provider-contract.dart
│   └── audio-recorder-provider-contract.dart
├── providers/
│   ├── flutter-tts-provider.dart
│   ├── speech-to-text-provider.dart
│   └── record-audio-provider.dart
├── tts-service.dart
└── voice-input-service.dart
```

**TtsService Observable State:**
```dart
final isSpeaking = false.obs;
final currentText = ''.obs;
```

**Key Methods:**
- `speak(String text, {String? language})` — Queue message for playback
- `stopForVoiceInput()` — Stop TTS and clear queue (for voice input priority)
- `setAutoPlay(bool value)` — Enable/disable auto-play for AI responses
- `setRate(double rate)`, `setPitch(double pitch)` — Playback controls

**VoiceInputService Observable State:**
```dart
final isListening = false.obs;
final partialText = ''.obs;
final amplitude = 0.0.obs;
final sttAvailable = false.obs;
final listeningDuration = Duration.zero.obs;
```

**Key Methods:**
- `startVoiceInput({String? language})` — Start STT, optionally record (iOS)
- `stopVoiceInput()` → VoiceInputResult — Stop STT, return transcribed text + audio path

**Platform Differences:**

| Feature | iOS | Android |
|---------|-----|---------|
| STT | ✅ Yes | ✅ Yes |
| Recording during STT | ✅ Yes | ❌ No |
| Timeout | 55s (Apple 60s limit) | 55s |
| Backend transcription | POST /ai/transcribe with audio file | Text only |

**Preferences Stored (Hive):**
- `tts_auto_play` — Boolean (default: false)
- `tts_rate` — Double 0.0–2.0 (default: 0.5)
- `tts_pitch` — Double 0.0–2.0 (default: 1.0)

**Files Created:**
- `/lib/core/services/audio/models/` - 3 model files (TtsEvent, SttResult, VoiceInputResult)
- `/lib/core/services/audio/contracts/` - 3 contract files (TtsProviderContract, SttProviderContract, AudioRecorderProviderContract)
- `/lib/core/services/audio/providers/` - 3 provider files (FlutterTtsProvider, SpeechToTextProvider, RecordAudioProvider)
- `/lib/core/services/audio/tts-service.dart` - TtsService
- `/lib/core/services/audio/voice-input-service.dart` - VoiceInputService

**Files Deleted:**
- `/lib/core/services/audio_service.dart` (monolithic, replaced by modular pattern)

**Dependencies Added:**
- `flutter_tts: ^4.2.5`
- `speech_to_text: ^7.3.0`

**Global Dependency Injection:**
```dart
Get.lazyPut<TtsProviderContract>(() => FlutterTtsProvider());
Get.lazyPut<SttProviderContract>(() => SpeechToTextProvider());
Get.lazyPut<AudioRecorderProviderContract>(() => RecordAudioProvider());
Get.lazyPut(() => TtsService());
Get.lazyPut(() => VoiceInputService());
```

**Initialization Order:**
1. Audio providers (contracts)
2. TtsService (initializes provider, loads preferences)
3. VoiceInputService (initializes providers)

**Technical Decisions:**
- **Provider Pattern:** Contracts enable platform-specific implementations and testing
- **Queue-Based TTS:** Prevents rapid audio playback overlaps; user preference persisted
- **iOS Recording:** Simultaneous STT + recording for backend cloud transcription (higher accuracy)
- **Timeout Design:** 55s safety margin before Apple's 60s hard limit
- **Audio Session:** Explicit stop of TTS before STT to prevent session conflicts

**Integration Points:**
- Chat controller: `ttsService.speak()` when AI response arrives (if auto-play enabled)
- Chat UI: Voice input button calls `voiceInputService.startVoiceInput()` and `stopVoiceInput()`
- Settings screen: TTS rate/pitch/auto-play toggles

**Success Criteria Met:**
- ✅ TTS service queues and plays messages sequentially
- ✅ STT initializes correctly on both platforms
- ✅ iOS records audio while listening to STT
- ✅ TTS stops before STT starts (no audio session conflicts)
- ✅ 55s timeout prevents exceeding Apple limits
- ✅ Preferences persist across app sessions
- ✅ All files compile without errors
- ✅ Services register correctly in GetX

---

### Phase 6.10: Onboarding Progress Resume ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 2 hours
**Completion Date:** 2026-04-15
**Dependencies:** Phase 3 (StorageService), Phase 6.6 (Chat), Phase 6.9 (Audio) ✅
**Priority:** P1 - Critical (UX polish, session persistence)

**Overview:**
Users who close the app during onboarding now resume from their last checkpoint (language selections, active conversation) instead of restarting from the welcome screen. Unified `OnboardingProgress` model persists to local storage with schema version safety, graceful degradation, and legacy migration support.

**Deliverables:**
- ✅ `OnboardingProgress` model with schema versioning and JSON round-trip
- ✅ `OnboardingProgressService` with unified read/write API
- ✅ Legacy migration: `onboarding_conversation_id` → `chat.conversation_id`
- ✅ `SplashController.computeOnboardingResumeTarget()` with priority routing
- ✅ Chat cold-resume via `AiChatController._bootstrapSession()`
- ✅ `ChatMessage.fromServerJson()` factory for rehydration
- ✅ `GET /onboarding/conversations/{id}/messages` endpoint integration
- ✅ `StorageService.setHasCompletedLogin()` flag for returning users
- ✅ Global DI registration with proper init order

**Architecture:**
```
lib/features/onboarding/
├── models/
│   └── onboarding_progress_model.dart        (OnboardingProgress, LangCheckpoint, ChatCheckpoint)
└── services/
    └── onboarding_progress_service.dart      (read/write, legacy migration)

lib/features/chat/
└── models/
    └── chat_message_model.dart               (fromServerJson factory)

lib/core/constants/
└── api_endpoints.dart                        (onboardingConversationMessages endpoint)

lib/app/
└── global-dependency-injection-bindings.dart (OnboardingProgressService DI + init)
```

**Storage Schema:**
- **Hive Box:** `preferences`
- **Key:** `onboarding_progress`
- **Value:** JSON string (schema-versioned for future evolution)
- **Fields Tracked:** `native_lang{code,id}`, `learning_lang{code,id}`, `chat{conversation_id}`, `profileComplete`, `updated_at`

**Resume Priority (SplashController):**
```
1. If profileComplete → route to scenario-gift
2. Else if chat checkpoint → route to chat (rehydrate from backend)
3. Else if learningLang → route to chat (empty session)
4. Else if nativeLang → route to learning-language picker
5. Else → route to welcome screen
```

**Chat Cold-Resume Flow:**
1. AiChatController init calls `_bootstrapSession()`
2. Check `OnboardingProgressService.read().chat` for prior conversation
3. If exists: call `GET /onboarding/conversations/{id}/messages`
4. If 404: conversation expired → clear checkpoint, start fresh
5. If 2xx: populate chat UI with rehydrated messages
6. If error: show retryable error, user can create new session

**Key Methods:**
```dart
// OnboardingProgressService
OnboardingProgress read()
Future<void> setNativeLang(String code, {String? id})
Future<void> setLearningLang(String code, {String? id})
Future<void> setChatConversationId(String conversationId)
Future<void> setProfileComplete(bool complete)
Future<void> clearChat()  // Clear only chat, keep languages
Future<void> clearAll()   // Full reset

// StorageService
bool get hasCompletedLogin  // Never cleared, survives logout
Future<void> setHasCompletedLogin()

// SplashController (exported for testing)
String computeOnboardingResumeTarget(OnboardingProgress p)
```

**Dependency Injection Order (initializeServices):**
1. AuthStorage → init()
2. StorageService → init()
3. OnboardingProgressService → init() [runs legacy migration]
4. ConnectivityService → init()
5. Audio providers, TtsService, VoiceInputService → init()
6. ApiClient → init()
7. RevenueCat, Subscription services → init()

**Migration Logic:**
- Detects old `onboarding_conversation_id` preference (from prior implementation)
- Auto-converts to `chat.conversation_id` in unified progress on first service init
- Old key deleted after migration; never checked again
- Graceful: if conversion fails, user restarts from beginning (no crash)

**Error Handling:**
- JSON corruption: return empty progress (safe degradation)
- Missing key: return empty progress (first-time user)
- Unknown schema version: return empty progress (forward-compatible)
- Backend 404: clear chat checkpoint, offer fresh session
- Backend network error: show retryable error

**Tests:**
- `test/features/onboarding/onboarding_progress_model_test.dart` — model serialization, schema versioning
- `test/features/onboarding/splash_controller_resume_test.dart` — routing priority, login state logic
- `test/features/onboarding/onboarding_progress_service_test.dart` — read/write ops, migration, error resilience
- `test/features/chat/chat_message_server_parse_test.dart` — rehydration message parsing (snake_case + camelCase)
- `test/features/chat/ai_chat_binding_cold_resume_test.dart` — cold-resume dependency chain

**Files Created:**
- `lib/features/onboarding/models/onboarding_progress_model.dart`
- `lib/features/onboarding/services/onboarding_progress_service.dart`
- 5 test files (model, service, splash routing, chat parsing, bindings)

**Files Modified:**
- `lib/app/global-dependency-injection-bindings.dart` — DI registration, init order
- `lib/core/services/storage_service.dart` — `hasCompletedLogin` flag
- `lib/core/constants/api_endpoints.dart` — new endpoint
- `lib/features/chat/controllers/ai_chat_controller.dart` — cold-resume bootstrap
- `lib/features/chat/models/chat_message_model.dart` — server JSON factory
- `lib/features/chat/bindings/ai_chat_binding.dart` — delegate to OnboardingBinding
- `lib/features/onboarding/controllers/splash_controller.dart` — resume routing
- `lib/features/auth/controllers/auth_controller.dart` — post-login flag

**Technical Decisions:**
1. **JSON Storage (not Typed Hive Object):** Enables schema evolution without code-gen recompilation
2. **Schema Version Guard:** Unknown versions degrade gracefully (return empty, no crash)
3. **Synchronous Reads:** Hive is in-memory; no delay on hot-resume paths
4. **Permanent `hasCompletedLogin` Flag:** Survives logout so re-login doesn't re-onboard
5. **Unified Progress Map:** Single source of truth vs scattered preferences

**Success Criteria Met:**
- ✅ Users resume from last checkpoint after app restart
- ✅ Language selections persisted and recovered
- ✅ Active chat conversation rehydrated from backend
- ✅ Conversation expiry (404) handled gracefully
- ✅ Legacy migration runs automatically
- ✅ No breaking changes; fully backward compatible
- ✅ Schema versioning prevents crashes on future changes
- ✅ All files compile without errors
- ✅ Services init in correct dependency order

---

### Phase 6.11: Multi-Language Adaptation ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 1.5 hours
**Completion Date:** 2026-04-19
**Dependencies:** Phase 6.10 ✅
**Priority:** P1 - Critical

**Overview:**
Multi-language adaptation infrastructure enabling users to learn multiple languages simultaneously. Introduces language context as single source of truth, automatic cache invalidation per language, and intelligent header injection for API partitioning.

**Deliverables:**
- ✅ `LanguageContextService` — Persisted active language (code + UUID) with reactive observables
- ✅ `CacheInvalidatorService` — Automatic cache flush on language switch + one-time migration
- ✅ `ActiveLanguageInterceptor` — Attaches `X-Learning-Language` header to content requests
- ✅ `LanguageRecoveryInterceptor` — Handles 403 "not enrolled" with one-shot resync+retry
- ✅ `StorageService.preferenceKeysMatching()` — Bulk-clear language-scoped preferences
- ✅ `LanguageContextError` enum in api_exceptions.dart for 403 language-specific errors
- ✅ Updated DI order: LanguageContextService init before ApiClient
- ✅ Controller integration: chat, onboarding, profile delegate to service

**Key Achievements:**
- Language context persists across sessions (Hive storage)
- Caches automatically clear on language switch (lessons, chat, progress, attempts)
- Interceptors transparently attach language header to backend requests
- 403 "not enrolled" automatically triggers resync + single retry
- Migration safe: one-time flush flag prevents repeated migrations
- Zero breaking changes to existing controllers
- All files compile without errors

**Files Created:**
- `/lib/core/services/language-context-service.dart` (50 LOC)
- `/lib/core/services/cache-invalidator-service.dart` (50 LOC)
- `/lib/core/network/active-language-interceptor.dart` (45 LOC)
- `/lib/core/network/language-recovery-interceptor.dart` (50 LOC)

**Files Modified:**
- `lib/core/services/storage_service.dart` (2 methods added)
- `lib/core/network/api_client.dart` (interceptor chain reordered)
- `lib/core/network/api_exceptions.dart` (new error enum + helper)
- `lib/app/global-dependency-injection-bindings.dart` (DI + init order)
- Feature controllers: onboarding, chat, profile

**Success Criteria Met:**
- ✅ LanguageContextService load/save via Hive
- ✅ CacheInvalidatorService react to language changes via worker
- ✅ ActiveLanguageInterceptor injects header on content requests
- ✅ LanguageRecoveryInterceptor resync + retry on 403
- ✅ StorageService bulk-clear preferences by pattern
- ✅ DI order prevents interceptor access to uninitialized service
- ✅ All controllers compile and function normally

**Integration Points:**
- Onboarding: language selection flows to active context
- Chat: reads active language for message context
- Profile: clears context on logout
- API: all content requests include language header
- Backend: partitions data by language code

---

### Phase 6.12: Critical Fixes (Auth Race, Casing, Cache, Controller, Firebase) ✅ COMPLETED

**Status:** ✅ Completed
**Duration:** 18 hours
**Completion Date:** 2026-04-19
**Dependencies:** Phase 6.11 ✅
**Priority:** P0 - Critical

**Overview:**
7 critical bug fixes addressing security, race conditions, API contract mismatches, cache safety, controller lifecycle, and security leaks. All fixes required for production readiness of feat/update-onboarding branch.

**Deliverables:**

1. **C6: AuthInterceptor Double-Refresh Race** ✅
   - Issue: Concurrent 401 responses → simultaneous refresh attempts → token corruption
   - Fix: Added `Completer` gate preventing concurrent refresh, ensures single refresh call
   - Impact: Eliminates race condition in token refresh flow

2. **C1: Payload Casing (snake_case)** ✅
   - Issue: Callers sending camelCase payload to snake_case backend endpoint (`/onboarding/complete`)
   - Fix: Updated `ai_chat_controller.dart` + `auth_controller.dart` to send snake_case request bodies
   - Impact: Fixes API contract mismatch, ensures backend receives correct field names

3. **C2+C3: LanguageRecoveryInterceptor Retry Mechanism** ✅
   - Issue: Naive retry loop in interceptor → HTTP exception re-thrown instead of being handled
   - Fix: Created shared `retryDio` instance, converted to `QueuedInterceptor`, added `Completer` gate
   - Impact: Prevents concurrent retry attempts, ensures language resync on 403 "not enrolled"

4. **C4+C5a: Per-Language Cache Scoping + Seeded Race Fix** ✅
   - Issue: Language switch → cache flush lost user's baseline code, race condition on seed
   - Fix: Scoped cache invalidation (clear only affected language keys), added Hive transaction + lock
   - Impact: Preserves baseline across language switches, prevents seeded code corruption

5. **C5: OnboardingController Lifecycle** ✅
   - Issue: Permanent controller lifetime → logic runs on every route transition, state leaks
   - Fix: Converted to route-scoped binding (removed `permanent: true`)
   - Impact: Controller init/destroy tied to screen lifecycle, prevents accidental re-execution

6. **C9: Firebase Error Message Leak** ✅
   - Issue: Firebase auth errors (PlatformException messages) leaked to user, exposing internals
   - Fix: Added `mapFirebaseAuthErrorCode()` utility mapping platform exceptions → user-safe messages
   - Impact: Prevents information disclosure, improves user experience with friendly error text

**Files Modified:**
- `lib/core/network/auth_interceptor.dart` — Completer gate for double-refresh prevention
- `lib/features/chat/controllers/ai_chat_controller.dart` — snake_case payloads, C9 error mapping
- `lib/features/auth/controllers/auth_controller.dart` — snake_case payloads, C9 error mapping
- `lib/core/network/language_recovery_interceptor.dart` — QueuedInterceptor + shared retryDio + Completer gate
- `lib/core/services/storage_service.dart` — Per-language cache scoping via `preferenceKeysMatching()`
- `lib/core/services/cache_invalidator_service.dart` — Scoped flush + migration flag
- `lib/features/onboarding/bindings/onboarding_binding.dart` — Removed `permanent: true`
- `lib/core/utils/firebase_error_mapper.dart` — New utility for safe error messages

**Success Criteria Met:**
- ✅ Concurrent 401 responses don't trigger multiple refresh calls
- ✅ Requests sent with correct snake_case payloads
- ✅ 403 language errors automatically retry with resync
- ✅ Language switches preserve user baseline code
- ✅ Baseline seeding race condition eliminated
- ✅ OnboardingController destroys when screen pops
- ✅ Firebase errors mapped to user-safe messages
- ✅ All files compile without errors
- ✅ flutter analyze clean
- ✅ flutter test green (all existing + new tests)

**Quality Assurance:**
- ✅ Code review complete (all 7 critical issues addressed)
- ✅ Test coverage for all fixes implemented
- ✅ No regression in onboarding happy-path
- ✅ Concurrent/edge case scenarios covered
- ✅ Security implications reviewed

---

### Phase 7: Home Dashboard 🔲 PENDING

**Status:** 🔲 Pending
**Duration:** 1.5 hours
**Dependencies:** Phase 6.11 ✅
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

### 2026-03-10 (Phase 6.8 Complete — Chat Grammar Correction Feature)

**Phase 6.8 Completion Summary:**
- ✅ **Grammar Correction Widget:** New `grammar_correction_section.dart` displays corrections in user bubble
- ✅ **Model Enhancement:** Added `correctedText` and `showCorrection` fields to ChatMessage
- ✅ **API Integration:** `POST /ai/correct` endpoint integrated with parallel call logic
- ✅ **Controller Logic:** Async grammar check with automatic error handling
- ✅ **UI Toggle:** Show/hide button for corrections in user message bubble
- ✅ **Full Localization:** EN and VI translation keys added (4 keys each)

**Feature Details:**
- Grammar check runs in parallel with main chat send (non-blocking)
- Corrections display only if errors found (no visual noise)
- User can toggle visibility with button in message bubble
- API failure gracefully handled (doesn't interrupt chat)
- All UI elements integrated into existing design system

**Files Created:**
- `/lib/features/chat/widgets/grammar_correction_section.dart`

**Files Modified:**
- Chat model, endpoints, controller, widgets, screen
- Both EN and VI translation files

**Quality Metrics:**
- ✅ Zero compile errors
- ✅ App runs normally
- ✅ Feature fully tested and functional
- ✅ All acceptance criteria met

**Next Step:** Implement Phase 7 (Home Dashboard)

---

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
