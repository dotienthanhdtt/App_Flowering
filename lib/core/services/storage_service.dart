// lib/core/services/storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'storage_service_lessons.dart';
part 'storage_service_chat.dart';
part 'storage_service_preferences.dart';

/// Storage service with LRU eviction for lessons, FIFO for chat
class StorageService extends GetxService {
  static const String _lessonsBox = 'lessons_cache';
  static const String _lessonsAccessBox = 'lessons_access';
  static const String _chatBox = 'chat_cache';
  static const String _preferencesBox = 'preferences';

  /// Key for the permanent "user has completed login" flag.
  /// This key survives clearAll() so returning users are never re-onboarded.
  static const String _hasCompletedLoginKey = 'has_completed_login';

  // Size limits in bytes
  static const int _lessonsMaxSize = 100 * 1024 * 1024; // 100 MB
  static const int _chatMaxSize = 10 * 1024 * 1024; // 10 MB

  late Box<String> _lessons;
  late Box<int> _lessonsAccess;
  late Box<String> _chat;
  late Box<dynamic> _preferences;
  // Insertion-ordered LRU of open language lesson boxes. When we exceed
  // [_maxOpenLangBoxes], the least-recently used box is closed to bound
  // file-descriptor use across language switches.
  static const int _maxOpenLangBoxes = 2;
  final Map<String, Box<String>> _langLessonBoxes = <String, Box<String>>{};

  int _lessonsCurrentSize = 0;
  int _chatCurrentSize = 0;

  /// Initialize storage service
  Future<StorageService> init() async {
    try {
      await Hive.initFlutter();

      _lessons = await Hive.openBox<String>(_lessonsBox);
      _lessonsAccess = await Hive.openBox<int>(_lessonsAccessBox);
      _chat = await Hive.openBox<String>(_chatBox);
      _preferences = await Hive.openBox<dynamic>(_preferencesBox);

      // Calculate current sizes
      _lessonsCurrentSize = _calculateBoxSize(_lessons);
      _chatCurrentSize = _calculateBoxSize(_chat);
    } on HiveError catch (e) {
      // Box corrupted - recreate
      if (kDebugMode) {
        print('Hive box error: $e. Recreating...');
      }
      await Hive.deleteFromDisk();
      return await init(); // Retry
    }

    return this;
  }

  /// Close all boxes
  Future<void> close() async {
    await _lessons.close();
    await _lessonsAccess.close();
    await _chat.close();
    await _preferences.close();
    for (final box in _langLessonBoxes.values) {
      await box.close();
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Cache Management
  // ─────────────────────────────────────────────────────────────────

  /// Get total cache size in bytes
  int get totalCacheSize => _lessonsCurrentSize + _chatCurrentSize;

  /// Get lessons cache size in bytes
  int get lessonsCacheSize => _lessonsCurrentSize;

  /// Get chat cache size in bytes
  int get chatCacheSize => _chatCurrentSize;

  /// Clear ALL lessons caches (flat box + all per-lang sub-boxes).
  Future<void> clearLessonsCache() async {
    await _lessons.clear();
    await _lessonsAccess.clear();
    _lessonsCurrentSize = 0;
    for (final box in _langLessonBoxes.values) {
      await box.clear();
    }
  }

  /// Clear chat cache
  Future<void> clearChatCache() async {
    await _chat.clear();
    _chatCurrentSize = 0;
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await clearLessonsCache();
    await clearChatCache();
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

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────

  int _calculateBoxSize(Box box) {
    int size = 0;
    for (final key in box.keys) {
      final value = box.get(key);
      if (value != null) {
        size += _estimateSize(value.toString());
      }
    }
    return size;
  }

  int _estimateSize(String value) {
    // UTF-16 encoding approximation
    return value.length * 2;
  }
}
