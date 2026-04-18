import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flowering/core/services/storage_service.dart';
import 'package:flowering/features/onboarding/services/onboarding_progress_service.dart';

/// In-memory StorageService fake — overrides only the preference surface used
/// by OnboardingProgressService. Bypasses Hive init entirely so tests don't
/// need platform channels or temp dirs.
class _FakeStorageService extends StorageService {
  final Map<String, dynamic> _prefs = {};

  @override
  Future<StorageService> init() async => this;

  @override
  T? getPreference<T>(String key) => _prefs[key] as T?;

  @override
  Future<void> setPreference<T>(String key, T value) async {
    _prefs[key] = value;
  }

  @override
  Future<void> removePreference(String key) async {
    _prefs.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeStorageService storage;
  late OnboardingProgressService service;

  setUp(() async {
    Get.reset();
    storage = _FakeStorageService();
    Get.put<StorageService>(storage);
    service = OnboardingProgressService();
  });

  tearDown(() {
    Get.reset();
  });

  group('OnboardingProgressService read', () {
    test('missing key returns empty progress', () {
      expect(service.read().isEmpty, isTrue);
    });

    test('corrupted JSON returns empty progress (no throw)', () async {
      await storage.setPreference<String>(
          'onboarding_progress', 'not-valid-json{');
      expect(() => service.read(), returnsNormally);
      expect(service.read().isEmpty, isTrue);
    });

    test('non-object JSON returns empty progress', () async {
      await storage.setPreference<String>('onboarding_progress', '[1,2,3]');
      expect(service.read().isEmpty, isTrue);
    });
  });

  group('OnboardingProgressService individual writes', () {
    test('setNativeLang persists without disturbing siblings', () async {
      await service.setLearningLang('en', id: 'uuid-en');
      await service.setNativeLang('vi', id: 'uuid-vi');

      final p = service.read();
      expect(p.nativeLang?.code, 'vi');
      expect(p.nativeLang?.id, 'uuid-vi');
      expect(p.learningLang?.code, 'en');
    });

    test('setChatConversationId persists chat checkpoint', () async {
      await service.setNativeLang('vi');
      await service.setChatConversationId('conv-uuid');

      final p = service.read();
      expect(p.chat?.conversationId, 'conv-uuid');
      expect(p.nativeLang?.code, 'vi');
    });

    test('setProfileComplete flips boolean flag', () async {
      await service.setProfileComplete(true);
      expect(service.read().profileComplete, isTrue);
    });

    test('clearChat removes only chat, preserves languages', () async {
      await service.setNativeLang('vi');
      await service.setLearningLang('en');
      await service.setChatConversationId('conv-uuid');

      await service.clearChat();
      final p = service.read();

      expect(p.chat, isNull);
      expect(p.nativeLang?.code, 'vi');
      expect(p.learningLang?.code, 'en');
    });

    test('clearAll wipes entire progress key', () async {
      await service.setNativeLang('vi');
      await service.setProfileComplete(true);

      await service.clearAll();

      expect(service.read().isEmpty, isTrue);
    });
  });

  group('OnboardingProgressService legacy migration', () {
    test('init migrates legacy onboarding_conversation_id into chat', () async {
      await storage.setPreference<String>(
          'onboarding_conversation_id', 'legacy-uuid');

      await service.init();

      expect(service.read().chat?.conversationId, 'legacy-uuid');
      expect(
          storage.getPreference<String>('onboarding_conversation_id'), isNull,
          reason: 'legacy key should be deleted after migration');
    });

    test('init skips migration when chat checkpoint already set', () async {
      await service.setChatConversationId('current-uuid');
      await storage.setPreference<String>(
          'onboarding_conversation_id', 'legacy-uuid');

      await service.init();

      expect(service.read().chat?.conversationId, 'current-uuid',
          reason: 'current chat checkpoint should not be overwritten');
    });

    test('init is safe to call when no legacy key exists', () async {
      await expectLater(service.init(), completes);
      expect(service.read().isEmpty, isTrue);
    });

    test('init is idempotent — repeated calls do not duplicate data', () async {
      await storage.setPreference<String>(
          'onboarding_conversation_id', 'legacy-uuid');

      await service.init();
      await service.init();

      expect(service.read().chat?.conversationId, 'legacy-uuid');
    });
  });
}
