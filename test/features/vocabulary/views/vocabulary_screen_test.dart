import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flowering/core/network/api_response.dart';
import 'package:flowering/features/vocabulary/controllers/vocabulary-controller.dart';
import 'package:flowering/features/vocabulary/models/vocabulary-model.dart';
import 'package:flowering/features/vocabulary/services/vocabulary-service.dart';
import 'package:flowering/features/vocabulary/views/vocabulary-screen.dart';
import 'package:flowering/l10n/english-translations-en-us.dart';

VocabularyItem _item(String word, String translation) =>
    VocabularyItem(id: word, word: word, translation: translation, box: 1);

class _FakeVocabularyService extends VocabularyService {
  _FakeVocabularyService(this.response);

  final VocabularyListResponse response;

  @override
  Future<ApiResponse<VocabularyListResponse>> getVocabulary({
    int page = 1,
    int limit = 20,
    int box = 1,
    String search = '',
  }) async {
    return ApiResponse<VocabularyListResponse>.success(data: response);
  }
}

Widget _host(VocabularyListResponse response) {
  Get.put<VocabularyService>(_FakeVocabularyService(response));
  Get.put<VocabularyController>(VocabularyController());

  return GetMaterialApp(
    translationsKeys: {'en_US': enUS},
    locale: const Locale('en', 'US'),
    fallbackLocale: const Locale('en', 'US'),
    home: const Scaffold(body: VocabularyScreen()),
  );
}

Future<void> _finishInitialLoad(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2100));
  await tester.pump();
}

void main() {
  setUpAll(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('VocabularyScreen', () {
    testWidgets('renders word and translation cards', (tester) async {
      await tester.pumpWidget(
        _host(
          VocabularyListResponse(
            items: [_item('hello', 'xin chao')],
            total: 1,
            page: 1,
            limit: 20,
          ),
        ),
      );
      await _finishInitialLoad(tester);

      expect(find.text('hello'), findsOneWidget);
      expect(find.text('xin chao'), findsOneWidget);
      expect(find.text('Box 1'), findsOneWidget);
    });

    testWidgets('renders Box 1-5 tabs', (tester) async {
      await tester.pumpWidget(
        _host(
          VocabularyListResponse(
            items: [_item('hello', 'xin chao')],
            total: 1,
            page: 1,
            limit: 20,
          ),
        ),
      );
      await _finishInitialLoad(tester);

      for (var box = 1; box <= 5; box++) {
        expect(find.text('$box'), findsOneWidget);
      }
    });

    testWidgets('empty state appears when response has no items', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const VocabularyListResponse(items: [], total: 0, page: 1, limit: 20),
        ),
      );
      await _finishInitialLoad(tester);

      expect(find.text('No words learned yet'), findsOneWidget);
    });
  });
}
