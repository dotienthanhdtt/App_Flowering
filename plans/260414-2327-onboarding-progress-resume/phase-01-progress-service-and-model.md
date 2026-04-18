# Phase 01 — Progress Service & Model

## Context Links
- Brainstorm: `plans/reports/brainstorm-260414-2327-onboarding-progress-resume.md`
- Existing storage: `lib/core/services/storage_service.dart` (preferences Hive box)

## Overview
- **Priority:** High (foundation for all later phases)
- **Status:** completed (2026-04-15)
- Create the typed helper (`OnboardingProgressService`) and lightweight JSON model that all writes/reads funnel through. Single source of truth for progress state.

## Key Insights
- Use existing `preferences` Hive box — do NOT open a new box.
- Value stored as JSON-encoded String for forward-compat with nested fields.
- Schema version field (`_v: 1`) added now to avoid migration pain later.
- Service is pure Dart + `StorageService` dependency; no Get-reactive state (consumers are controllers that already have `.obs`).

## Requirements
**Functional**
- Read full progress map.
- Write individual checkpoint: `setNativeLang`, `setLearningLang`, `setChatConversationId`, `setProfileComplete`.
- Read individual checkpoints with typed getters.
- Clear all (admin / debug only; NOT called on auto-flow).
- JSON corruption → return empty progress, log warning. No crash.

**Non-functional**
- Synchronous reads (Hive preferences are in-memory after init).
- Writes are async (Hive `put`); controllers `await` them.

## Architecture

```
OnboardingProgressService
  ├── _storage: StorageService  (injected via Get)
  ├── Key: 'onboarding_progress'
  └── Value: JSON string of Map<String, dynamic>
        {
          "_v": 1,
          "native_lang": {"code": "vi", "id": "uuid"},
          "learning_lang": {"code": "en", "id": "uuid"},
          "chat": {"conversation_id": "uuid"},
          "profile_complete": true,
          "updated_at": "2026-04-14T23:27:00Z"
        }
```

## Related Code Files
**Create:**
- `lib/features/onboarding/services/onboarding_progress_service.dart` (~120 LOC)
- `lib/features/onboarding/models/onboarding_progress_model.dart` (~80 LOC)

**Read for context:**
- `lib/core/services/storage_service.dart`
- `lib/core/services/auth_storage.dart` (pattern reference)

## Implementation Steps

1. **Create model** `onboarding_progress_model.dart`:
   ```dart
   class OnboardingProgress {
     static const int schemaVersion = 1;
     final LangCheckpoint? nativeLang;
     final LangCheckpoint? learningLang;
     final ChatCheckpoint? chat;
     final bool profileComplete;
     final DateTime? updatedAt;

     const OnboardingProgress({this.nativeLang, this.learningLang, this.chat,
                               this.profileComplete = false, this.updatedAt});

     factory OnboardingProgress.empty() => const OnboardingProgress();
     factory OnboardingProgress.fromJson(Map<String, dynamic> json) { ... }
     Map<String, dynamic> toJson() { ... }
     OnboardingProgress copyWith({...}) { ... }
   }

   class LangCheckpoint { final String code; final String? id; ... }
   class ChatCheckpoint { final String conversationId; ... }
   ```

2. **Create service** `onboarding_progress_service.dart`:
   ```dart
   class OnboardingProgressService extends GetxService {
     static const _key = 'onboarding_progress';
     final StorageService _storage = Get.find();

     OnboardingProgress read() {
       final raw = _storage.getPreference<String>(_key);
       if (raw == null) return OnboardingProgress.empty();
       try {
         return OnboardingProgress.fromJson(jsonDecode(raw));
       } catch (e) {
         // Corrupted — return empty, don't crash
         return OnboardingProgress.empty();
       }
     }

     Future<void> setNativeLang(String code, {String? id}) async {
       final next = read().copyWith(
         nativeLang: LangCheckpoint(code: code, id: id),
         updatedAt: DateTime.now(),
       );
       await _write(next);
     }
     // ... similar for setLearningLang, setChatConversationId, setProfileComplete
     // ... clearChat() for expired-conversation recovery
     Future<void> clearAll() async => _storage.removePreference(_key);

     Future<void> _write(OnboardingProgress p) async =>
         _storage.setPreference(_key, jsonEncode(p.toJson()));
   }
   ```

3. **Register** in `lib/app/global-dependency-injection-bindings.dart` as permanent Get service (after `StorageService`):
   ```dart
   Get.put<OnboardingProgressService>(OnboardingProgressService(), permanent: true);
   ```

4. **Compile check:** `flutter analyze lib/features/onboarding/services/onboarding_progress_service.dart lib/features/onboarding/models/onboarding_progress_model.dart`

## Todo List
- [x] Create `onboarding_progress_model.dart` with `OnboardingProgress`, `LangCheckpoint`, `ChatCheckpoint`
- [x] Implement `fromJson`/`toJson`/`copyWith`
- [x] Handle schema version parsing (ignore unknown versions → empty)
- [x] Create `onboarding_progress_service.dart` with CRUD methods
- [x] Register service in global DI bindings
- [x] Run `flutter analyze` — must be clean

## Success Criteria
- Service reads/writes round-trip without data loss.
- Corrupt JSON → returns empty progress (no throw).
- `flutter analyze` clean.

## Risk Assessment
- **Risk:** JSON-encoding dates/nested maps breaks. **Mitigation:** Unit test in phase 5; use ISO8601 strings.
- **Risk:** Get registration order — service reads StorageService before it's initialized. **Mitigation:** Register AFTER `StorageService.init()` in main.dart.

## Security Considerations
- No PII in progress map (only language codes + conversation UUID). Safe to persist unencrypted.

## Next Steps
- Phase 02 consumes `OnboardingProgressService.read()` in `SplashController`.
