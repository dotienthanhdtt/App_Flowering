# Flowering — Feature Summary

**Last Updated:** March 11, 2026

---

## Done

| Feature | Description |
|---------|-------------|
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
| **Chat UI** | Conversational interface with message bubbles, quick reply buttons, typing indicators, and a progress bar. Makes AI interaction feel natural and guided. |
| **Home Shell** | Bottom navigation with 4 tabs (Chat, Lessons, Vocabulary, Profile) using IndexedStack for instant tab switching. Users can navigate the app's main sections smoothly. |
| **AI Observability** | All AI interactions are traced via Langfuse — tracking costs, latency, and quality. Allows the team to monitor and optimize AI performance and spending. |
| **Subscription Backend** | RevenueCat integration handling in-app purchase webhooks and subscription status. The billing plumbing needed to monetize premium features. |
| **Push Notification Backend** | Firebase FCM device token registration and management. The server-side setup needed to send users reminders and updates. |
| **Email Service** | SMTP-based email delivery for OTP codes and password resets. Users receive timely emails for account recovery. |

---

## In Progress

| Feature | Description |
|---------|-------------|
| **Lessons & Exercises API** | Backend endpoints for creating, reading, and managing lessons and exercises. Without this, the app has no structured learning content to serve. |
| **Social Authentication (Mobile)** | Google Sign-In and Apple Sign-In on the mobile app. Users expect one-tap login with their existing accounts instead of creating yet another password. |
| **Push Notifications (Mobile)** | Wiring Firebase push notifications end-to-end so users actually receive reminders, streaks, and learning prompts on their devices. |
| **Premium Subscription Flow** | Connecting RevenueCat to the mobile app so users can purchase and activate premium plans. Needed to unlock revenue. |
| **Testing Infrastructure** | Building out unit and integration tests for both backend and mobile. Currently at 0% coverage — the safety net needed before launching to real users. |

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

**Overall MVP Progress: ~65%**
**Target Launch: June 2026**
