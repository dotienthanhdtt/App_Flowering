import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/services/storage_service.dart';
import '../models/onboarding_progress_model.dart';

/// Persists onboarding progress across app restarts so users resume at their
/// last completed checkpoint. Single source of truth — replaces standalone
/// `onboarding_conversation_id` preference.
///
/// Storage: unified JSON blob under a single preference key (`onboarding_progress`).
/// Reads are synchronous (Hive in-memory); writes are awaited.
class OnboardingProgressService extends GetxService {
  static const String _key = 'onboarding_progress';

  /// Legacy preference key — migrated into progress map on init, then deleted.
  static const String _legacyConversationIdKey = 'onboarding_conversation_id';

  StorageService get _storage => Get.find<StorageService>();

  /// Runs one-shot migration of legacy `onboarding_conversation_id` preference
  /// into the unified progress map. Safe to call multiple times.
  Future<OnboardingProgressService> init() async {
    try {
      final legacy = _storage.getPreference<String>(_legacyConversationIdKey);
      if (legacy != null && legacy.isNotEmpty) {
        final current = read();
        if (current.chat == null) {
          await setChatConversationId(legacy);
        }
        await _storage.removePreference(_legacyConversationIdKey);
      }
    } catch (e) {
      if (kDebugMode) {
        print('OnboardingProgressService.init migration failed: $e');
      }
    }
    return this;
  }

  /// Reads current progress. Returns empty progress on missing key, JSON
  /// corruption, or schema mismatch — never throws.
  OnboardingProgress read() {
    final raw = _storage.getPreference<String>(_key);
    if (raw == null || raw.isEmpty) return OnboardingProgress.empty();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return OnboardingProgress.empty();
      return OnboardingProgress.fromJson(decoded);
    } catch (e) {
      if (kDebugMode) {
        print('OnboardingProgressService.read corruption: $e');
      }
      return OnboardingProgress.empty();
    }
  }

  Future<void> setNativeLang(String code, {String? id}) async {
    final next = read().copyWith(
      nativeLang: LangCheckpoint(code: code, id: id),
      updatedAt: DateTime.now().toUtc(),
    );
    await _write(next);
  }

  Future<void> setLearningLang(String code, {String? id}) async {
    final next = read().copyWith(
      learningLang: LangCheckpoint(code: code, id: id),
      updatedAt: DateTime.now().toUtc(),
    );
    await _write(next);
  }

  Future<void> setChatConversationId(String conversationId) async {
    final next = read().copyWith(
      chat: ChatCheckpoint(conversationId: conversationId),
      updatedAt: DateTime.now().toUtc(),
    );
    await _write(next);
  }

  Future<void> setProfileComplete(bool complete) async {
    final next = read().copyWith(
      profileComplete: complete,
      updatedAt: DateTime.now().toUtc(),
    );
    await _write(next);
  }

  /// Clears only the chat checkpoint (e.g. when backend returns 404 for a
  /// conversation). Preserves language selections.
  Future<void> clearChat() async {
    final next = read().copyWith(
      clearChat: true,
      updatedAt: DateTime.now().toUtc(),
    );
    await _write(next);
  }

  /// Wipes all progress. Called on logout / debug reset — NOT on auto-flow.
  Future<void> clearAll() async {
    await _storage.removePreference(_key);
  }

  Future<void> _write(OnboardingProgress progress) async {
    await _storage.setPreference<String>(_key, jsonEncode(progress.toJson()));
  }
}
