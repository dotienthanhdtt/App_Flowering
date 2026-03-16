import 'package:get/get.dart';
import '../../../core/base/base_controller.dart';

/// Controls bottom navigation tab index
class MainShellController extends BaseController {
  final selectedIndex = 0.obs;

  void changePage(int index) {
    selectedIndex.value = index;
  }
}
