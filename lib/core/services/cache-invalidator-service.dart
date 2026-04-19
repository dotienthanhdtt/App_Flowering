import 'package:get/get.dart';
import 'language-context-service.dart';
import 'storage_service.dart';

/// Subscribes to LanguageContextService.activeCode and flushes language-scoped
/// caches on every switch. Also runs a one-time flush on first launch after the
/// multi-language partition update to clear pre-partition cached content.
class CacheInvalidatorService extends GetxService {
  static const String _migrationFlag = 'lang_migration_v1_done';

  Worker? _worker;
  bool _seeded = false;

  Future<CacheInvalidatorService> init() async {
    final storage = Get.find<StorageService>();
    final langCtx = Get.find<LanguageContextService>();

    // One-time flush for existing installs before content partitioning
    final migrationDone = storage.getPreference<bool>(_migrationFlag) ?? false;
    if (!migrationDone) {
      await _flush(storage);
      await storage.setPreference(_migrationFlag, true);
    }

    _worker = ever<String?>(langCtx.activeCode, (code) async {
      // Skip the first emission which mirrors the already-persisted boot value
      if (!_seeded) {
        _seeded = true;
        return;
      }
      await _flush(storage);
    });
    // Mark seeded so boot emission does not trigger flush on fresh installs
    _seeded = true;
    return this;
  }

  Future<void> _flush(StorageService storage) async {
    await storage.clearLessonsCache();
    await storage.clearChatCache();
    await storage.removePreferencesMatching(
      (k) => k.startsWith('progress_') || k.startsWith('attempt_'),
    );
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }
}
