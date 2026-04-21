import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flowering/core/network/api_response.dart';
import 'package:flowering/core/services/language-context-service.dart';
import 'package:flowering/features/scenarios/controllers/flowering_feed_controller.dart';
import 'package:flowering/features/scenarios/models/scenario_access_tier.dart';
import 'package:flowering/features/scenarios/models/scenario_feed_item.dart';
import 'package:flowering/features/scenarios/models/scenario_type.dart';
import 'package:flowering/features/scenarios/models/scenario_user_status.dart';
import 'package:flowering/features/scenarios/models/scenarios_feed_response.dart';
import 'package:flowering/features/scenarios/models/scenarios_pagination.dart';
import 'package:flowering/features/scenarios/models/personal_scenario_item.dart';
import 'package:flowering/features/scenarios/services/scenarios_service.dart';

ScenarioFeedItem _fakeItem(String id) => ScenarioFeedItem(
      id: id,
      title: 'T$id',
      description: 'd',
      imageUrl: null,
      difficulty: 'beginner',
      languageId: 'en',
      accessTier: ScenarioAccessTier.free,
      status: ScenarioUserStatus.available,
      type: ScenarioType.defaultType,
      orderIndex: 0,
    );

class _FakeScenariosService extends ScenariosService {
  _FakeScenariosService({
    required this.pages,
    required this.total,
  });

  final List<List<ScenarioFeedItem>> pages;
  final int total;
  int defaultCalls = 0;
  int? lastDefaultPage;

  @override
  Future<ApiResponse<ScenariosFeedResponse<ScenarioFeedItem>>> getDefaultFeed({
    int page = 1,
    int limit = 20,
  }) async {
    defaultCalls++;
    lastDefaultPage = page;
    final idx = page - 1;
    final items = idx >= 0 && idx < pages.length ? pages[idx] : <ScenarioFeedItem>[];
    return ApiResponse<ScenariosFeedResponse<ScenarioFeedItem>>.success(
      data: ScenariosFeedResponse<ScenarioFeedItem>(
        items: items,
        pagination:
            ScenariosPagination(page: page, limit: limit, total: total),
      ),
    );
  }

  @override
  Future<ApiResponse<ScenariosFeedResponse<PersonalScenarioItem>>>
      getPersonalFeed({int page = 1, int limit = 20}) async =>
          ApiResponse<ScenariosFeedResponse<PersonalScenarioItem>>.success(
            data: ScenariosFeedResponse<PersonalScenarioItem>(
              items: const [],
              pagination:
                  ScenariosPagination(page: page, limit: limit, total: 0),
            ),
          );
}

void main() {
  setUpAll(() {
    Get.testMode = true;
  });

  late _FakeScenariosService fakeService;
  late LanguageContextService langCtx;

  setUp(() {
    Get.reset();
    langCtx = LanguageContextService();
    langCtx.activeCode.value = 'en';
    Get.put<LanguageContextService>(langCtx);
  });

  tearDown(() {
    Get.reset();
  });

  group('FloweringFeedController', () {
    testWidgets('first fetch populates items and increments page',
        (tester) async {
      fakeService = _FakeScenariosService(
        pages: [
          List.generate(20, (i) => _fakeItem('p1_$i')),
        ],
        total: 20,
      );
      Get.put<ScenariosService>(fakeService);

      final controller = FloweringFeedController();
      controller.onInit();
      await tester.pumpAndSettle();

      expect(controller.items.length, 20);
      expect(fakeService.defaultCalls, 1);
      expect(fakeService.lastDefaultPage, 1);
      expect(controller.hasMore, isFalse);
      controller.onClose();
    });

    testWidgets('loadMore appends items and bumps page', (tester) async {
      fakeService = _FakeScenariosService(
        pages: [
          List.generate(20, (i) => _fakeItem('p1_$i')),
          List.generate(5, (i) => _fakeItem('p2_$i')),
        ],
        total: 25,
      );
      Get.put<ScenariosService>(fakeService);

      final controller = FloweringFeedController();
      controller.onInit();
      await tester.pumpAndSettle();

      expect(controller.items.length, 20);
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      await tester.pumpAndSettle();

      expect(controller.items.length, 25);
      expect(fakeService.lastDefaultPage, 2);
      expect(controller.hasMore, isFalse);
      controller.onClose();
    });

    testWidgets('refresh resets page to 1 and replaces items', (tester) async {
      fakeService = _FakeScenariosService(
        pages: [
          List.generate(2, (i) => _fakeItem('a$i')),
          List.generate(2, (i) => _fakeItem('b$i')),
        ],
        total: 2,
      );
      Get.put<ScenariosService>(fakeService);

      final controller = FloweringFeedController();
      controller.onInit();
      await tester.pumpAndSettle();
      expect(controller.items.map((e) => e.id), ['a0', 'a1']);

      await controller.refreshFeed();
      await tester.pumpAndSettle();

      // Page cursor reset → service called with page=1 again.
      expect(fakeService.lastDefaultPage, 1);
      expect(controller.items.length, 2);
      controller.onClose();
    });

    testWidgets('language-change triggers a refresh', (tester) async {
      fakeService = _FakeScenariosService(
        pages: [
          List.generate(2, (i) => _fakeItem('en$i')),
          List.generate(2, (i) => _fakeItem('fr$i')),
        ],
        total: 2,
      );
      Get.put<ScenariosService>(fakeService);

      final controller = FloweringFeedController();
      controller.onInit();
      await tester.pumpAndSettle();
      final beforeCalls = fakeService.defaultCalls;

      langCtx.activeCode.value = 'fr';
      await tester.pumpAndSettle();

      expect(fakeService.defaultCalls, greaterThan(beforeCalls));
      controller.onClose();
    });
  });
}
