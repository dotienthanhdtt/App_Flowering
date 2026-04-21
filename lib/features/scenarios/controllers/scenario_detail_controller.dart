import 'package:get/get.dart';

import '../../../app/routes/app-route-constants.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/language-context-service.dart';
import '../../subscription/widgets/paywall-bottom-sheet.dart';
import '../models/scenario_detail.dart';
import '../services/scenarios_service.dart';

class ScenarioDetailController extends BaseController {
  final String scenarioId;

  ScenarioDetailController(this.scenarioId);

  final detail = Rxn<ScenarioDetail>();
  final notFound = false.obs;

  Worker? _langWorker;

  ScenariosService get _service => Get.find<ScenariosService>();
  LanguageContextService get _langCtx => Get.find<LanguageContextService>();

  @override
  void onInit() {
    super.onInit();
    fetch();
    _langWorker = ever<String?>(_langCtx.activeCode, (_) {
      Get.back();
    });
  }

  Future<void> fetch() async {
    await apiCall(
      () => _service.getScenarioDetail(scenarioId),
      showLoading: detail.value == null,
      onSuccess: (resp) {
        if (resp.isSuccess && resp.data != null) {
          detail.value = resp.data;
        }
      },
      onError: (e) {
        if (e is NotFoundException) {
          notFound.value = true;
        }
        errorMessage.value = e.userMessage;
      },
    );
  }

  Future<void> openPaywall() async {
    final purchased = await PaywallBottomSheet.show();
    if (purchased) await fetch();
  }

  void startChat() {
    final d = detail.value;
    if (d == null) return;
    Get.toNamed(
      AppRoutes.scenarioChat,
      arguments: {
        'scenarioId': d.id,
        'scenarioTitle': d.title,
        'forceNew': false,
      },
    );
  }

  void practiceAgain() {
    final d = detail.value;
    if (d == null) return;
    Get.toNamed(
      AppRoutes.scenarioChat,
      arguments: {
        'scenarioId': d.id,
        'scenarioTitle': d.title,
        'forceNew': true,
      },
    );
  }

  @override
  void onClose() {
    _langWorker?.dispose();
    super.onClose();
  }
}
