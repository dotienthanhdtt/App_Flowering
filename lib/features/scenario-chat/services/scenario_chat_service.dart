import 'package:get/get.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/scenario_chat_turn_request.dart';
import '../models/scenario_chat_turn_response.dart';

class ScenarioChatService extends GetxService {
  ApiClient get _apiClient => Get.find<ApiClient>();

  Future<ApiResponse<ScenarioChatResponse>> chat(
    ScenarioChatTurnRequest req,
  ) {
    return _apiClient.post<ScenarioChatResponse>(
      ApiEndpoints.scenarioChat,
      data: req.toJson(),
      fromJson: (data) =>
          ScenarioChatResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
