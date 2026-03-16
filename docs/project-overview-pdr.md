# Flowering - AI Language Learning App

## Product Overview

Flowering is a Flutter-based AI-powered language learning application focused on Vietnamese/English language pairs. The app provides interactive chat-based learning with voice and text support, offline capabilities, and personalized lesson tracking.

## Product Requirements Document (PRD)

### 1. Vision & Objectives

**Vision:** Enable natural language acquisition through AI-powered conversational practice with seamless offline support.

**Objectives:**
- Provide real-time AI chat tutor for language practice
- Support both voice and text interactions
- Enable offline lesson access and progress sync
- Track learning progress with detailed analytics
- Support Vietnamese/English language pairs

### 2. User Personas

**Primary Persona: The Busy Professional**
- Age: 25-45
- Goal: Learn English/Vietnamese for career advancement
- Needs: Flexible learning schedule, mobile-first, offline access
- Pain Points: Limited time, inconsistent internet connectivity

**Secondary Persona: The Student**
- Age: 18-25
- Goal: Improve language skills for academic purposes
- Needs: Structured lessons, progress tracking, interactive practice
- Pain Points: Need for immediate feedback, engagement

### 3. Functional Requirements

#### 3.1 Authentication & User Management
- User registration with email/password
- Secure login with JWT token authentication
- Token refresh mechanism for session persistence
- User profile management
- Logout functionality

#### 3.2 AI Chat Feature
- Real-time text chat with AI tutor
- Voice input support with speech-to-text
- Text-to-speech for AI responses
- Message history persistence
- Offline message queue with sync

#### 3.3 Lessons & Learning
- Browse available lessons by category/level
- Access lesson content offline
- Track lesson completion status
- Save lesson progress locally
- Bookmark favorite lessons

#### 3.4 Progress Tracking
- Daily/weekly/monthly statistics
- Learning streaks and achievements
- Time spent learning analytics
- Vocabulary mastery tracking
- Performance metrics visualization

#### 3.5 Settings & Preferences
- Language preference (EN/VI)
- Audio settings (voice speed, volume)
- Notification preferences
- Account settings
- Privacy controls

### 4. Non-Functional Requirements

#### 4.1 Performance
- App launch time < 2 seconds
- Chat message response time < 500ms (online)
- Smooth 60fps UI animations
- Memory usage < 150MB during normal operation

#### 4.2 Offline Capabilities
- Full lesson access offline (up to 100MB cached)
- Chat message queue when offline
- Automatic sync when connection restored
- Progress tracking without internet

#### 4.3 Security
- Secure token storage using Hive (AuthStorage)
- HTTPS-only API communication
- No sensitive data in plain Hive storage (tokens separated in AuthStorage)
- Token expiration and refresh handling

#### 4.4 Scalability
- Support up to 10,000 cached messages
- Handle 100MB lesson cache
- LRU cache eviction for lessons
- FIFO cache for chat messages

#### 4.5 Accessibility
- Screen reader support
- Minimum touch target size 44x44
- High contrast mode support
- Text scaling support

### 5. Technical Constraints

- **Platform:** Flutter 3.10.3+
- **State Management:** GetX 4.6.6+
- **Networking:** Dio 5.4.0+
- **Storage:** Hive 2.2.3+ for all data (cache and tokens via AuthStorage)
- **Audio:** record 5.0.4+, audioplayers 5.2.1+
- **Minimum Android:** API 21 (Android 5.0)
- **Minimum iOS:** iOS 12.0

### 6. Success Metrics

#### User Engagement
- Daily Active Users (DAU) growth
- Average session duration > 10 minutes
- Chat messages per session > 5
- Lesson completion rate > 60%

#### Performance Metrics
- App crash rate < 0.5%
- API success rate > 99%
- Offline mode usage > 30%
- User retention rate (7-day) > 40%

#### Business Metrics
- User registration rate
- User satisfaction score > 4.0/5.0
- Feature adoption rates
- Time to value < 5 minutes

### 7. Out of Scope (v1.0)

- Multi-language support beyond EN/VI
- Social features (friend lists, leaderboards)
- In-app purchases or subscriptions
- Video lessons or live tutoring
- Gamification elements
- Community forums

### 8. Dependencies & Integrations

#### External APIs
- Backend API for authentication, chat, lessons, progress
- Speech-to-text service (platform-dependent)
- Text-to-speech service (platform-dependent)

#### Third-party Services
- Google Fonts for typography
- Cached Network Image for image optimization
- Connectivity Plus for network status

### 9. Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Backend API downtime | High | Medium | Offline-first architecture, message queue |
| Audio permission denial | Medium | Low | Graceful fallback to text-only mode |
| Hive data corruption | High | Low | Regular backups, data validation |
| Token expiration issues | Medium | Medium | Robust refresh mechanism, error handling |
| Memory leaks | High | Medium | Proper disposal, GetX SmartManagement |

### 10. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-11 | Onboarding & Auth complete, chat with grammar correction, bottom nav, typography system |

### 11. Acceptance Criteria

**Phase 1-4 (Setup & Infrastructure) - COMPLETED:**
- ✅ Project structure created
- ✅ Dependencies installed
- ✅ Environment configuration
- ✅ Network layer with error handling (ApiClient, interceptors, exceptions)
- ✅ Core services (StorageService, AuthStorage, AudioService, ConnectivityService)
- ✅ Base classes enforced (BaseController, BaseScreen)
- ✅ Shared widgets library (AppButton, AppTextField, AppText, etc.)
- ✅ App compiles successfully

**Phase 5-6 (User Acquisition & Chat) - COMPLETED:**
- ✅ Routing and localization (99+ translation keys, 16 routes)
- ✅ Onboarding flow (8 screens: splash, welcome, language selection, AI chat, scenario)
- ✅ Authentication (login, signup, forgot password, OTP, password reset)
- ✅ Bottom navigation (4 tabs: chat, read, vocabulary, profile)
- ✅ Chat feature with grammar correction and translation

**Phase 7-10 (Future Features):**
- Home dashboard with learning stats
- Expanded chat features and message history
- Lessons browser with offline caching
- Profile and settings screens
- Comprehensive testing (target >70% coverage)
