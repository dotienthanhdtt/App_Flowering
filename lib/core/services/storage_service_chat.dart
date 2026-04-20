part of 'storage_service.dart';

// Chat cache methods for StorageService (FIFO eviction).
// Declared as extension within the same library part — has access to all
// library-private (`_`) identifiers defined in storage_service.dart.

extension StorageServiceChat on StorageService {
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
      while (_chatCurrentSize + valueSize > StorageService._chatMaxSize && _chat.isNotEmpty) {
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
}
