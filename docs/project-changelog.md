# Project Changelog

## Version 1.0.0 - In Development

### [2026-04-06] Audio Architecture Refactor: Monolithic → Provider Pattern ✅ COMPLETED

#### Overview
Replaced the monolithic `AudioService` (283 LOC) with a modular provider-based architecture supporting Text-to-Speech (TTS) and Speech-to-Text (STT) with platform-specific optimizations. New architecture enables TTS auto-play, queue-based message playback, iOS audio recording during STT, and proper audio session conflict prevention.

#### Added
- **Audio Models** (`lib/core/services/audio/models/`)
  - `TtsEvent` — Events from TTS provider (start, complete, cancel, error)
  - `SttResult` — Partial/final transcription from STT provider
  - `VoiceInputResult` — Combined result: transcribed text + audio path (iOS)

- **Audio Contracts** (`lib/core/services/audio/contracts/`)
  - `TtsProviderContract` — Abstract TTS interface (flutter_tts implementation)
  - `SttProviderContract` — Abstract STT interface (speech_to_text implementation)
  - `AudioRecorderProviderContract` — Abstract recorder interface (record package implementation)

- **Audio Providers** (`lib/core/services/audio/providers/`)
  - `FlutterTtsProvider` — Wraps flutter_tts with contract compliance
  - `SpeechToTextProvider` — Wraps speech_to_text with contract compliance
  - `RecordAudioProvider` — Wraps record package with amplitude tracking

- **TtsService** (`lib/core/services/audio/tts-service.dart`)
  - Queue-based message playback (up to 10 pending)
  - Auto-play preference persistence in Hive (`tts_auto_play`)
  - Rate and pitch control with preferences
  - Automatic queue processing on message completion
  - Immediate stop/clear when voice input starts

- **VoiceInputService** (`lib/core/services/audio/voice-input-service.dart`)
  - STT initialization and platform availability checking
  - iOS-specific: simultaneous recording + STT for backend transcription
  - Android-specific: STT only (no recording)
  - 55s timeout (safety margin before Apple's 60s limit)
  - Amplitude tracking and listening duration monitoring
  - Explicit TTS stop before STT start (audio session conflict prevention)

- **New Dependencies**
  - `flutter_tts: ^4.2.5` — Cross-platform TTS engine
  - `speech_to_text: ^7.3.0` — Cross-platform STT engine

#### Changed
- **Audio Service Registration** (`global-dependency-injection-bindings.dart`)
  - Providers registered as contracts before services
  - TtsService and VoiceInputService depend on contracts

#### Removed
- **Monolithic AudioService** (`lib/core/services/audio_service.dart`)
  - Replaced by modular TtsService + VoiceInputService
  - Recording/playback functionality migrated to providers

#### Platform-Specific Behavior

| Feature | iOS | Android |
|---------|-----|---------|
| TTS Engine | flutter_tts | flutter_tts |
| STT Engine | speech_to_text | speech_to_text |
| Audio Recording | YES (during STT) | NO |
| Amplitude Tracking | YES | NO |
| Max Listening Duration | 55s (Apple 60s limit) | 55s |
| Backend Transcription | POST /ai/transcribe + audio file | Text only |

#### Storage Updates
- **New Hive Preferences:**
  - `tts_auto_play` — Boolean; enables auto-play of AI responses
  - `tts_rate` — Double 0.0–2.0; playback speed (default: 0.5)
  - `tts_pitch` — Double 0.0–2.0; voice pitch (default: 1.0)

#### Integration Points
1. **Chat Controller** — Calls `ttsService.speak()` when AI responds (if auto-play enabled)
2. **Chat UI** — Voice input button triggers `voiceInputService.startVoiceInput()`
3. **Settings Screen** — TTS rate/pitch/auto-play toggles (future)
4. **Audio Session Management** — `voiceInputService.startVoiceInput()` auto-stops TTS

#### Breaking Changes
- `AudioService` removed; clients must use `TtsService` and `VoiceInputService` separately
- Recording is now iOS-specific (Android has no recording during STT)
- Audio file paths returned only on iOS via `VoiceInputResult.audioFilePath`

#### Technical Decisions
1. **Provider Pattern:** Enables platform-specific implementations and easy testing via mocks
2. **Queue-Based TTS:** Prevents audio overlaps; respects user preference for auto-play
3. **iOS Recording:** Simultaneous STT + recording for cloud transcription (higher accuracy than device STT)
4. **Timeout Design:** 55s limit prevents exceeding Apple's 60s hard constraint
5. **Audio Session Priority:** TTS explicitly stops before STT to avoid session conflicts

#### Files Created
- `/lib/core/services/audio/models/tts-event.dart`
- `/lib/core/services/audio/models/stt-result.dart`
- `/lib/core/services/audio/models/voice-input-result.dart`
- `/lib/core/services/audio/contracts/tts-provider-contract.dart`
- `/lib/core/services/audio/contracts/stt-provider-contract.dart`
- `/lib/core/services/audio/contracts/audio-recorder-provider-contract.dart`
- `/lib/core/services/audio/providers/flutter-tts-provider.dart`
- `/lib/core/services/audio/providers/speech-to-text-provider.dart`
- `/lib/core/services/audio/providers/record-audio-provider.dart`
- `/lib/core/services/audio/tts-service.dart`
- `/lib/core/services/audio/voice-input-service.dart`

#### Files Deleted
- `/lib/core/services/audio_service.dart`

#### Testing Notes
- TTS initialization tested on iOS and Android simulators
- STT availability varies by platform (iOS: always available, Android: requires Google Speech plugin)
- Recording during STT tested on iOS simulator
- 55s timeout verified with manual timer tests
- Queue-based TTS verified with multiple rapid `speak()` calls

#### Migration Guide
For existing chat features using the old `AudioService`:
```dart
// OLD (removed)
final audioService = Get.find<AudioService>();
await audioService.playFile(path);

// NEW (TtsService for text output)
final ttsService = Get.find<TtsService>();
await ttsService.speak('Hello world');

// NEW (VoiceInputService for voice input)
final voiceInputService = Get.find<VoiceInputService>();
await voiceInputService.startVoiceInput();
final result = await voiceInputService.stopVoiceInput();
final transcribedText = result.transcribedText;
final audioPath = result.audioFilePath;  // iOS only
```

---

### [2026-03-28] API JSON Keys Migration: camelCase → snake_case ✅ COMPLETED

#### Overview
Backend switched all API JSON keys to `snake_case`. Flutter app manual `fromJson`/`toJson` serialization updated to match new contract. All models now parse request/response bodies with snake_case keys. Backward-compatible fallback reads added for cached data during transition.

#### Added
- **Backward compatibility fallbacks** in all models to read old camelCase keys from cached Hive data
- Proper snake_case field mapping across all request payloads

#### Changed
- **UserModel** (`lib/shared/models/user_model.dart`)
  - `displayName` → `name`
  - `avatarUrl` → `profile_picture`
  - Removed: `nativeLanguageId`, `nativeLanguageCode`, `nativeLanguageName`
  - Added: `emailVerified` (bool), `updatedAt` (DateTime)

- **AuthResponse** (`lib/features/auth/models/auth_response.dart`)
  - `accessToken` → `access_token`
  - `refreshToken` → `refresh_token`

- **OnboardingLanguage** (`lib/features/onboarding/models/onboarding_language.dart`)
  - `isNativeAvailable` → `is_active` (native languages)
  - `isLearningAvailable` → `is_active` (learning languages)
  - `flagUrl` → `flag_url`
  - `nativeName` → `native_name`

- **OnboardingSession** (`lib/features/onboarding/models/onboarding_session.dart`)
  - `sessionToken` → `session_id`
  - `turnNumber` → `turn_count`
  - `reply` → `response`
  - Added: `maxTurns` (int), `expiresAt` (DateTime)
  - Kept: `quickReplies` list unchanged

- **OnboardingProfile** (`lib/features/onboarding/models/onboarding_profile.dart`)
  - Removed: `userId`
  - Added: `extractedProfile` (nested object)
  - Kept: `scenarios` list unchanged

- **Scenario** (`lib/features/onboarding/models/scenario.dart`)
  - `accentColor` → `accent_color` (HEX string)
  - `imageUrl` → `image_url`

- **SubscriptionModel** (`lib/features/subscription/models/subscription_model.dart`)
  - `expiresAt` → split into `currentPeriodStart` + `currentPeriodEnd`
  - `isActive` → `is_active`
  - `cancelAtPeriodEnd` → `cancel_at_period_end`

- **WordTranslationModel** (`lib/features/chat/models/word_translation_model.dart`)
  - `partOfSpeech` → `part_of_speech`
  - `vocabularyId` → `vocabulary_id`

- **SentenceTranslationModel** (`lib/features/chat/models/sentence_translation_model.dart`)
  - `messageId` → `message_id`
  - `translation` → `translated_content`

- **Request payloads** updated in:
  - `AuthController` — login, signup, forgot password endpoints
  - `ForgotPasswordController` — OTP and reset endpoints
  - `AiChatController` — chat, translate, correction endpoints
  - `TranslationService` — word/sentence translation requests

#### Phases Completed
1. ✅ **Phase 1 (Complete):** All 9 model files updated with snake_case keys + fallback reads
2. ✅ **Phase 2 (Complete):** All 4 controller/service files updated with snake_case request payloads
3. ✅ **Phase 3 (Complete):** Auth interceptor token handling verified

#### Files Modified (13 total)
- `lib/shared/models/user_model.dart`
- `lib/features/auth/models/auth_response.dart`
- `lib/features/onboarding/models/onboarding_language.dart`
- `lib/features/onboarding/models/onboarding_session.dart`
- `lib/features/onboarding/models/onboarding_profile.dart`
- `lib/features/onboarding/models/scenario.dart`
- `lib/features/subscription/models/subscription_model.dart`
- `lib/features/chat/models/word_translation_model.dart`
- `lib/features/chat/models/sentence_translation_model.dart`
- `lib/features/auth/controllers/auth_controller.dart`
- `lib/features/auth/controllers/forgot_password_controller.dart`
- `lib/features/chat/controllers/ai_chat_controller.dart`
- `lib/shared/services/translation_service.dart`

#### Breaking Changes
- **API Contract:** All JSON keys now use `snake_case`. Update backend responses before deploying this app version.
- **Cache Impact:** Old camelCase cached data will be read using fallback keys; no manual cache clear required.
- **Onboarding:** Field names in OnboardingSession changed (`sessionToken`→`session_id`, `reply`→`response`). Ensure backend sends correct field names.

#### Backward Compatibility
- Models gracefully fall back to reading old camelCase keys from Hive cache
- Supports mixed old/new key formats during transition period
- Recommended: Clear app cache on first launch of new version (optional)

#### Testing
- All models tested with both old (camelCase) and new (snake_case) JSON
- Request payload validation confirmed in staging environment
- Auth token flow (access_token/refresh_token) verified

---

### [2026-03-23] AI Chat Screen UI Redesign (Screens 08A-08E) ✅ COMPLETED

#### Added
- **Chat Context Card** (`lib/features/chat/widgets/chat-context-card.dart`)
  - New widget displaying scenario context at top of chat area
  - Orange/warning background with message-circle icon
  - Integrated in AiChatScreen when contextDescription exists

#### Changed
- **ChatTopBar** (`lib/features/chat/widgets/chat_top_bar.dart`)
  - Replaced onboarding-style (logo+progress+skip) with conversation-style design
  - Back arrow + centered title + optional more icon (for 08E)
  - 1px divider below in `infoColor`
  - New constructor: `title`, `onBack`, `showMoreButton`, `onMore`

- **GrammarCorrectionSection** (`lib/features/chat/widgets/grammar_correction_section.dart`)
  - Redesigned from embedded-in-bubble to standalone card
  - Red border (1px `errorColor`), white background, sparkles icon
  - "Try this instead:" header with corrected text below
  - Removed toggle UI (now always visible when present)

- **ChatTextInputField** (`lib/features/chat/widgets/chat_text_input_field.dart`)
  - Placeholder color: changed to `infoColor` (#9CB0CF)
  - Input text size: 16px (`fontSizeMedium`)

- **AiMessageBubble** (`lib/features/chat/widgets/ai_message_bubble.dart`)
  - Removed "Flora" label and AI avatar widget
  - Updated card shadow: blur 4, #0000001A, offset y:1
  - Moved action buttons (Translate/Play) outside card with pill-shaped backgrounds
  - Translation section integrated inside card with divider (for 08D)

- **TextActionButton** (`lib/features/chat/widgets/text_action_button.dart`)
  - Added `hasPillBackground` parameter for pill-shaped chip variant
  - Pill variant has beige background, subtle shadow, 8px border radius

- **UserMessageBubble** (`lib/features/chat/widgets/user_message_bubble.dart`)
  - Color changed: orange (`primaryColor`) → blue (`secondaryColor`)
  - Border radius: 12px all corners (was mixed)
  - Removed embedded `GrammarCorrectionSection`
  - Removed `onToggleCorrection` callback

- **ChatRecordingBar** (`lib/features/chat/widgets/chat_recording_bar.dart`)
  - Cancel/send button sizes increased: 36px → 48px circles

- **ChatWaveformBars** (`lib/features/chat/widgets/chat_waveform_bars.dart`)
  - Bar count increased: 20 → 39 bars
  - Gap between bars: 2px
  - Height range: 6-26px

- **WordTranslationSheet** (`lib/shared/widgets/word-translation-sheet.dart`)
  - Added "Save to My Words" button at bottom (52px height, outlined, bookmark icon)
  - Handle pill width: 40 → 36px
  - Added `onSave` callback parameter

- **WordTranslationSheetLoader** (`lib/shared/widgets/word-translation-sheet-loader.dart`)
  - Now forwards `onSave` callback to `WordTranslationSheet`

- **AiChatController** (`lib/features/chat/controllers/ai_chat_controller.dart`)
  - Added `chatTitle` observable (read from route args)
  - Added `contextDescription` observable (read from route args)
  - Added `saveWord()` stub method for vocabulary integration

- **AiChatScreen** (`lib/features/chat/views/ai_chat_screen.dart`)
  - Grammar correction now renders as separate item below user message (right-aligned)
  - Context card renders above chat list when contextDescription is not empty
  - ChatTopBar now receives `title` from controller instead of progress data
  - Integrated all Phase 01-03 widget updates

#### Added Translation Keys
- `chat_try_instead` - "Try this instead:" (EN: "Try this instead:", VI: "Thu lai cau nay:")
- `chat_save_to_words` - "Save to My Words" (EN: "Save to My Words", VI: "Luu vao tu vung")

#### Phases Completed
1. ✅ **Phase 01:** Top bar, grammar correction, input widgets — 7/7 todo items
2. ✅ **Phase 02:** Message bubbles, recording bar — 6/6 todo items
3. ✅ **Phase 03:** Bottom sheet, context card, screen integration — 9/9 todo items

#### Files Modified
- `lib/features/chat/widgets/chat_top_bar.dart` - Full rewrite for conversation style
- `lib/features/chat/widgets/grammar_correction_section.dart` - Red border card design
- `lib/features/chat/widgets/chat_text_input_field.dart` - Color and size tweaks
- `lib/features/chat/widgets/ai_message_bubble.dart` - Removed Flora, updated shadow, actions below
- `lib/features/chat/widgets/user_message_bubble.dart` - Blue color, 12px radius
- `lib/features/chat/widgets/text_action_button.dart` - Added pill background option
- `lib/features/chat/widgets/chat_recording_bar.dart` - 48px buttons
- `lib/features/chat/widgets/chat_waveform_bars.dart` - 39 bars, 2px gap
- `lib/shared/widgets/word-translation-sheet.dart` - Save button, handle resize
- `lib/shared/widgets/word-translation-sheet-loader.dart` - Forward onSave callback
- `lib/features/chat/controllers/ai_chat_controller.dart` - Chat title, context, saveWord()
- `lib/features/chat/views/ai_chat_screen.dart` - Integrate all changes, grammar correction rendering
- `lib/l10n/english-translations-en-us.dart` - Added chat_try_instead, chat_save_to_words
- `lib/l10n/vietnamese-translations-vi-vn.dart` - Added chat_try_instead, chat_save_to_words

#### Files Created
- `lib/features/chat/widgets/chat-context-card.dart` - Scenario context card widget

#### Technical Decisions
- **Grammar Correction Placement:** Rendered below user bubble as separate item (not inside) for cleaner UI separation
- **Context Card:** Only shown when contextDescription observable is not empty
- **Pill Buttons:** Reused TextActionButton with `hasPillBackground` parameter (no new widget)
- **Backward Compatibility:** WordTranslationSheet's `onSave` callback is optional (nullable)
- **Title Management:** ChatTopBar now reads from controller observable instead of route params

#### Quality Assurance
- ✅ All 3 phases completed: 22 todo items checked
- ✅ `flutter analyze` passes — 0 errors, 0 new warnings
- ✅ All widget files under 200 lines
- ✅ Screens compile without errors
- ✅ Visual QA against Pencil design screens 08A-08E verified
- ✅ Grammar correction properly separated from user bubble
- ✅ Context card renders when scenario description exists
- ✅ Recording bar buttons sized to 48px
- ✅ Waveform bars increased to 39 with 2px gaps
- ✅ Save button integrated into bottom sheet

#### Design Alignment
- ✅ Top bar: 56px height, back arrow (24px), centered title (20px w600)
- ✅ Grammar correction: Red border (1px errorColor), white bg, sparkles icon
- ✅ User bubble: Blue (#0077BA secondaryColor), 12px all corners, 18px white text
- ✅ AI bubble: White card, shadow blur 4, action pills below with 8px radius
- ✅ Recording bar: 48px cancel/send circles, 39 waveform bars with 2px gaps
- ✅ Context card: Orange bg, message-circle icon, scenario text
- ✅ Bottom sheet: Save button (52px height, outlined, bookmark icon)

#### Success Metrics Met
- ✅ 3 phases completed on schedule (260323 plan)
- ✅ All 22 implementation todo items completed
- ✅ Zero compile errors
- ✅ All widget redesigns match Pencil screens 08A-08E
- ✅ Grammar correction successfully separated from user bubble
- ✅ Context card functional when contextDescription provided
- ✅ Recording bar UI enhanced with larger buttons and more bars
- ✅ Bottom sheet save button integrated with callback support
- ✅ Full translation coverage (EN + VI)

---

### [2026-03-10] Base Class Inheritance Enforcement ✅ COMPLETED

#### Changed
- **All 6 feature controllers** migrated from `GetxController` to `BaseController`:
  - `MainShellController`, `SplashController`, `OnboardingController` (simple — no conflicts)
  - `AuthController`, `ForgotPasswordController`, `AiChatController` (removed duplicate `isLoading`/`errorMessage` fields)

- **10 screens** migrated from `StatelessWidget` to `BaseScreen<T>`:
  - Auth: `LoginEmailScreen`, `SignupEmailScreen`, `ForgotPasswordScreen`, `NewPasswordScreen`, `OtpVerificationScreen`
  - Chat: `AiChatScreen`
  - Onboarding: `SplashScreen`, `NativeLanguageScreen`, `LearningLanguageScreen`, `ScenarioGiftScreen`
  - Home: `MainShellScreen`

- **5 screens documented as exempt** with explanatory comments:
  - Tab children (nested Scaffold risk): `VocabularyScreen`, `ProfileScreen`, `ChatHomeScreen`, `ReadScreen`
  - StatefulWidget (needs State lifecycle): `WelcomeProblemScreen`

- **CLAUDE.md** — Added "Base Class Inheritance (Mandatory)" rules section and BaseController enforcement note
- **docs/code-standards.md** — Updated controller and view standards to show BaseController/BaseScreen patterns
- **docs/system-architecture.md** — Updated presentation layer to document base class requirements
- **docs/codebase-summary.md** — Updated base class status from "pending" to "enforced"

#### Technical Decisions
- **Inline loading preferred:** All migrated screens set `showLoadingOverlay => false` because they handle loading UI inline (spinners in buttons)
- **No behavior change:** Removing duplicate `isLoading`/`errorMessage` fields works because views already reference `controller.isLoading` which now resolves to BaseController's inherited field (same type: `RxBool`/`RxString`)
- **Tab children exempt:** Using BaseScreen would create nested Scaffolds since MainShellScreen already wraps them in a Scaffold

#### Quality Assurance
- ✅ `flutter analyze` passes — 0 errors, 0 new warnings
- ✅ Zero controllers extend `GetxController` directly in `features/*/controllers/`
- ✅ All non-exempt screens extend `BaseScreen<T>`
- ✅ Exempt screens have explanatory doc comments

---

### [2026-03-10] Chat Grammar Correction Feature ✅ COMPLETED

#### Added
- **Grammar Correction API Integration** (`lib/core/constants/api_endpoints.dart`)
  - `POST /ai/correct` - New endpoint for grammar checking

- **ChatMessage Model Enhancement** (`lib/features/chat/models/chat_message_model.dart`)
  - `correctedText` field - Stores corrected version of message
  - `showCorrection` field - Reactive toggle for showing/hiding correction

- **Grammar Correction UI Component** (`lib/features/chat/widgets/grammar_correction_section.dart`)
  - New widget displaying grammar corrections inside user message bubble
  - Shows suggested corrections with visual highlighting
  - Matches design system aesthetic

- **User Message Bubble Enhancement** (`lib/features/chat/widgets/user_message_bubble.dart`)
  - Integrated grammar correction section
  - Toggle button to show/hide corrections
  - Smooth animation transitions

- **Controller Logic** (`lib/features/chat/controllers/ai_chat_controller.dart`)
  - Parallel grammar check API call on every user message
  - Automatic error handling (doesn't break chat flow)
  - Loading state management for correction UI

- **Screen Integration** (`lib/features/chat/views/ai_chat_screen.dart`)
  - Message object passed to bubbles with correction data
  - Callback handler for correction toggle events

- **Localization** (EN & VI)
  - `grammar_correction_label` - "Grammar Correction" label
  - `grammar_corrections` - Plural form
  - `show_correction` - "Show Correction" button text
  - `hide_correction` - "Hide Correction" button text
  - Added to both `english-translations-en-us.dart` and `vietnamese-translations-vi-vn.dart`

#### Key Features
- ✅ Parallel API call: Grammar check runs alongside main chat request
- ✅ Non-blocking: Correction failures don't interrupt chat functionality
- ✅ User-controlled: Toggle button lets users show/hide suggestions
- ✅ Integrated UI: Correction displays inside user bubble matching design
- ✅ Localized: Full EN/VI translation support

#### Files Modified
- `lib/features/chat/models/chat_message_model.dart` - Added correction fields
- `lib/core/constants/api_endpoints.dart` - Added chatCorrect endpoint
- `lib/features/chat/controllers/ai_chat_controller.dart` - Added parallel correction logic
- `lib/features/chat/widgets/user_message_bubble.dart` - Integrated correction section
- `lib/features/chat/widgets/grammar_correction_section.dart` (NEW)
- `lib/features/chat/views/ai_chat_screen.dart` - Wired up message + callback
- `lib/l10n/english-translations-en-us.dart` - Added EN keys
- `lib/l10n/vietnamese-translations-vi-vn.dart` - Added VI keys

#### Technical Decisions
- **Parallel Calls:** Grammar check doesn't wait for main chat response (improves UX)
- **Error Resilience:** Correction failure logged but doesn't propagate to user
- **UI Pattern:** Toggle in bubble keeps UI clean and user-controlled
- **Data Model:** Immutable fields with reactive `showCorrection` for state management

#### Quality Assurance
- ✅ No compile errors
- ✅ App runs normally with grammar corrections active
- ✅ Corrections display correctly when returned from API
- ✅ Toggle functionality works smoothly
- ✅ Graceful handling of API failures

#### Success Metrics Met
- ✅ Correction API called in parallel with chat API on every user message
- ✅ Correction UI appears inside user bubble when errors found
- ✅ No visual change when no errors detected
- ✅ Hide/Show toggle works correctly
- ✅ Correction failures don't break chat flow
- ✅ Zero compile errors, app runs normally

---

### [2026-02-28] Phase 6: Onboarding Feature (First Half) ✅ COMPLETED

#### Added
- **Onboarding Feature** (`lib/features/onboarding/`)
  - `bindings/onboarding_binding.dart` - Dependency injection setup
  - `controllers/onboarding_controller.dart` - State and screen navigation management
  - `models/onboarding_model.dart` - Data structure for onboarding state
  - `views/splash_screen.dart` - Loading screen shown on app startup
  - `views/onboarding_welcome_1/2/3_screen.dart` - 3 welcome screens (3 features per screen)
  - `views/onboarding_language_1/2_screen.dart` - Native and target language selection screens
  - Feature-specific widgets and animations

- **Routes Configuration**
  - `/splash` - Splash screen (now initial route)
  - `/onboarding-welcome-1`, `/onboarding-welcome-2`, `/onboarding-welcome-3`
  - `/onboarding-language-1`, `/onboarding-language-2`
  - 5 new routes with rightToLeft transitions (300ms)

- **API Integration**
  - `GET /users/me` - Fetch current user profile data
  - `PUT /users/me` - Update user profile (language preferences, display name)

#### Changed
- **UserModel** (`lib/shared/models/user_model.dart`)
  - Renamed `name` → `displayName`
  - Renamed `nativeLanguage` → `nativeLanguageId`, `nativeLanguageCode`, `nativeLanguageName`
  - Renamed `targetLanguage` → `targetLanguageId`, `targetLanguageCode`, `targetLanguageName`
  - Updated JSON serialization to use camelCase field names
  - Added copyWith method support for all new fields

- **API Endpoints** (`lib/core/constants/api_endpoints.dart`)
  - Added `userMe` constant for GET /users/me
  - Added `updateUserMe` constant for PUT /users/me

- **Configuration** (`.env.dev`)
  - Updated API_BASE_URL from previous value to `https://dev.broduck.me`

- **Routing** (`lib/app/routes/app-route-constants.dart`)
  - Changed initial route from `/login` to `/splash`
  - Added 5 onboarding route constants

- **Global Bindings** (`lib/app/global-dependency-injection-bindings.dart`)
  - Added `SplashBinding` for splash screen
  - Added `OnboardingBinding` for onboarding feature

#### Technical Decisions
- **Onboarding Flow:** Splash → Welcome (3 screens) → Language Selection (2 screens) → Login
- **Language Selection:** Two-step process (native language first, then target language)
- **API Integration:** Onboarding controller syncs selections with backend via /users/me PUT
- **UserModel Changes:** JSON field names use camelCase to match backend API contract
- **Route Management:** Initial route is splash to allow app initialization before user login

#### Build Verification
- ✅ All onboarding screens compile without errors
- ✅ Navigation flow works smoothly between screens
- ✅ API endpoints properly configured
- ✅ UserModel serialization updated and tested
- ✅ No breaking changes to existing code

#### Success Metrics Met
- ✅ Onboarding screens render without UI errors
- ✅ Splash screen shows during app initialization
- ✅ Welcome screens display feature highlights
- ✅ Language selection persists to backend
- ✅ All route transitions are smooth (rightToLeft 300ms)
- ✅ UserModel correctly serializes/deserializes new fields

---

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

### [2026-03-09] Text→AppText Refactoring: Unified Typography System ✅ COMPLETED

#### Added
- **Base Widget Rule** (CLAUDE.md)
  - Documented requirement to use `AppText` instead of raw `Text` widgets
  - Extends to `AppButton` and `AppTextField` for consistency
  - Ensures all future text rendering uses design system

#### Changed
- **AppText Widget** (`lib/shared/widgets/app_text.dart`)
  - Added `button` variant to `AppTextVariant` enum
  - Added optional override parameters: `fontWeight`, `fontSize`, `style`, `decoration`, `fontStyle`, `height`
  - Updated build logic to merge overrides correctly
  - Maintains backward compatibility with existing usages

- **Text Widget Replacement** (30 files across codebase)
  - 100+ raw `Text(` widgets replaced with `AppText(`
  - Affected files:
    - Shared widgets (4 files): app_button, app_text_field, word-translation-sheet, loading_widget
    - Auth feature (8 files): All auth screens and widgets
    - Chat feature (9 files): All chat screens, bubbles, and widgets
    - Onboarding feature (8 files): All onboarding screens
    - Other features (4 files): Profile, vocabulary, home, lessons
  - All `.tr` translation calls preserved
  - All color overrides correctly applied

#### Technical Decisions
- **Selective Replacement:** Intentionally skipped:
  - `Text` inside `RichText`/`SelectableText` children (TextSpan usage)
  - Emoji-only Text widgets (flag emojis in `_LanguageFlag`) - no Outfit font needed
  - `Text` inside `AppText.build()` itself
- **Style Merging:** Used variant + override approach for flexibility without bloating enum
- **Import Consistency:** All relative imports updated per project convention
- **Backward Compatibility:** All new params optional, existing code unaffected

#### Quality Assurance
- ✅ `flutter analyze` passes with zero errors/warnings
- ✅ All tests passing (5/5)
- ✅ Code review complete - all issues fixed:
  - Style merge logic corrected
  - Logout button color fixed
  - Semantic variant applied correctly
  - Unused GoogleFonts import removed
- ✅ No visual regressions detected
- ✅ All typography consistent across app

#### Files Modified
- `lib/shared/widgets/app_text.dart` - Enhanced with new params
- 30 feature and shared widget files - Text→AppText replacement
- `CLAUDE.md` - Added base widget rule
- Multiple auth, chat, onboarding, and profile files

#### Success Metrics Met
- ✅ Consistent Outfit font usage enforced across 100+ text widgets
- ✅ Centralized typography control via AppText variants
- ✅ Design system compliance improved
- ✅ Future text widgets guided toward base widget pattern
- ✅ Codebase maintainability improved

#### Build Verification
- ✅ All modified files compile without errors
- ✅ No new warnings introduced
- ✅ Test suite passes (5/5)
- ✅ Code review approved
- ✅ No breaking changes to existing functionality

---

### [2026-03-08] Native Splash Screen Logo Polish ✅ COMPLETED

#### Added
- **Android Native Splash Logo**
  - Added app logo to `launch_background.xml` using density-specific `splash_logo.png` drawables
  - Density variants: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
  - Centered logo display via `android:gravity="center"`

- **iOS Native Splash Logo**
  - Replaced generic LaunchImage assets with app logo at proper scales (180x180)
  - Fixed storyboard centering with proper constraints:
    - `centerX` and `centerY` constraints ensure centered logo
    - LaunchScreen.storyboard properly configured with LaunchImage

- **Flutter Text Animation**
  - Added TweenAnimationBuilder for "Flowering" text and tagline
  - 600ms fade-in animation with easeIn curve
  - Text opacity transitions from 0.0 → 1.0

#### Changed
- **SplashScreen Widget** (`lib/features/onboarding/views/splash_screen.dart`)
  - Logo now displays with app name and tagline
  - Added animated text fade-in effect during app initialization
  - Maintained existing primary color background

#### Technical Decisions
- **Platform-specific Assets:** Native splash uses density-specific Android drawables and iOS LaunchImage for proper scaling across devices
- **Animation Timing:** 600ms fade-in chosen to match typical app initialization duration
- **UI Consistency:** App logo and colors unified across native splash and Flutter UI

#### Build Verification
- ✅ Android native splash renders with centered logo
- ✅ iOS storyboard displays centered LaunchImage with proper constraints
- ✅ Flutter SplashScreen animation compiles without errors
- ✅ No breaking changes to existing flows

#### Success Metrics Met
- ✅ Native splash screens display app logo professionally
- ✅ Logo centered on both Android and iOS platforms
- ✅ Text animation provides visual polish during initialization
- ✅ Loading experience improved with branded native splash

---

### [2026-03-04] Bottom Navigation Bar Feature ✅ COMPLETED

#### Added
- **Bottom Navigation Bar Widget** (`lib/shared/widgets/bottom-nav-bar.dart`)
  - 4-tab navigation (Chat, Read, Vocabulary, Profile)
  - Custom styling matching Pencil design system
  - Active/inactive tab color states (#FF7A27 orange active, #9C9585 gray inactive)
  - 80px fixed height with 20px corner radius
  - Integrated with MainShellScreen for tab switching

- **MainShellScreen** (`lib/features/home/views/main-shell-screen.dart`)
  - App shell containing bottom navigation
  - IndexedStack-based page switching
  - Maintains controller state across tab switches
  - Routes to 4 main screens: ChatHomeScreen, ReadScreen, VocabularyScreen, ProfileScreen

- **Navigation Tab Screens**
  - `lib/features/chat/views/chat-home-screen.dart` - Chat home screen (placeholder)
  - `lib/features/read/views/read-screen.dart` - Reading feature (placeholder)
  - `lib/features/vocabulary/views/vocabulary-screen.dart` - Vocabulary management (placeholder)
  - `lib/features/profile/views/profile-screen.dart` - User profile (placeholder)

- **Vocabulary Feature Directory** (`lib/features/vocabulary/`)
  - New feature module with bindings, controllers, views, and widgets
  - Structure ready for vocabulary browser and management functionality

- **Translation Keys** (EN & VI)
  - `nav_chat` - Chat tab label
  - `nav_read` - Read tab label
  - `nav_vocabulary` - Vocabulary tab label
  - `nav_profile` - Profile tab label

- **Dependencies Added**
  - `lucide_icons ^0.x.x` - Modern icon library for bottom nav icons

#### Changed
- **Routes Configuration** (`lib/app/routes/app-page-definitions-with-transitions.dart`)
  - New home route (`/home`) → MainShellScreen (replaces previous home implementation)
  - Previous auth flow routes remain unchanged

- **Feature Directory Structure**
  - Created new directories for Read, Chat, and Vocabulary features
  - Maintained existing Profile feature

#### Technical Decisions
- **Bottom Nav Structure:** Custom widget for design consistency over built-in BottomNavigationBar
- **Page Management:** IndexedStack for efficient tab switching without rebuilding screens
- **Color Scheme:** Orange (#FF7A27) for active tabs per Pencil design system
- **Icon Library:** lucide_icons for modern, consistent iconography
- **Placeholder Screens:** Basic screens created to allow navigation testing before feature implementation

#### Build Verification
- ✅ All new widgets compile without errors
- ✅ MainShellScreen integrates with existing routing
- ✅ IndexedStack page switching functional
- ✅ Bottom navigation styling matches Pencil design
- ✅ All translation keys properly mapped
- ✅ No breaking changes to existing authentication flow

#### Success Metrics Met
- ✅ Bottom navigation renders with correct 4-tab layout
- ✅ Tab switching works smoothly without memory leaks
- ✅ Active/inactive states display with correct colors
- ✅ Navigation bar maintains consistent height (80px) and corner radius (20px)
- ✅ Integration with existing app routing verified
- ✅ Localization keys for all navigation labels (EN & VI)

---

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

### [2026-03-08] Chat Translate Feature ✅ COMPLETED

#### Added
- **Word Translation Models** (`lib/shared/models/`)
  - `WordTranslationModel` - Single word translation with transliterations
  - `SentenceTranslationModel` - Sentence-level translation with word-by-word mapping

- **Translation Service** (`lib/core/services/translation_service.dart`)
  - `toggleTranslation()` - Async fetch/cache word translations
  - Caches translations in StorageService (LRU eviction)
  - Handles translation errors gracefully

- **Word Translation UI Widgets** (`lib/shared/widgets/`)
  - `WordTranslationSheet` - Bottom sheet displaying translation details
  - `WordTranslationSheetLoader` - Loading state with skeleton
  - Displays translated text with phonetic pronunciation

- **Message Interactivity**
  - `ChatMessage` model: added `backendMessageId`, mutable `translatedText` fields
  - `AiMessageBubble`: added `onWordTap` callback for tap handling
  - Integrated `AppTappablePhrase` widget for interactive word highlighting

- **API Integration**
  - `POST /ai/translate` - Backend endpoint for word translation
  - Request: `{messageId, word}` → Response: `{translations, phoneticSimilar, phoneticOriginal}`

- **Localization Keys** (EN & VI)
  - Translation sheet labels and buttons
  - Loading states and error messages

#### Changed
- **AppTappablePhrase Widget** (`lib/shared/widgets/app_tappable_phrase.dart`)
  - Converted from StatelessWidget to StatefulWidget
  - Fixes memory leak in gesture detector
  - Maintains proper lifecycle cleanup

- **ChatMessage Model** (`lib/shared/models/chat_message_model.dart`)
  - Added `backendMessageId` field (UUID from API)
  - Added `translatedText` (mutable) for caching translations

- **AiMessageBubble Widget** (`lib/features/chat/widgets/ai_message_bubble.dart`)
  - Added `onWordTap` callback parameter
  - Integrated `AppTappablePhrase` with translation callback

- **AiChatController** (`lib/features/chat/controllers/ai_chat_controller.dart`)
  - Added `onWordTap(word)` handler
  - Added `toggleTranslation(word, messageId)` async method
  - Manages translation loading/error states

#### Technical Decisions
- **Translation Caching:** Uses existing StorageService to cache frequent translations (reduces API calls)
- **Lazy Loading:** Translations fetched on-demand when user taps word
- **Memory Safety:** AppTappablePhrase fixed to use StatefulWidget for proper cleanup
- **Backend Integration:** Leverages new POST /ai/translate endpoint
- **UX Pattern:** Bottom sheet provides immersive translation detail view

#### Build Verification
- ✅ New models compile without errors
- ✅ TranslationService integrates with StorageService
- ✅ Word translation sheet renders without UI issues
- ✅ AppTappablePhrase memory leak fixed (StatefulWidget lifecycle)
- ✅ ChatMessage serialization handles new fields
- ✅ AiMessageBubble tap handling functional
- ✅ No breaking changes to existing chat flow

#### Success Metrics Met
- ✅ Users can tap words in AI messages to see translations
- ✅ Translations display with phonetic information
- ✅ Translation data cached to reduce API load
- ✅ Memory leak fixed in AppTappablePhrase
- ✅ All new l10n keys added for EN and VI

---

### Upcoming Phases (7-10)

**Phase 7: Home Dashboard**
- Learning statistics and progress display
- Quick action cards
- Recent activity feed
- Integration with backend progress API

**Phase 8: Expanded Chat Feature**
- Full chat interface with message history
- Voice input/output integration
- Message persistence
- Offline message queue

**Phase 9: Lessons & Content**
- Lessons browser with categories
- Offline content caching
- Lesson completion tracking
- Vocabulary management

**Phase 10: Profile & Settings**
- User profile page
- App settings and preferences
- Account management
- Language/theme preferences
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

### [2026-03-13] Phase 3: RevenueCat Service ✅ COMPLETED

#### Added
- **RevenueCat Subscription Integration**
  - `lib/features/subscription/services/revenuecat-service.dart` - Thin SDK wrapper (88 LOC)
  - Service initialization with platform-specific API keys (iOS/Android)
  - User identification methods: `logIn(userId)`, `logOut()`
  - Purchase flow: `getOfferings()`, `purchasePackage()`
  - Purchase restoration: `restorePurchases()`
  - Subscription state: `getCustomerInfo()` with `customerInfoStream`
  - Graceful degradation when API keys are missing

- **Subscription Feature Structure**
  - Created `lib/features/subscription/` directory structure
  - Planned subscription models and services for Phase 4

#### Technical Decisions
- **Thin Wrapper Pattern:** RevenueCatService handles only SDK calls, no business logic
- **Platform-Specific Keys:** Supports iOS (App Store) and Android (Google Play) separately
- **Stream-Based Updates:** CustomerInfo stream for reactive subscription state changes
- **Error Propagation:** PlatformExceptions propagated to callers for proper UX handling
- **Graceful Failure:** Missing API keys don't crash the app, service disabled gracefully

#### Security & Configuration
- API keys loaded from environment config (EnvConfig)
- Debug logging only in development mode
- No hardcoded credentials in code
- Platform-specific security handled by RevenueCat SDK

#### Build Verification
- ✅ Service compiles without errors
- ✅ No circular dependencies
- ✅ Proper resource cleanup (stream disposal)
- ✅ flutter analyze passes

#### Dependencies
- `purchases_flutter ^8.11.0` - RevenueCat SDK
- Requires `revenueCatAppleApiKey` and `revenueCatGoogleApiKey` in `.env.dev`/`.env.prod`

---

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
