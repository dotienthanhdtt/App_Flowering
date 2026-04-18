# Flowering — Feature Summary

**Last Updated:** April 15, 2026

---

## Done

| Feature | Description |
|---------|-------------|
| **Onboarding Progress Resume** | Users who close the app during onboarding now resume from their last checkpoint (language selections, active conversation) instead of restarting. Unified `OnboardingProgress` model persists to local storage with schema version safety and legacy migration support. |
| **Onboarding Flow** | New users land on the app with no account needed. They see 3 welcome screens, pick their native and target languages, and receive a personalized learning scenario — removing the friction of forced signup before trying the product. |
| **Anonymous AI Chat** | During onboarding, users can chat with "Flora" (AI tutor) without creating an account. Conversations are limited to 10 turns with a 7-day lifespan, letting users experience the product value before committing. |
| **Email Authentication** | Users can sign up and log in with email/password. Includes input validation and secure token management so returning users can pick up where they left off. |
| **Password Reset** | Users who forget their password go through a 3-step recovery: enter email, verify OTP code, set new password. Solves the common "locked out" problem without requiring support tickets. |
| **AI Translation** | Users can tap any word or sentence to get instant translations powered by AI. Works for both logged-in and anonymous users, helping learners understand unfamiliar words in context. |
| **AI Grammar Correction** | Learners submit sentences and get grammar feedback — what's wrong, why, and how to fix it. Provides the kind of instant correction a human tutor would give. |
| **Multi-Provider AI** | The backend routes AI requests across OpenAI, Anthropic, and Google Gemini. If one provider goes down, traffic shifts to another — ensuring the AI tutor is always available. |
| **Backend Infrastructure** | Full server setup with database (14 tables), authentication guards, standardized API responses, error handling, and rate limiting. The foundation everything else is built on. |
| **Mobile App Architecture** | Feature-organized Flutter app with state management, HTTP networking (auto-retry, token refresh), offline storage, and connectivity monitoring. The shell that all mobile features plug into. |
| **Design System** | Consistent colors, typography (Outfit font), spacing, and reusable components (buttons, text fields, loading states) across the entire app. Users get a polished, cohesive experience. |
| **Localization** | Full English and Vietnamese language support (~130+ translated strings). Users interact with the app in their preferred language. |
| **Chat Cold-Resume & Rehydration** | When returning to an active conversation, the app fetches message history from the server and populates the chat UI. Handles conversation expiry gracefully (404 clears checkpoint and starts fresh). |
| **Chat UI** | Conversational interface with message bubbles, quick reply buttons, typing indicators, and a progress bar. Makes AI interaction feel natural and guided. |
| **Home Shell** | Bottom navigation with 4 tabs (Chat, Lessons, Vocabulary, Profile) using IndexedStack for instant tab switching. Users can navigate the app's main sections smoothly. |
| **AI Observability** | All AI interactions are traced via Langfuse — tracking costs, latency, and quality. Allows the team to monitor and optimize AI performance and spending. |
| **Subscription Backend** | RevenueCat integration handling in-app purchase webhooks and subscription status. The billing plumbing needed to monetize premium features. |
| **Push Notification Backend** | Firebase FCM device token registration and management. The server-side setup needed to send users reminders and updates. |
| **Email Service** | SMTP-based email delivery for OTP codes and password resets. Users receive timely emails for account recovery. |

---

## In Progress

| Feature | % Complete | Description |
|---------|---------|-------------|
| **API JSON Migration** | 100% | ✅ COMPLETED (Mar 28) - All JSON keys migrated from camelCase to snake_case. All 13 model files updated with backward-compatible fallbacks for cached data. |
| **Lessons & Exercises API** | 5% | Backend endpoints for creating, reading, and managing lessons and exercises. Without this, the app has no structured learning content to serve. |
| **Social Authentication (Mobile)** | 15% | Google Sign-In and Apple Sign-In dependencies added. UI integration pending. Users expect one-tap login with their existing accounts instead of creating yet another password. |
| **Push Notifications (Mobile)** | 10% | Firebase integration backend complete. Mobile Firebase SDK wiring pending. Push notifications end-to-end so users receive reminders and updates. |
| **Premium Subscription Flow** | 25% | RevenueCat service created and integrated. Mobile paywall UI and subscription management pending. Needed to unlock revenue. |
| **Testing Infrastructure** | 0% | Building out unit and integration tests for both backend and mobile. Currently at minimal coverage — the safety net needed before launching to real users. |

---

## Todo

| Feature | Description |
|---------|-------------|
| **Exercise Engine** | 6 exercise types (multiple choice, fill-in-blank, listening, speaking, translation, matching) with scoring and answer validation. The core practice mechanic for learning. |
| **Progress Tracking** | Track which lessons users completed, exercise scores, and proficiency level per language. Users need to see their growth to stay motivated. |
| **Progress Tracking UI** | Mobile screens showing completion stats, lesson history, and learning streaks. Without visible progress, users don't feel they're advancing. |
| **Speech Recognition** | Whisper-based speech-to-text so users can practice speaking and get pronunciation feedback. Solves the "I can read but can't speak" problem. |
| **User Profile Screen** | View and edit profile, change languages, see learning stats. Users need a place to manage their account and preferences. |
| **Settings & Preferences** | Notification frequency, language preferences, app settings. Gives users control over their experience. |
| **Offline Lessons** | Download lessons for offline use and sync progress when back online. Essential for users with unreliable internet. |
| **E2E Testing** | End-to-end tests covering critical flows (onboarding, auth, chat). Catches integration bugs before they reach users. |
| **CI/CD Pipeline** | Automated build, test, and deploy pipeline via GitHub Actions. Needed for reliable, repeatable releases. |
| **Staging Environment** | A pre-production environment for testing before going live. Prevents untested code from reaching users. |
| **Beta Launch** | Closed beta with 100 users to collect feedback and find issues before public launch. Real users reveal real problems. |
| **Adaptive Learning** | AI recommends lessons based on user performance and proficiency. Personalizes the learning path so users study what they actually need. |
| **Gamification** | Streaks, badges, leaderboards, daily challenges. Adds motivation mechanics to keep users coming back. |
| **Spaced Repetition** | Flashcard-style review with SM-2 scheduling algorithm. Optimizes memory retention by reviewing at the right intervals. |
| **Social Features** | Friends, shared challenges, competition. Adds community and accountability to learning. |
| **Analytics Dashboard** | User engagement metrics, learning progress charts, revenue tracking. The team needs data to make informed product decisions. |

---

## Progress Summary

**Completed (Done):** 16 features
**In Progress:** 6 features (API migration 100% complete, others ~15% avg)
**Todo:** 13 features

**Overall MVP Progress: ~70%** (increased from 65% due to API migration completion)
**Target Launch: June 2026**
**Latest Milestone:** All API JSON keys migrated to snake_case (March 28, 2026)
