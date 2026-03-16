# RevenueCat Subscription Feature — Implementation Plan

**Date:** 2026-03-13
**Status:** Complete (all phases done — pending RevenueCat sandbox testing)
**Brainstorm:** [brainstorm-260313-revenuecat-payment-feature.md](../reports/brainstorm-260313-revenuecat-payment-feature.md)
**Research:** [researcher-260313-revenuecat-flutter-sdk.md](../reports/researcher-260313-revenuecat-flutter-sdk.md) | [researcher-260313-backend-subscription-api.md](../reports/researcher-260313-backend-subscription-api.md)

## Summary

Implement in-app subscriptions using RevenueCat SDK. Backend already has full integration (webhooks, subscription entity, plan management). This plan covers Flutter-side only: SDK setup, service layer, controllers, paywall UI, and feature gating.

## Architecture

```
RevenueCatService (SDK wrapper: init, logIn/logOut, purchase, restore)
    ↓
SubscriptionService (orchestrates RC + backend API, caches state)
    ↓
SubscriptionController (reactive UI state via GetX)
PaywallController (offerings, purchase flow, loading)
    ↓
PaywallScreen / PaywallBottomSheet / SubscriptionGate (UI + gating)
```

## Phases

| # | Phase | Status | Priority | Effort |
|---|-------|--------|----------|--------|
| 1 | [Platform Setup & Dependencies](phase-01-platform-setup-and-dependencies.md) | Complete | Critical | Small |
| 2 | [Models & API Endpoints](phase-02-models-and-api-endpoints.md) | Complete | Critical | Small |
| 3 | [RevenueCat Service](phase-03-revenuecat-service.md) | Complete | Critical | Medium |
| 4 | [Subscription Service](phase-04-subscription-service.md) | Complete | Critical | Medium |
| 5 | [Controllers](phase-05-controllers.md) | Complete | High | Medium |
| 6 | [Paywall UI](phase-06-paywall-ui.md) | Complete | High | Large |
| 7 | [Feature Gating Integration](phase-07-feature-gating-integration.md) | Complete | High | Medium |

## Dependencies

- Backend `GET /subscriptions/me` endpoint (exists)
- RevenueCat dashboard: products & offerings configured
- App Store / Play Store: products created
- RevenueCat API keys in `.env.dev` and `.env.prod`

## Key Decisions

- **Hybrid state**: RC SDK for instant UX, backend `/subscriptions/me` as source of truth
- **Hive cache**: Persist subscription state for offline access
- **Feature gating**: Client-side based on plan type from SubscriptionService
- **Entitlement ID**: Single entitlement `premium` covering all paid plans
