# Phase 2: Models & API Endpoints

## Context Links
- [Backend API Research](../reports/researcher-260313-backend-subscription-api.md)
- Backend DTO: `SubscriptionDto { id, plan, status, expiresAt, isActive, cancelAtPeriodEnd }`

## Overview
- **Priority:** Critical
- **Status:** Complete
- **Description:** Create Flutter models matching backend DTOs and add subscription API endpoints.

## Key Insights
- Backend returns: `{ code: 1, message: "...", data: { id, plan, status, expiresAt, isActive, cancelAtPeriodEnd } }`
- Plans enum: FREE, MONTHLY, YEARLY, LIFETIME
- Status enum: ACTIVE, EXPIRED, CANCELLED, TRIAL
- `isActive` is computed server-side: status == ACTIVE && (plan == LIFETIME || expiresAt > now)

## Requirements
- `SubscriptionModel` matching backend `SubscriptionDto`
- `SubscriptionPlan` and `SubscriptionStatus` enums
- `OfferingModel` wrapper for RevenueCat offerings (lightweight)
- API endpoint constant for `/subscriptions/me`

## Related Code Files

### Files to Modify
- `lib/core/constants/api_endpoints.dart` — add subscription endpoint

### Files to Create
- `lib/features/subscription/models/subscription-model.dart`
- `lib/features/subscription/models/offering-model.dart`

## Implementation Steps

1. **Add API endpoint:**
   ```dart
   // api_endpoints.dart
   static const String subscriptionMe = '/subscriptions/me';
   ```

2. **Create SubscriptionModel:**
   ```dart
   // subscription-model.dart
   enum SubscriptionPlan { free, monthly, yearly, lifetime }
   enum SubscriptionStatus { active, expired, cancelled, trial }

   class SubscriptionModel {
     final String? id;
     final SubscriptionPlan plan;
     final SubscriptionStatus status;
     final DateTime? expiresAt;
     final bool isActive;
     final bool cancelAtPeriodEnd;

     SubscriptionModel({...});

     factory SubscriptionModel.fromJson(Map<String, dynamic> json) => ...;
     factory SubscriptionModel.free() => SubscriptionModel(plan: SubscriptionPlan.free, ...);

     bool get isPremium => plan != SubscriptionPlan.free && isActive;
   }
   ```

3. **Create OfferingModel** (thin wrapper for RC Package display):
   ```dart
   // offering-model.dart
   class OfferingModel {
     final String identifier;
     final String title;
     final String description;
     final String priceString;
     final dynamic rcPackage; // RevenueCat Package reference

     OfferingModel({...});
     factory OfferingModel.fromRCPackage(Package package) => ...;
   }
   ```

4. **Verify:** `flutter analyze`

## Todo List
- [x] Add subscription endpoint to api_endpoints.dart
- [x] Create subscription-model.dart with enums + fromJson
- [x] Create offering-model.dart
- [x] Run `flutter analyze`

## Success Criteria
- Models correctly parse backend response format
- Enums match backend values (case-insensitive parsing)
- `flutter analyze` passes

## Next Steps
- Phase 3: RevenueCat Service
