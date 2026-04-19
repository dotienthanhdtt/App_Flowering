import 'package:get/get.dart';
import 'language-context-service.dart';
import 'storage_service.dart';

/// Subscribes to LanguageContextService.activeCode and flushes only the
/// switched-from language's lesson sub-box on every switch.
/// Baseline is captured synchronously before ever() registration to avoid
/// the seeded-emission false-trigger (C5a fix).
class CacheInvalidatorService extends GetxService {
  static const String _migrationFlag = 'lang_migration_v1_done';

  Worker? _worker;
  String? _baselineCode;

  Future<CacheInvalidatorService> init() async {
    final storage = Get.find<StorageService>();
    final langCtx = Get.find<LanguageContextService>();

    // One-time flush for existing installs before per-language partitioning.
    final migrationDone = storage.getPreference<bool>(_migrationFlag) ?? false;
    if (!migrationDone) {
      await storage.clearLessonsCache();
      await storage.clearChatCache();
      await storage.removePreferencesMatching(
        (k) => k.startsWith('progress_') || k.startsWith('attempt_'),
      );
      await storage.setPreference(_migrationFlag, true);
    }

    // Capture baseline before registering ever() to skip the initial emission.
    _baselineCode = langCtx.activeCode.value;

    _worker = ever<String?>(langCtx.activeCode, (newCode) async {
      if (newCode == _baselineCode) return;
      final prevCode = _baselineCode;
      _baselineCode = newCode;
      if (prevCode != null && prevCode.isNotEmpty) {
        await storage.clearLessonsCacheForLang(prevCode);
      }
    });

    return this;
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }
}
