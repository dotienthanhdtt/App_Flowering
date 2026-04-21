// lib/core/services/storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'storage_service_preferences.dart';

/// Local preferences storage (Hive).
///
/// No API response cache lives here anymore — only long-lived user state:
/// onboarding progress JSON, `has_completed_login` flag, etc. Tokens live in
/// [AuthStorage], not here.
class StorageService extends GetxService {
  static const String _preferencesBox = 'preferences';

  /// Key for the permanent "user has completed login" flag.
  /// This key survives clearAll() so returning users are never re-onboarded.
  static const String _hasCompletedLoginKey = 'has_completed_login';

  /// One-shot guard that prevents the v1 orphan-box cleanup from running
  /// more than once per install.
  static const String _orphanBoxesCleanedV1Key = 'orphan_boxes_cleaned_v1';

  /// Names of old boxes that existed before the cache removal. Deleted from
  /// disk on first run after the refactor to reclaim ~110 MB of stale data.
  static const List<String> _orphanBoxNames = [
    'lessons_cache',
    'lessons_access',
    'chat_cache',
  ];

  late Box<dynamic> _preferences;

  /// Initialize storage service. On failure wipes Hive and retries once.
  /// If the retry also fails the error is rethrown rather than swallowed
  /// so callers don't end up with half-initialized late fields.
  Future<StorageService> init() async {
    try {
      await _openBoxes();
    } catch (e, st) {
      if (kDebugMode) {
        print('StorageService.init failed: $e. Wiping Hive and retrying once.');
      }
      await Hive.deleteFromDisk();
      try {
        await _openBoxes();
      } catch (e2, st2) {
        if (kDebugMode) {
          print('StorageService.init failed after wipe-and-retry: $e2\n$st2');
        }
        rethrow;
      }
      if (kDebugMode) {
        print('StorageService.init recovered from: $e\n$st');
      }
    }

    await _cleanOrphanBoxesOnce();
    return this;
  }

  Future<void> _openBoxes() async {
    await Hive.initFlutter();
    _preferences = await Hive.openBox<dynamic>(_preferencesBox);
  }

  /// One-time deletion of Hive boxes left over from the old API cache layer.
  /// Gated by a preference flag so it runs exactly once per install.
  Future<void> _cleanOrphanBoxesOnce() async {
    if (_preferences.get(_orphanBoxesCleanedV1Key) == true) return;
    for (final name in _orphanBoxNames) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (e) {
        if (kDebugMode) {
          print('StorageService: failed to delete orphan box "$name": $e');
        }
      }
    }
    await _preferences.put(_orphanBoxesCleanedV1Key, true);
  }

  /// Close all boxes
  Future<void> close() async {
    await _preferences.close();
  }

  /// Clear all preferences
  Future<void> clearPreferences() async {
    await _preferences.clear();
  }

  // ─────────────────────────────────────────────────────────────────
  // Preferences — instance methods (not extension) so tests can
  // override with in-memory fakes without touching Hive.
  // ─────────────────────────────────────────────────────────────────

  /// Get preference value
  T? getPreference<T>(String key) {
    return _preferences.get(key) as T?;
  }

  /// Set preference value
  Future<void> setPreference<T>(String key, T value) async {
    await _preferences.put(key, value);
  }

  /// Remove preference
  Future<void> removePreference(String key) async {
    await _preferences.delete(key);
  }
}
