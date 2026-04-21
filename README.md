# Flowering

**AI-powered language learning app with Vietnamese/English support.**

Conversational practice with an AI tutor using text, voice, and grammar feedback. Offline-first architecture ensures learning continues without internet.

## Key Features

- **AI Chat Tutor:** Real-time conversation with Flora (AI tutor) using text or voice
- **Grammar Correction:** Instant feedback on written sentences with explanations
- **Multi-Language Support:** Switch between English and Vietnamese learning paths
- **Text-to-Speech & Voice Input:** Hear AI responses and practice speaking
- **Session Persistence:** Resume conversations after app close/restart
- **Offline Capable:** Access cached lessons and chat history without internet
- **Secure Auth:** Email/password, Google, and Apple Sign-In
- **In-App Purchases:** RevenueCat-powered subscriptions for premium features

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run dev build
flutter run --dart-define=ENV=dev

# Run tests
flutter test

# Static analysis
flutter analyze

# Code generation (Hive adapters)
flutter pub run build_runner build --delete-conflicting-outputs
```

## Tech Stack

- **Framework:** Flutter 3.10.3+
- **State Management:** GetX 4.6.6
- **Networking:** Dio 5.4.0 (with retry, token refresh, interceptors)
- **Storage:** Hive 2.2.3 (cached lessons), flutter_secure_storage (tokens)
- **Audio:** flutter_tts 4.2.5 (TTS), speech_to_text 7.3.0 (STT), record 6.2.0
- **Auth:** Firebase Auth 5.5.2, google_sign_in 6.2.2, sign_in_with_apple 6.1.4
- **Purchases:** purchases_flutter 8.0.0 (RevenueCat)

## Documentation

- **[docs/README.md](./docs/README.md)** — Full documentation index
- **[docs/development-roadmap.md](./docs/development-roadmap.md)** — Project roadmap and progress
- **[docs/system-architecture.md](./docs/system-architecture.md)** — Architecture and technical design
- **[docs/code-standards.md](./docs/code-standards.md)** — Code conventions and patterns
- **[docs/project-changelog.md](./docs/project-changelog.md)** — Detailed change history

## Status

**Phase 6.12 Complete** (April 20, 2026)
- Foundation, auth, chat, TTS/STT, multi-language support
- Critical security/race-condition fixes
- Session rehydration and checkpoint persistence

**Phase 7 In Progress** (50% complete)
- Home dashboard with language switcher

See [docs/development-roadmap.md](./docs/development-roadmap.md) for full timeline.

## Getting Help

1. Check [docs/codebase-quick-start.md](./docs/codebase-quick-start.md) for a 5-minute overview
2. Review [CLAUDE.md](./CLAUDE.md) for architecture principles and workflows
3. Read [docs/system-architecture.md](./docs/system-architecture.md) for design details

---

**Last Updated:** April 20, 2026
