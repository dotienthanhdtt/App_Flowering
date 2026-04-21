import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/onboarding_language_model.dart';

/// Fetches language lists from API. No persistent cache — every call hits the network.
class OnboardingLanguageService {
  final ApiClient _apiClient;

  OnboardingLanguageService(this._apiClient);

  /// Returns native languages.
  Future<List<OnboardingLanguage>> getNativeLanguages() {
    return _getLanguages(type: 'native');
  }

  /// Returns learning languages.
  Future<List<OnboardingLanguage>> getLearningLanguages() {
    return _getLanguages(type: 'learning');
  }

  Future<List<OnboardingLanguage>> _getLanguages({
    required String type,
  }) async {
    try {
      final response = await _apiClient.get<List<OnboardingLanguage>>(
        ApiEndpoints.languages,
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
      if (kDebugMode) {
        print(
          '[Languages:$type] code=${response.code} '
          'msg="${response.message}" count=${response.data?.length ?? 0}',
        );
      }
      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
    } catch (e, st) {
      if (kDebugMode) print('[Languages:$type] ERROR: $e\n$st');
    }
    return [];
  }
}
