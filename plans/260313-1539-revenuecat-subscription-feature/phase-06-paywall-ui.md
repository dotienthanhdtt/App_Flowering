# Phase 6: Paywall UI

## Context Links
- [Brainstorm](../reports/brainstorm-260313-revenuecat-payment-feature.md) — UX requirements
- Design file: `design.pen` (check via Pencil MCP tools for subscription/paywall screens)

## Overview
- **Priority:** High
- **Status:** Pending
- **Description:** Create paywall screen, bottom sheet modal, plan card widget, and subscription status widget. Two entry points: settings screen link + bottom sheet triggered by feature gates.

## Requirements
- PaywallScreen: full-screen paywall accessible from settings
- PaywallBottomSheet: modal triggered by feature gates
- PlanCardWidget: displays individual plan offering
- SubscriptionStatusWidget: shows current plan in settings/profile
- Restore purchases button (mandatory for iOS review)
- Loading and error states
- Translations for all user-facing strings

## Related Code Files

### Files to Create
- `lib/features/subscription/views/paywall-screen.dart`
- `lib/features/subscription/widgets/paywall-bottom-sheet.dart`
- `lib/features/subscription/widgets/plan-card-widget.dart`
- `lib/features/subscription/widgets/subscription-status-widget.dart`

### Files to Modify
- `lib/app/routes/app-route-constants.dart` — add paywall route
- `lib/app/routes/app-page-definitions-with-transitions.dart` — add paywall page
- `lib/features/settings/views/*.dart` — add subscription status + paywall link
- `lib/l10n/english-translations-en-us.dart` — add subscription strings
- `lib/l10n/vietnamese-translations-vi-vn.dart` — add subscription strings

### Dependencies
- Phase 5: Controllers
- Check `design.pen` for UI design reference

## Implementation Steps

1. **Add route:**
   ```dart
   // app-route-constants.dart
   static const String paywall = '/paywall';
   ```

2. **Add page definition:**
   ```dart
   GetPage(
     name: AppRoutes.paywall,
     page: () => const PaywallScreen(),
     binding: SubscriptionBinding(),
   ),
   ```

3. **PlanCardWidget:** Displays plan name, price, period, features. Highlights selected/recommended plan. Handles tap to select.

4. **PaywallScreen:** Full-screen with:
   - Header/hero section
   - List of PlanCardWidgets from offerings
   - Purchase button (primary CTA)
   - Restore purchases link
   - Terms/privacy links
   - Loading overlay during purchase

5. **PaywallBottomSheet:** Compact modal version:
   ```dart
   class PaywallBottomSheet {
     static Future<void> show() async {
       Get.bottomSheet(
         // Compact paywall with offerings + purchase button
         isScrollControlled: true,
         backgroundColor: Colors.transparent,
       );
     }
   }
   ```

6. **SubscriptionStatusWidget:** Shows current plan badge in settings.

7. **Add translations:**
   ```dart
   // English
   'subscription_title': 'Upgrade to Premium',
   'subscription_restore': 'Restore Purchases',
   'subscription_current_plan': 'Current Plan',
   'subscription_free_plan': 'Free',
   'subscription_monthly': 'Monthly',
   'subscription_yearly': 'Yearly',
   'subscription_lifetime': 'Lifetime',
   'subscription_purchase_button': 'Subscribe Now',
   'subscription_terms': 'Terms & Conditions',
   'subscription_privacy': 'Privacy Policy',
   // Vietnamese equivalents
   ```

8. **Integrate into settings:** Add subscription status + tap to open paywall.

9. **Verify:** `flutter analyze`

## Todo List
- [ ] Add paywall route and page definition
- [ ] Create plan-card-widget.dart
- [ ] Create paywall-screen.dart
- [ ] Create paywall-bottom-sheet.dart
- [ ] Create subscription-status-widget.dart
- [ ] Add translations (EN + VI)
- [ ] Integrate into settings screen
- [ ] Check design.pen for reference (Pencil MCP tools)
- [ ] Run `flutter analyze`

## Success Criteria
- Paywall displays dynamic offerings from RevenueCat
- Purchase flow works with loading/error feedback
- Restore purchases accessible
- Bottom sheet can be triggered programmatically
- All strings translated

## Risk Assessment
- **iOS review:** Must have restore button + subscription terms — both included
- **Empty offerings:** Show error state with retry

## Next Steps
- Phase 7: Feature Gating
