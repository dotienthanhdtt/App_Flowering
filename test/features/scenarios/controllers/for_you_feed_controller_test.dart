import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flowering/core/network/api_response.dart';
import 'package:flowering/core/services/language-context-service.dart';
import 'package:flowering/features/scenarios/controllers/for_you_feed_controller.dart';
import 'package:flowering/features/scenarios/models/personal_scenario_item.dart';
import 'package:flowering/features/scenarios/models/personal_source.dart';
import 'package:flowering/features/scenarios/models/scenario_access_tier.dart';
import 'package:flowering/features/scenarios/models/scenario_feed_item.dart';
import 'package:flowering/features/scenarios/models/scenario_type.dart';
import 'package:flowering/features/scenarios/models/scenario_user_status.dart';
import 'package:flowering/features/scenarios/models/scenarios_feed_response.dart';
import 'package:flowering/features/scenarios/models/scenarios_pagination.dart';
import 'package:flowering/features/scenarios/services/scenarios_service.dart';

PersonalScenarioItem _fakeItem(String id) => PersonalScenarioItem(
      id: id,
      title: 'T$id',
      description: 'd',
      difficulty: 'beginner',
      languageId: 'en',
      addedAt: DateTime.utc(2026, 4, 20),
      source: PersonalSource.personalized,
      accessTier: ScenarioAccessTier.free,
      status: ScenarioUserStatus.available,
      type: ScenarioType.defaultType,
    );

class _FakeScenariosService extends ScenariosService {
  _FakeScenariosService({required this.pages, required this.total});

  final List<List<PersonalScenarioItem>> pages;
  final int total;
  int personalCalls = 0;
  int? lastPersonalPage;

  @override
  Future<ApiResponse<ScenariosFeedResponse<ScenarioFeedItem>>> getDefaultFeed({
    int page = 1,
    int limit = 20,
  }) async =>
      ApiResponse<ScenariosFeedResponse<ScenarioFeedItem>>.success(
        data: ScenariosFeedResponse<ScenarioFeedItem>(
          items: const [],
          pagination: ScenariosPagination(page: page, limit: limit, total: 0),
        ),
      );

  @override
  Future<ApiResponse<ScenariosFeedResponse<PersonalScenarioItem>>>
      getPersonalFeed({int page = 1, int limit = 20}) async {
    personalCalls++;
    lastPersonalPage = page;
    final idx = page - 1;
    final items =
        idx >= 0 && idx < pages.length ? pages[idx] : <PersonalScenarioItem>[];
    return ApiResponse<ScenariosFeedResponse<PersonalScenarioItem>>.success(
      data: ScenariosFeedResponse<PersonalScenarioItem>(
        items: items,
        pagination:
            ScenariosPagination(page: page, limit: limit, total: total),
      ),
    );
  }
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

  group('ForYouFeedController', () {
    testWidgets('first fetch populates items from personal feed',
        (tester) async {
      fakeService = _FakeScenariosService(
        pages: [List.generate(3, (i) => _fakeItem('p1_$i'))],
        total: 3,
      );
      Get.put<ScenariosService>(fakeService);

      final controller = ForYouFeedController();
      controller.onInit();
      await tester.pumpAndSettle();

      expect(controller.items.length, 3);
      expect(fakeService.personalCalls, 1);
      expect(fakeService.lastPersonalPage, 1);
      expect(controller.hasMore, isFalse);
      controller.onClose();
    });

    testWidgets('loadMore appends and advances page', (tester) async {
      fakeService = _FakeScenariosService(
        pages: [
          List.generate(20, (i) => _fakeItem('p1_$i')),
          List.generate(1, (i) => _fakeItem('p2_$i')),
        ],
        total: 21,
      );
      Get.put<ScenariosService>(fakeService);

      final controller = ForYouFeedController();
      controller.onInit();
      await tester.pumpAndSettle();
      expect(controller.items.length, 20);
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      await tester.pumpAndSettle();

      expect(controller.items.length, 21);
      expect(fakeService.lastPersonalPage, 2);
      expect(controller.hasMore, isFalse);
      controller.onClose();
    });

    testWidgets('language-change refreshes feed', (tester) async {
      fakeService = _FakeScenariosService(
        pages: [
          List.generate(1, (i) => _fakeItem('en$i')),
          List.generate(1, (i) => _fakeItem('fr$i')),
        ],
        total: 1,
      );
      Get.put<ScenariosService>(fakeService);

      final controller = ForYouFeedController();
      controller.onInit();
      await tester.pumpAndSettle();
      final beforeCalls = fakeService.personalCalls;

      langCtx.activeCode.value = 'fr';
      await tester.pumpAndSettle();

      expect(fakeService.personalCalls, greaterThan(beforeCalls));
      controller.onClose();
    });
  });
}
