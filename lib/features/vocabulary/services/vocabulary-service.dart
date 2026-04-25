import 'package:get/get.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/vocabulary-model.dart';

class VocabularyService extends GetxService {
  ApiClient get _apiClient => Get.find<ApiClient>();

  Future<ApiResponse<VocabularyListResponse>> getVocabulary({
    int page = 1,
    int limit = 20,
    int box = 1,
    String search = '',
  }) {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      'box': box,
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };

    return _apiClient.get<VocabularyListResponse>(
      ApiEndpoints.vocabulary,
      queryParameters: query,
      fromJson: (data) =>
          VocabularyListResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
