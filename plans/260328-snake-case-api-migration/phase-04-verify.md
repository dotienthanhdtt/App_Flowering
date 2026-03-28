# Phase 4: Verify & Test

## Overview
- **Priority:** P1
- **Status:** pending
- Compile check, static analysis, and test suite.

---

## Steps

1. **Compile check**: `flutter analyze` -- fix any type errors from model changes
2. **Run tests**: `flutter test` -- fix any broken assertions
3. **Manual smoke test** with dev backend:
   - Register / Login flow
   - Onboarding chat flow
   - Subscription fetch
   - Translation (word + sentence)
   - Grammar correction
   - Forgot password flow
4. **Cache migration test**: Install old version, generate cached data, update to new version, verify no crashes

---

## Todo

- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Smoke test auth flows
- [ ] Smoke test onboarding flow
- [ ] Smoke test translation/grammar
- [ ] Smoke test subscription
- [ ] Test cache backward compatibility
