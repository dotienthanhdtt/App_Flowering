import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

/// Controller for profile tab
class ProfileController extends BaseController {
  final userName = ''.obs;
  final userEmail = ''.obs;

  void logout() {
    // Will connect to auth service in future
  }
}
