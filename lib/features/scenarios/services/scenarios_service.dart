import 'package:get/get.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/personal_scenario_item.dart';
import '../models/scenario_feed_item.dart';
import '../models/scenarios_feed_response.dart';

/// Thin wrapper around `/scenarios/default` and `/scenarios/personal`.
/// Stateless — controllers own pagination state. `X-Learning-Language` is
/// attached automatically by `ActiveLanguageInterceptor`.
class ScenariosService extends GetxService {
  ApiClient get _apiClient => Get.find<ApiClient>();

  Future<ApiResponse<ScenariosFeedResponse<ScenarioFeedItem>>> getDefaultFeed({
    int page = 1,
    int limit = 20,
  }) {
    return _apiClient.get<ScenariosFeedResponse<ScenarioFeedItem>>(
      ApiEndpoints.scenariosDefault,
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (data) => ScenariosFeedResponse<ScenarioFeedItem>.fromJson(
        data as Map<String, dynamic>,
        ScenarioFeedItem.fromJson,
      ),
    );
  }

  Future<ApiResponse<ScenariosFeedResponse<PersonalScenarioItem>>>
      getPersonalFeed({
    int page = 1,
    int limit = 20,
  }) {
    return _apiClient.get<ScenariosFeedResponse<PersonalScenarioItem>>(
      ApiEndpoints.scenariosPersonal,
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (data) => ScenariosFeedResponse<PersonalScenarioItem>.fromJson(
        data as Map<String, dynamic>,
        PersonalScenarioItem.fromJson,
      ),
    );
  }
}
