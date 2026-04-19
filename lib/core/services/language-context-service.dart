import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import 'storage_service.dart';

/// Single source of truth for the active learning language.
/// Persisted to Hive preferences box; read by ActiveLanguageInterceptor and controllers.
/// Must be initialized BEFORE ApiClient.init so the interceptor never sees a null service on boot.
class LanguageContextService extends GetxService {
  static const String _codeKey = 'active_language_code';
  static const String _idKey = 'active_language_id';

  final activeCode = RxnString();
  final activeId = RxnString();

  StorageService get _storage => Get.find<StorageService>();

  Future<LanguageContextService> init() async {
    activeCode.value = _storage.getPreference<String>(_codeKey);
    activeId.value = _storage.getPreference<String>(_idKey);
    return this;
  }

  /// Persists and emits the active language. Hive write is awaited before
  /// observable assignment so a crash mid-write leaves old or new state, never inconsistent.
  Future<void> setActive(String code, String? id) async {
    await _storage.setPreference<String>(_codeKey, code);
    if (id != null) {
      await _storage.setPreference<String>(_idKey, id);
    } else {
      await _storage.removePreference(_idKey);
    }
    activeCode.value = code;
    activeId.value = id;
  }

  /// Wipes active language state. Called on logout.
  Future<void> clear() async {
    await _storage.removePreference(_codeKey);
    await _storage.removePreference(_idKey);
    activeCode.value = null;
    activeId.value = null;
  }

  /// Fetches user enrollments from server and sets the active language to the
  /// enrolled entry marked isActive, or the first entry if none is marked.
  /// Returns the picked code, or null if no enrollments exist.
  Future<String?> resyncFromServer() async {
    try {
      final api = Get.find<ApiClient>();
      final resp = await api.get<List<dynamic>>(
        ApiEndpoints.userLanguages,
        fromJson: (d) => d as List<dynamic>,
      );
      if (!resp.isSuccess || resp.data == null || resp.data!.isEmpty) {
        await clear();
        return null;
      }
      final picked = _pickFromEnrollments(resp.data!);
      if (picked == null) {
        await clear();
        return null;
      }
      await setActive(picked['code'] as String, picked['id'] as String?);
      return picked['code'] as String;
    } catch (e) {
      if (kDebugMode) debugPrint('[LanguageContextService] resyncFromServer error: $e');
      return activeCode.value;
    }
  }

  Map<String, dynamic>? _pickFromEnrollments(List<dynamic> enrollments) {
    final maps = enrollments.whereType<Map<String, dynamic>>().toList();
    if (maps.isEmpty) return null;
    try {
      return maps.firstWhere(
        (e) => e['isActive'] == true || e['is_active'] == true,
        orElse: () => maps.first,
      );
    } catch (_) {
      return maps.first;
    }
  }
}
