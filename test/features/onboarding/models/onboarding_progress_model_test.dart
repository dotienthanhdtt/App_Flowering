import 'package:flutter_test/flutter_test.dart';
import 'package:flowering/features/onboarding/models/onboarding_progress_model.dart';

void main() {
  group('OnboardingProgress model', () {
    test('empty progress round-trips through toJson/fromJson', () {
      final empty = OnboardingProgress.empty();
      final decoded = OnboardingProgress.fromJson(empty.toJson());

      expect(decoded.nativeLang, isNull);
      expect(decoded.learningLang, isNull);
      expect(decoded.chat, isNull);
      expect(decoded.profileComplete, isFalse);
      expect(decoded.isEmpty, isTrue);
    });

    test('full progress preserves all fields round-trip', () {
      final now = DateTime.utc(2026, 4, 14, 23, 27);
      final original = OnboardingProgress(
        nativeLang: const LangCheckpoint(code: 'vi', id: 'uuid-native'),
        learningLang: const LangCheckpoint(code: 'en', id: 'uuid-learning'),
        chat: const ChatCheckpoint(conversationId: 'uuid-conv'),
        profileComplete: true,
        updatedAt: now,
      );
      final decoded = OnboardingProgress.fromJson(original.toJson());

      expect(decoded.nativeLang?.code, 'vi');
      expect(decoded.nativeLang?.id, 'uuid-native');
      expect(decoded.learningLang?.code, 'en');
      expect(decoded.learningLang?.id, 'uuid-learning');
      expect(decoded.chat?.conversationId, 'uuid-conv');
      expect(decoded.profileComplete, isTrue);
      expect(decoded.updatedAt, isNotNull);
    });

    test('schema version mismatch returns empty progress', () {
      final decoded = OnboardingProgress.fromJson({
        '_v': 999,
        'native_lang': {'code': 'vi'},
        'profile_complete': true,
      });

      expect(decoded.isEmpty, isTrue);
      expect(decoded.nativeLang, isNull);
    });

    test('missing schema version returns empty progress', () {
      final decoded = OnboardingProgress.fromJson({
        'native_lang': {'code': 'vi'},
      });

      expect(decoded.isEmpty, isTrue);
    });

    test('copyWith preserves unrelated fields', () {
      const original = OnboardingProgress(
        nativeLang: LangCheckpoint(code: 'vi'),
        learningLang: LangCheckpoint(code: 'en'),
      );
      final modified = original.copyWith(profileComplete: true);

      expect(modified.nativeLang?.code, 'vi');
      expect(modified.learningLang?.code, 'en');
      expect(modified.profileComplete, isTrue);
    });

    test('copyWith clearChat removes only chat checkpoint', () {
      const original = OnboardingProgress(
        nativeLang: LangCheckpoint(code: 'vi'),
        chat: ChatCheckpoint(conversationId: 'uuid-conv'),
      );
      final cleared = original.copyWith(clearChat: true);

      expect(cleared.chat, isNull);
      expect(cleared.nativeLang?.code, 'vi');
    });

    test('LangCheckpoint serializes id only when present', () {
      const withId = LangCheckpoint(code: 'vi', id: 'uuid');
      const withoutId = LangCheckpoint(code: 'vi');

      expect(withId.toJson()['id'], 'uuid');
      expect(withoutId.toJson().containsKey('id'), isFalse);
    });
  });
}
