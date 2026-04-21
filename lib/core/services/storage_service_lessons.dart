part of 'storage_service.dart';

// Lessons cache methods for StorageService (LRU eviction).
// Declared as extension within the same library part — has access to all
// library-private (`_`) identifiers defined in storage_service.dart.

extension StorageServiceLessons on StorageService {
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
      while (_lessonsCurrentSize + valueSize > StorageService._lessonsMaxSize &&
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

  /// Returns the per-language lessons sub-box, opening it lazily.
  /// Bounded by [StorageService._maxOpenLangBoxes] — when exceeded the
  /// least-recently-used box (front of insertion order) is closed.
  Future<Box<String>> getLessonsBoxFor(String langCode) async {
    final existing = _langLessonBoxes.remove(langCode);
    if (existing != null) {
      // Re-insert at the end to mark as most-recently-used.
      _langLessonBoxes[langCode] = existing;
      return existing;
    }
    final box = await Hive.openBox<String>('lessons_cache_$langCode');
    _langLessonBoxes[langCode] = box;
    while (_langLessonBoxes.length > StorageService._maxOpenLangBoxes) {
      final oldestKey = _langLessonBoxes.keys.first;
      final oldestBox = _langLessonBoxes.remove(oldestKey);
      try {
        await oldestBox?.close();
      } on HiveError catch (e) {
        if (kDebugMode) print('Failed to close lang box $oldestKey: $e');
      }
    }
    return box;
  }

  /// Clears only the cached lessons for [langCode] (scoped invalidation).
  Future<void> clearLessonsCacheForLang(String langCode) async {
    final box = await getLessonsBoxFor(langCode);
    await box.clear();
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
}
