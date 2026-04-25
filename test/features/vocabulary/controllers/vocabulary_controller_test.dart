import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flowering/core/network/api_response.dart';
import 'package:flowering/features/vocabulary/controllers/vocabulary-controller.dart';
import 'package:flowering/features/vocabulary/models/vocabulary-model.dart';
import 'package:flowering/features/vocabulary/services/vocabulary-service.dart';

VocabularyItem _item(String id, {int box = 1}) => VocabularyItem(
  id: id,
  word: 'word $id',
  translation: 'translation $id',
  box: box,
);

class _Request {
  final int page;
  final int limit;
  final int box;
  final String search;

  const _Request({
    required this.page,
    required this.limit,
    required this.box,
    required this.search,
  });
}

class _FakeVocabularyService extends VocabularyService {
  _FakeVocabularyService({required this.pages, required this.total});

  final List<List<VocabularyItem>> pages;
  final int total;
  final requests = <_Request>[];

  @override
  Future<ApiResponse<VocabularyListResponse>> getVocabulary({
    int page = 1,
    int limit = 20,
    int box = 1,
    String search = '',
  }) async {
    requests.add(_Request(page: page, limit: limit, box: box, search: search));
    final idx = page - 1;
    final items = idx >= 0 && idx < pages.length
        ? pages[idx]
        : <VocabularyItem>[];
    return ApiResponse<VocabularyListResponse>.success(
      data: VocabularyListResponse(
        items: items,
        total: total,
        page: page,
        limit: limit,
      ),
    );
  }
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

  group('VocabularyController', () {
    testWidgets('initial fetch requests page 1, limit 20, box 1', (
      tester,
    ) async {
      final service = _FakeVocabularyService(
        pages: [List.generate(2, (i) => _item('$i'))],
        total: 2,
      );
      Get.put<VocabularyService>(service);

      final controller = VocabularyController();
      controller.onInit();
      await _finishInitialLoad(tester);

      expect(service.requests.single.page, 1);
      expect(service.requests.single.limit, VocabularyController.pageLimit);
      expect(service.requests.single.box, 1);
      expect(controller.items, hasLength(2));
      controller.onClose();
    });

    testWidgets('changing box replaces items and requests selected box', (
      tester,
    ) async {
      final service = _FakeVocabularyService(
        pages: [
          [_item('box1', box: 1)],
        ],
        total: 1,
      );
      Get.put<VocabularyService>(service);

      final controller = VocabularyController();
      controller.onInit();
      await _finishInitialLoad(tester);
      expect(controller.items.single.word, 'word box1');

      final changeFuture = controller.changeBox(4);
      await _finishInitialLoad(tester);
      await changeFuture;

      expect(controller.selectedBox.value, 4);
      expect(service.requests.last.box, 4);
      expect(service.requests.last.page, 1);
      expect(controller.items, hasLength(1));
      controller.onClose();
    });

    testWidgets('search debounce sends search', (tester) async {
      final service = _FakeVocabularyService(
        pages: [
          [_item('hello')],
        ],
        total: 1,
      );
      Get.put<VocabularyService>(service);

      final controller = VocabularyController();
      controller.onInit();
      await _finishInitialLoad(tester);

      controller.updateSearch(' hel ');
      await tester.pump(VocabularyController.searchDebounce);
      await tester.pump();

      expect(service.requests.last.search, ' hel ');
      expect(service.requests.last.page, 1);
      controller.onClose();
    });

    testWidgets(
      'load more appends and stops when page times limit reaches total',
      (tester) async {
        final service = _FakeVocabularyService(
          pages: [
            List.generate(20, (i) => _item('p1_$i')),
            List.generate(5, (i) => _item('p2_$i')),
          ],
          total: 25,
        );
        Get.put<VocabularyService>(service);

        final controller = VocabularyController();
        controller.onInit();
        await _finishInitialLoad(tester);
        expect(controller.hasMore, isTrue);

        await controller.loadMore();
        await tester.pump();

        expect(controller.items, hasLength(25));
        expect(service.requests.last.page, 2);
        expect(controller.hasMore, isFalse);

        await controller.loadMore();
        expect(service.requests.length, 2);
        controller.onClose();
      },
    );

    testWidgets('refresh resets page and replaces items', (tester) async {
      final service = _FakeVocabularyService(
        pages: [
          [_item('fresh')],
          [_item('older')],
        ],
        total: 21,
      );
      Get.put<VocabularyService>(service);

      final controller = VocabularyController();
      controller.onInit();
      await _finishInitialLoad(tester);

      await controller.loadMore();
      await tester.pump();
      expect(controller.items, hasLength(2));

      await controller.refreshVocabulary();
      await tester.pump();

      expect(service.requests.last.page, 1);
      expect(controller.items, hasLength(1));
      expect(controller.items.single.id, 'fresh');
      controller.onClose();
    });
  });
}
