// lib/core/services/storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  // ─────────────────────────────────────────────────────────────────
  // Lessons Cache (LRU)
  // ─────────────────────────────────────────────────────────────────

  /// Get lesson from cache, updates access time
  String? getLesson(String key) {
    final value = _lessons.get(key);
    if (value != null) {
      // Update access time for LRU
      _lessonsAccess.put(key, DateTime.now().millisecondsSinceEpoch);
    }
    return value;
  }

  /// Save lesson to cache with LRU eviction
  Future<void> saveLesson(String key, String value) async {
    try {
      final valueSize = _estimateSize(value);

      // Evict until we have space
      while (_lessonsCurrentSize + valueSize > _lessonsMaxSize &&
          _lessons.isNotEmpty) {
        await _evictLRULesson();
      }

      await _lessons.put(key, value);
      await _lessonsAccess.put(key, DateTime.now().millisecondsSinceEpoch);
      _lessonsCurrentSize += valueSize;
    } on HiveError catch (e) {
      if (kDebugMode) {
        print('Failed to save lesson: $e');
      }
      // Skip saving on error
    }
  }

  /// Evict least recently used lesson
  Future<void> _evictLRULesson() async {
    if (_lessonsAccess.isEmpty) return;

    // Find oldest access
    String? oldestKey;
    int oldestTime = DateTime.now().millisecondsSinceEpoch;

    for (final key in _lessonsAccess.keys) {
      final time = _lessonsAccess.get(key) ?? 0;
      if (time < oldestTime) {
        oldestTime = time;
        oldestKey = key as String?;
      }
    }

    if (oldestKey != null) {
      final value = _lessons.get(oldestKey);
      if (value != null) {
        _lessonsCurrentSize -= _estimateSize(value);
      }
      await _lessons.delete(oldestKey);
      await _lessonsAccess.delete(oldestKey);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Chat Cache (FIFO)
  // ─────────────────────────────────────────────────────────────────

  /// Get chat messages
  String? getChatMessage(String key) {
    return _chat.get(key);
  }

  /// Get all chat messages for a conversation
  List<String> getChatMessages(String conversationId) {
    return _chat.keys
        .where((k) => k.toString().startsWith(conversationId))
        .map((k) => _chat.get(k))
        .whereType<String>()
        .toList();
  }

  /// Save chat message with FIFO eviction
  Future<void> saveChatMessage(String key, String value) async {
    try {
      final valueSize = _estimateSize(value);

      // FIFO eviction - remove oldest entries first
      while (_chatCurrentSize + valueSize > _chatMaxSize && _chat.isNotEmpty) {
        final firstKey = _chat.keyAt(0);
        final firstValue = _chat.get(firstKey);
        if (firstValue != null) {
          _chatCurrentSize -= _estimateSize(firstValue);
        }
        await _chat.deleteAt(0);
      }

      await _chat.put(key, value);
      _chatCurrentSize += valueSize;
    } on HiveError catch (e) {
      if (kDebugMode) {
        print('Failed to save chat message: $e');
      }
      // Skip saving on error
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Preferences
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
  // Cache Management
  // ─────────────────────────────────────────────────────────────────

  /// Get total cache size in bytes
  int get totalCacheSize => _lessonsCurrentSize + _chatCurrentSize;

  /// Get lessons cache size in bytes
  int get lessonsCacheSize => _lessonsCurrentSize;

  /// Get chat cache size in bytes
  int get chatCacheSize => _chatCurrentSize;

  /// Clear lessons cache
  Future<void> clearLessonsCache() async {
    await _lessons.clear();
    await _lessonsAccess.clear();
    _lessonsCurrentSize = 0;
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
  // Permanent flags (survive clearAll)
  // ─────────────────────────────────────────────────────────────────

  /// True once the user has successfully logged in at least once.
  /// Never cleared — even after logout — so the app knows to show auth
  /// on the onboarding intro screens instead of routing into onboarding flows.
  bool get hasCompletedLogin =>
      getPreference<bool>(_hasCompletedLoginKey) ?? false;

  Future<void> setHasCompletedLogin() async =>
      setPreference<bool>(_hasCompletedLoginKey, true);

  /// Clear everything — used on logout.
  /// Preserves [_hasCompletedLoginKey] so returning users are never re-onboarded.
  Future<void> clearAll() async {
    final hadLogin = hasCompletedLogin;
    await clearAllCaches();
    await clearPreferences();
    if (hadLogin) await setHasCompletedLogin();
  }

  /// Returns all preference keys matching [test].
  Iterable<String> preferenceKeysMatching(bool Function(String) test) =>
      _preferences.keys.whereType<String>().where(test);

  /// Deletes all preference keys matching [test].
  Future<void> removePreferencesMatching(bool Function(String) test) async {
    final keys = preferenceKeysMatching(test).toList();
    for (final k in keys) {
      await _preferences.delete(k);
    }
  }

  /// Close all boxes
  Future<void> close() async {
    await _lessons.close();
    await _lessonsAccess.close();
    await _chat.close();
    await _preferences.close();
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
