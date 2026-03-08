import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

/// Controller for vocabulary tab — manages word list and search
class VocabularyController extends BaseController {
  final words = <Map<String, String>>[].obs;
  final searchQuery = ''.obs;

  List<Map<String, String>> get filteredWords {
    if (searchQuery.value.isEmpty) return words;
    return words.where((word) {
      final term = (word['term'] ?? '').toLowerCase();
      final translation = (word['translation'] ?? '').toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return term.contains(query) || translation.contains(query);
    }).toList();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }
}
