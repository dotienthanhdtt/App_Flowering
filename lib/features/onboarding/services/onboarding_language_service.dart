import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/onboarding_language_model.dart';

/// Fetches language lists from API with 24-hour cache and offline fallback.
class OnboardingLanguageService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  static const _cacheDuration = Duration(hours: 24);

  OnboardingLanguageService(this._apiClient, this._storageService);

  /// Returns native languages — API → cache → fallback.
  Future<List<OnboardingLanguage>> getNativeLanguages() {
    return _getLanguages(
      type: 'native',
      fallback: OnboardingLanguage.nativeLanguages,
    );
  }

  /// Returns learning languages — API → cache → fallback.
  Future<List<OnboardingLanguage>> getLearningLanguages() {
    return _getLanguages(
      type: 'learning',
      fallback: OnboardingLanguage.learningLanguages,
    );
  }

  Future<List<OnboardingLanguage>> _getLanguages({
    required String type,
    required List<OnboardingLanguage> fallback,
  }) async {
    final cacheKey = 'languages_cache_$type';
    final timestampKey = 'languages_cache_ts_$type';

    // Return valid cache if available
    final cached = _readCache(cacheKey, timestampKey);
    if (cached != null) return cached;

    // Fetch from API
    try {
      final response = await _apiClient.get<List<OnboardingLanguage>>(
        ApiEndpoints.languages,
        queryParameters: {'type': type},
        fromJson: (data) {
          if (data is List) {
            return data
                .map(
                  (e) => OnboardingLanguage.fromJson(
                    e as Map<String, dynamic>,
                    type: type,
                  ),
                )
                .toList();
          }
          return <OnboardingLanguage>[];
        },
      );
      if (response.isSuccess &&
          response.data != null &&
          response.data!.isNotEmpty) {
        await _writeCache(cacheKey, timestampKey, response.data!);
        return response.data!;
      }
    } catch (e) {
      if (kDebugMode) print('OnboardingLanguageService[$type]: $e');
    }

    // Fallback: expired cache or static list
    return _readCache(cacheKey, timestampKey, ignoreExpiry: true) ?? fallback;
  }

  List<OnboardingLanguage>? _readCache(
    String cacheKey,
    String timestampKey, {
    bool ignoreExpiry = false,
  }) {
    if (!ignoreExpiry) {
      final ts = _storageService.getPreference<int>(timestampKey);
      if (ts == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _cacheDuration.inMilliseconds) return null;
    }

    final raw = _storageService.getPreference<String>(cacheKey);
    if (raw == null) return null;

    try {
      return (jsonDecode(raw) as List)
          .map((e) => OnboardingLanguage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
    String cacheKey,
    String timestampKey,
    List<OnboardingLanguage> languages,
  ) async {
    await _storageService.setPreference(
      cacheKey,
      jsonEncode(languages.map((l) => l.toJson()).toList()),
    );
    await _storageService.setPreference(
      timestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
