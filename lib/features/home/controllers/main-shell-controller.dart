import 'package:get/get.dart';

/// Controls bottom navigation tab index
class MainShellController extends GetxController {
  final selectedIndex = 0.obs;

  void changePage(int index) {
    selectedIndex.value = index;
  }
}
