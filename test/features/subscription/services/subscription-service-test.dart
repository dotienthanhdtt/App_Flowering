import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flowering/features/subscription/services/subscription-service.dart';
import 'package:flowering/features/subscription/services/revenuecat-service.dart';
import 'package:flowering/features/subscription/models/subscription-model.dart';
import 'package:flowering/core/network/api_client.dart';
import 'package:flowering/core/services/auth_storage.dart';
import 'package:flowering/core/network/api_response.dart';

import 'subscription-service-test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<RevenueCatService>(),
  MockSpec<ApiClient>(),
  MockSpec<AuthStorage>(),
])
void main() {
  group('SubscriptionService', () {
    late SubscriptionService subscriptionService;
    late MockRevenueCatService mockRevenueCatService;
    late MockApiClient mockApiClient;
    late MockAuthStorage mockAuthStorage;

    setUp(() {
      Get.reset();

      mockRevenueCatService = MockRevenueCatService();
      mockApiClient = MockApiClient();
      mockAuthStorage = MockAuthStorage();

      // Stub onStart so GetX lifecycle doesn't throw when resolving lazyPut factories
      final noOp = InternalFinalCallback<void>(callback: () {});
      when(mockRevenueCatService.onStart).thenReturn(noOp);
      when(mockApiClient.onStart).thenReturn(noOp);
      when(mockAuthStorage.onStart).thenReturn(noOp);

      Get.lazyPut<RevenueCatService>(() => mockRevenueCatService);
      Get.lazyPut<ApiClient>(() => mockApiClient);
      Get.lazyPut<AuthStorage>(() => mockAuthStorage);

      subscriptionService = SubscriptionService();
    });

    tearDown(() {
      subscriptionService.onClose();
      Get.reset();
    });

    group('init()', () {
      test('defaults to free plan', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        await subscriptionService.init();

        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.free));
      });

      test('returns SubscriptionService instance', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        final result = await subscriptionService.init();

        expect(result, isA<SubscriptionService>());
        expect(result, equals(subscriptionService));
      });
    });

    group('onUserLoggedIn()', () {
      test('calls RC logIn with user ID when RC is configured', () async {
        when(mockAuthStorage.getUserId()).thenAnswer((_) async => 'user-123');
        when(mockRevenueCatService.isConfigured).thenReturn(true);
        when(mockRevenueCatService.logIn('user-123')).thenAnswer((_) async {
          return LogInResult(
              created: true, customerInfo: _createMockCustomerInfo());
        });
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
                  code: 1,
                  message: 'Success',
                  data: SubscriptionModel.free(),
                ));

        await subscriptionService.init();

        await subscriptionService.onUserLoggedIn();

        verify(mockRevenueCatService.logIn('user-123')).called(1);
      });

      test('fetches subscription from backend after RC logIn', () async {
        when(mockAuthStorage.getUserId()).thenAnswer((_) async => 'user-123');
        when(mockRevenueCatService.isConfigured).thenReturn(true);
        when(mockRevenueCatService.logIn('user-123')).thenAnswer((_) async {
          return LogInResult(
              created: true, customerInfo: _createMockCustomerInfo());
        });
        final premiumSub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.active,
          isActive: true,
        );
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
                  code: 1,
                  message: 'Success',
                  data: premiumSub,
                ));

        await subscriptionService.init();

        await subscriptionService.onUserLoggedIn();

        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.monthly));
      });

      test('skips RC logIn when userId is null', () async {
        when(mockAuthStorage.getUserId()).thenAnswer((_) async => null);
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        await subscriptionService.init();

        await subscriptionService.onUserLoggedIn();

        verifyNever(mockRevenueCatService.logIn(any));
      });

      test('skips RC logIn when RC not configured', () async {
        when(mockAuthStorage.getUserId()).thenAnswer((_) async => 'user-123');
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
                  code: 1,
                  message: 'Success',
                  data: SubscriptionModel.free(),
                ));

        await subscriptionService.init();

        await subscriptionService.onUserLoggedIn();

        verifyNever(mockRevenueCatService.logIn(any));
      });
    });

    group('onUserLoggedOut()', () {
      test('calls RC logOut when RC is configured', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(true);
        when(mockRevenueCatService.logOut())
            .thenAnswer((_) async => _createMockCustomerInfo());

        await subscriptionService.init();

        await subscriptionService.onUserLoggedOut();

        verify(mockRevenueCatService.logOut()).called(1);
      });

      test('resets subscription to free after logout', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(true);
        final premiumSub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.active,
          isActive: true,
        );
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
                  code: 1,
                  message: 'Success',
                  data: premiumSub,
                ));
        when(mockRevenueCatService.logOut())
            .thenAnswer((_) async => _createMockCustomerInfo());

        await subscriptionService.init();
        await subscriptionService.fetchSubscriptionFromBackend();
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.monthly));

        await subscriptionService.onUserLoggedOut();

        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.free));
      });

      test('skips RC logOut when RC not configured', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        await subscriptionService.init();

        await subscriptionService.onUserLoggedOut();

        verifyNever(mockRevenueCatService.logOut());
      });
    });

    group('fetchSubscriptionFromBackend()', () {
      test('updates state on successful API response', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        final backendSub = SubscriptionModel(
          id: 'sub-456',
          plan: SubscriptionPlan.yearly,
          status: SubscriptionStatus.active,
          isActive: true,
        );
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
                  code: 1,
                  message: 'Success',
                  data: backendSub,
                ));

        await subscriptionService.init();

        await subscriptionService.fetchSubscriptionFromBackend();

        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.yearly));
        expect(subscriptionService.currentSubscription.value.isActive, isTrue);
      });

      test('retains current state on API error', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenThrow(Exception('Network error'));

        await subscriptionService.init();

        await subscriptionService.fetchSubscriptionFromBackend();

        // Pre-fetch state was default free; error must not flip to any other state.
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.free));
      });

      test('ignores null API response data', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        await subscriptionService.init();

        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
                  code: 1,
                  message: 'Success',
                  data: null,
                ));

        await subscriptionService.fetchSubscriptionFromBackend();

        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.free));
      });
    });

    group('isPremium getter', () {
      test('returns true for active premium subscriptions', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        final premiumSub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.active,
          isActive: true,
        );
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
                  code: 1,
                  message: 'Success',
                  data: premiumSub,
                ));

        await subscriptionService.init();
        await subscriptionService.fetchSubscriptionFromBackend();

        expect(subscriptionService.isPremium, isTrue);
      });

      test('returns false for free tier', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        await subscriptionService.init();

        expect(subscriptionService.isPremium, isFalse);
      });

      test('returns false for inactive premium subscriptions', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        final inactiveSub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.expired,
          isActive: false,
        );
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
                  code: 1,
                  message: 'Success',
                  data: inactiveSub,
                ));

        await subscriptionService.init();
        await subscriptionService.fetchSubscriptionFromBackend();

        expect(subscriptionService.isPremium, isFalse);
      });
    });

    group('currentPlan getter', () {
      test('returns current subscription plan', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        final monthlySub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.active,
          isActive: true,
        );
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
                  code: 1,
                  message: 'Success',
                  data: monthlySub,
                ));

        await subscriptionService.init();
        await subscriptionService.fetchSubscriptionFromBackend();

        expect(subscriptionService.currentPlan,
            equals(SubscriptionPlan.monthly));
      });
    });

    group('onClose cleanup', () {
      test('cancels customer info subscription on close', () async {
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        await subscriptionService.init();

        subscriptionService.onClose();

        expect(subscriptionService, isNotNull);
      });
    });
  });
}

/// Helper to create mock CustomerInfo with required parameters
CustomerInfo _createMockCustomerInfo() {
  return CustomerInfo(
    EntitlementInfos({}, {}), // entitlements
    {}, // allPurchaseDates
    [], // activeSubscriptions
    [], // allPurchasedProductIdentifiers
    [], // nonSubscriptionTransactions
    '2026-03-14T00:00:00Z', // firstSeen
    'test-user', // originalAppUserId
    {}, // allExpirationDates
    '2026-03-14T00:00:00Z', // requestDate
    latestExpirationDate: null,
    originalPurchaseDate: null,
  );
}
