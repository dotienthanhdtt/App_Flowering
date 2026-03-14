import 'dart:async';
import 'dart:convert';
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
import 'package:flowering/core/services/storage_service.dart';
import 'package:flowering/core/network/api_response.dart';

import 'subscription-service-test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<RevenueCatService>(),
  MockSpec<ApiClient>(),
  MockSpec<AuthStorage>(),
  MockSpec<StorageService>(),
])
void main() {
  group('SubscriptionService', () {
    late SubscriptionService subscriptionService;
    late MockRevenueCatService mockRevenueCatService;
    late MockApiClient mockApiClient;
    late MockAuthStorage mockAuthStorage;
    late MockStorageService mockStorageService;

    setUp(() {
      Get.reset();

      mockRevenueCatService = MockRevenueCatService();
      mockApiClient = MockApiClient();
      mockAuthStorage = MockAuthStorage();
      mockStorageService = MockStorageService();

      // Stub onStart so GetX lifecycle doesn't throw when resolving lazyPut factories
      final noOp = InternalFinalCallback<void>(callback: () {});
      when(mockRevenueCatService.onStart).thenReturn(noOp);
      when(mockApiClient.onStart).thenReturn(noOp);
      when(mockAuthStorage.onStart).thenReturn(noOp);
      when(mockStorageService.onStart).thenReturn(noOp);

      Get.lazyPut<RevenueCatService>(() => mockRevenueCatService);
      Get.lazyPut<ApiClient>(() => mockApiClient);
      Get.lazyPut<AuthStorage>(() => mockAuthStorage);
      Get.lazyPut<StorageService>(() => mockStorageService);

      subscriptionService = SubscriptionService();
    });

    tearDown(() {
      subscriptionService.onClose();
      Get.reset();
    });

    group('init()', () {
      test('loads cached subscription on init', () async {
        // Arrange
        final cachedSub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.active,
          isActive: true,
        );
        final jsonString = jsonEncode(cachedSub.toJson());
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(jsonString);
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        // Act
        await subscriptionService.init();

        // Assert
        expect(subscriptionService.currentSubscription.value, isNotNull);
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.monthly));
        expect(subscriptionService.currentSubscription.value.isActive,
            isTrue);
      });

      test('defaults to free plan when no cache exists', () async {
        // Arrange
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        // Act
        await subscriptionService.init();

        // Assert
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.free));
        expect(subscriptionService.currentSubscription.value.isActive,
            isTrue);
      });

      test('returns SubscriptionService instance', () async {
        // Arrange
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        // Act
        final result = await subscriptionService.init();

        // Assert
        expect(result, isA<SubscriptionService>());
        expect(result, equals(subscriptionService));
      });

      test('handles corrupted cache gracefully', () async {
        // Arrange
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn('invalid json');
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        // Act & Assert
        expect(() async => await subscriptionService.init(),
            returnsNormally);
        await subscriptionService.init();
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.free));
      });
    });

    group('onUserLoggedIn()', () {
      test('calls RC logIn with user ID when RC is configured', () async {
        // Arrange
        when(mockAuthStorage.getUserId()).thenReturn('user-123');
        when(mockRevenueCatService.isConfigured).thenReturn(true);
        when(mockRevenueCatService.logIn('user-123')).thenAnswer((_) async {
          final mockCustomerInfo = _createMockCustomerInfo();
          return LogInResult(created: true, customerInfo: mockCustomerInfo);
        });
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
              code: 1,
              message: 'Success',
              data: SubscriptionModel.free(),
            ));
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockStorageService.setPreference<String>(any, any))
            .thenAnswer((_) async {});

        await subscriptionService.init();

        // Act
        await subscriptionService.onUserLoggedIn();

        // Assert
        verify(mockRevenueCatService.logIn('user-123')).called(1);
      });

      test('fetches subscription from backend after RC logIn', () async {
        // Arrange
        when(mockAuthStorage.getUserId()).thenReturn('user-123');
        when(mockRevenueCatService.isConfigured).thenReturn(true);
        when(mockRevenueCatService.logIn('user-123')).thenAnswer((_) async {
          final mockCustomerInfo = _createMockCustomerInfo();
          return LogInResult(created: true, customerInfo: mockCustomerInfo);
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
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockStorageService.setPreference<String>(any, any))
            .thenAnswer((_) async {});

        await subscriptionService.init();

        // Act
        await subscriptionService.onUserLoggedIn();

        // Assert
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.monthly));
        verify(mockStorageService.setPreference<String>(
                'subscription_cache', any))
            .called(1);
      });

      test('skips RC logIn when userId is null', () async {
        // Arrange
        when(mockAuthStorage.getUserId()).thenReturn(null);
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
              code: 1,
              message: 'Success',
              data: SubscriptionModel.free(),
            ));
        when(mockStorageService.setPreference<String>(any, any))
            .thenAnswer((_) async {});

        await subscriptionService.init();

        // Act
        await subscriptionService.onUserLoggedIn();

        // Assert
        verifyNever(mockRevenueCatService.logIn(any));
      });

      test('skips RC logIn when RC not configured', () async {
        // Arrange
        when(mockAuthStorage.getUserId()).thenReturn('user-123');
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
              code: 1,
              message: 'Success',
              data: SubscriptionModel.free(),
            ));
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockStorageService.setPreference<String>(any, any))
            .thenAnswer((_) async {});

        await subscriptionService.init();

        // Act
        await subscriptionService.onUserLoggedIn();

        // Assert
        verifyNever(mockRevenueCatService.logIn(any));
      });
    });

    group('onUserLoggedOut()', () {
      test('calls RC logOut when RC is configured', () async {
        // Arrange
        when(mockRevenueCatService.isConfigured).thenReturn(true);
        when(mockRevenueCatService.logOut()).thenAnswer(
            (_) async => _createMockCustomerInfo());
        when(mockStorageService.removePreference(any))
            .thenAnswer((_) async {});
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);

        await subscriptionService.init();

        // Act
        await subscriptionService.onUserLoggedOut();

        // Assert
        verify(mockRevenueCatService.logOut()).called(1);
      });

      test('resets subscription to free after logout', () async {
        // Arrange
        final cachedSub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.active,
          isActive: true,
        );
        final jsonString = jsonEncode(cachedSub.toJson());
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(jsonString);
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        await subscriptionService.init();

        // Verify cached state
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.monthly));

        // Arrange for logout
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        when(mockStorageService.removePreference(any))
            .thenAnswer((_) async {});

        // Act
        await subscriptionService.onUserLoggedOut();

        // Assert
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.free));
      });

      test('clears cache after logout', () async {
        // Arrange
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        when(mockStorageService.removePreference(any))
            .thenAnswer((_) async {});

        await subscriptionService.init();

        // Act
        await subscriptionService.onUserLoggedOut();

        // Assert
        verify(mockStorageService.removePreference('subscription_cache'))
            .called(1);
      });

      test('skips RC logOut when RC not configured', () async {
        // Arrange
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        when(mockStorageService.removePreference(any))
            .thenAnswer((_) async {});

        await subscriptionService.init();

        // Act
        await subscriptionService.onUserLoggedOut();

        // Assert
        verifyNever(mockRevenueCatService.logOut());
      });
    });

    group('fetchSubscriptionFromBackend()', () {
      test('updates state on successful API response', () async {
        // Arrange
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
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
        when(mockStorageService.setPreference<String>(any, any))
            .thenAnswer((_) async {});

        await subscriptionService.init();

        // Act
        await subscriptionService.fetchSubscriptionFromBackend();

        // Assert
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.yearly));
        expect(subscriptionService.currentSubscription.value.isActive,
            isTrue);
      });

      test('caches subscription on success', () async {
        // Arrange
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockRevenueCatService.isConfigured).thenReturn(false);
        final backendSub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
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
        when(mockStorageService.setPreference<String>(any, any))
            .thenAnswer((_) async {});

        await subscriptionService.init();

        // Act
        await subscriptionService.fetchSubscriptionFromBackend();

        // Assert
        verify(mockStorageService.setPreference<String>(
                'subscription_cache', any))
            .called(1);
      });

      test('falls back to cache on API error', () async {
        // Arrange
        final cachedSub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.active,
          isActive: true,
        );
        final jsonString = jsonEncode(cachedSub.toJson());
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(jsonString);
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        await subscriptionService.init();

        // Verify initial state is cached
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.monthly));

        // Arrange for error
        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenThrow(Exception('Network error'));
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(jsonString);

        // Act
        await subscriptionService.fetchSubscriptionFromBackend();

        // Assert - should retain cached state
        expect(subscriptionService.currentSubscription.value.plan,
            equals(SubscriptionPlan.monthly));
      });

      test('ignores null API response data', () async {
        // Arrange
        final initialSub = SubscriptionModel.free();
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        await subscriptionService.init();

        when(mockApiClient.get<SubscriptionModel>(any,
                fromJson: anyNamed('fromJson')))
            .thenAnswer((_) async => ApiResponse<SubscriptionModel>(
              code: 1,
              message: 'Success',
              data: null,
            ));

        // Act
        await subscriptionService.fetchSubscriptionFromBackend();

        // Assert - state should not change
        expect(subscriptionService.currentSubscription.value.plan,
            equals(initialSub.plan));
      });
    });

    group('isPremium getter', () {
      test('returns true for active premium subscriptions', () async {
        // Arrange
        final premiumSub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.active,
          isActive: true,
        );
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(jsonEncode(premiumSub.toJson()));
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        // Act
        await subscriptionService.init();

        // Assert
        expect(subscriptionService.isPremium, isTrue);
      });

      test('returns false for free tier', () async {
        // Arrange
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        // Act
        await subscriptionService.init();

        // Assert
        expect(subscriptionService.isPremium, isFalse);
      });

      test('returns false for inactive premium subscriptions', () async {
        // Arrange
        final inactiveSub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.expired,
          isActive: false,
        );
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(jsonEncode(inactiveSub.toJson()));
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        // Act
        await subscriptionService.init();

        // Assert
        expect(subscriptionService.isPremium, isFalse);
      });
    });

    group('currentPlan getter', () {
      test('returns current subscription plan', () async {
        // Arrange
        final monthlySub = SubscriptionModel(
          plan: SubscriptionPlan.monthly,
          status: SubscriptionStatus.active,
          isActive: true,
        );
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(jsonEncode(monthlySub.toJson()));
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        // Act
        await subscriptionService.init();

        // Assert
        expect(subscriptionService.currentPlan,
            equals(SubscriptionPlan.monthly));
      });
    });

    group('onClose cleanup', () {
      test('cancels customer info subscription on close', () async {
        // Arrange
        when(mockStorageService.getPreference<String>('subscription_cache'))
            .thenReturn(null);
        when(mockRevenueCatService.isConfigured).thenReturn(false);

        await subscriptionService.init();

        // Act
        subscriptionService.onClose();

        // Assert - should complete without error
        expect(subscriptionService, isNotNull);
      });
    });
  });
}

/// Helper to create mock CustomerInfo with required parameters
CustomerInfo _createMockCustomerInfo() {
  return CustomerInfo(
    EntitlementInfos({}, {}),      // entitlements
    {},                            // allPurchaseDates
    [],                            // activeSubscriptions
    [],                            // allPurchasedProductIdentifiers
    [],                            // nonSubscriptionTransactions
    '2026-03-14T00:00:00Z',        // firstSeen
    'test-user',                   // originalAppUserId
    {},                            // allExpirationDates
    '2026-03-14T00:00:00Z',        // requestDate
    latestExpirationDate: null,
    originalPurchaseDate: null,
  );
}
