---
phase: 2
title: "Migrate all existing controllers and screens to base classes"
status: pending
priority: P1
effort: 2h45m
---

## Context Links

- Base classes: `lib/core/base/base_controller.dart`, `lib/core/base/base_screen.dart`
- Phase 1: `phase-01-update-rules.md`

## Overview

Migrate 6 controllers to extend `BaseController` and 16 screens to use `BaseScreen`/`BaseStatelessScreen` (or document exemptions).

## Key Insights

- `AuthController` and `ForgotPasswordController` both define their own `isLoading` and `errorMessage` -- these MUST be removed (BaseController provides them)
- `AiChatController` defines `isLoading` and `errorMessage` -- same, must remove
- `OnboardingController` defines `isLoadingLanguages` (different name) -- this is fine, keep it. It does NOT have `isLoading`/`errorMessage` so no conflict
- `MainShellController` and `SplashController` are simple -- no conflicts
- Tab child screens (`VocabularyScreen`, `ProfileScreen`, `ChatHomeScreen`, `ReadScreen`) are embedded in `MainShellScreen`'s `IndexedStack` -- they MUST NOT use `BaseScreen` (would nest Scaffolds). Keep as `StatelessWidget`
- `WelcomeProblemScreen` is a `StatefulWidget` -- exempt, add comment

---

## Part A: Controller Migration (6 controllers)

### A1. `MainShellController` -- SIMPLE

**File:** `lib/features/home/controllers/main-shell-controller.dart`

**Changes:**
1. Change `import 'package:get/get.dart';` -- keep it (BaseController re-exports it)
2. Add `import '../../../core/base/base_controller.dart';`
3. Change `extends GetxController` to `extends BaseController`

**No conflicts:** Does not define `isLoading` or `errorMessage`.

---

### A2. `AuthController` -- HAS CONFLICTS

**File:** `lib/features/auth/controllers/auth_controller.dart`

**Changes:**
1. Add `import '../../../core/base/base_controller.dart';`
2. Change `extends GetxController` to `extends BaseController`
3. **REMOVE line 18:** `final isLoading = false.obs;` -- inherited from BaseController
4. **REMOVE line 19:** `final errorMessage = ''.obs;` -- inherited from BaseController
5. Refactor `register()` and `login()` methods -- they can optionally use `apiCall()` wrapper, BUT since they have custom form validation + custom error handling + custom success logic, it is simpler to keep manual try/catch and just use inherited `isLoading`/`errorMessage`. The existing code already sets `isLoading.value` and `errorMessage.value` which will now reference inherited fields. **No code change needed beyond removing the declarations.**

**Verification:** All usages of `isLoading.value` and `errorMessage.value` in this file will now reference BaseController's fields. Behavior identical.

---

### A3. `ForgotPasswordController` -- HAS CONFLICTS

**File:** `lib/features/auth/controllers/forgot_password_controller.dart`

**Changes:**
1. Add `import '../../../core/base/base_controller.dart';`
2. Change `extends GetxController` to `extends BaseController`
3. **REMOVE line 14:** `final isLoading = false.obs;` -- inherited
4. **REMOVE line 15:** `final errorMessage = ''.obs;` -- inherited

**No other changes needed.** All methods set `isLoading.value` and `errorMessage.value` directly, which will now reference inherited fields.

---

### A4. `SplashController` -- SIMPLE

**File:** `lib/features/onboarding/controllers/splash_controller.dart`

**Changes:**
1. Add `import '../../../core/base/base_controller.dart';`
2. Change `extends GetxController` to `extends BaseController`

**No conflicts:** Does not define `isLoading` or `errorMessage`.

---

### A5. `AiChatController` -- HAS CONFLICTS

**File:** `lib/features/chat/controllers/ai_chat_controller.dart`

**Changes:**
1. Add `import '../../../core/base/base_controller.dart';`
2. Change `extends GetxController` to `extends BaseController`
3. **REMOVE line 25:** `final isLoading = false.obs;` -- inherited
4. **REMOVE line 28:** `final errorMessage = ''.obs;` -- inherited

**Keep:** `isTyping`, `isChatComplete`, `progress`, `isRecording`, `recordingDuration` -- these are chat-specific, not in BaseController.

---

### A6. `OnboardingController` -- SIMPLE

**File:** `lib/features/onboarding/controllers/onboarding_controller.dart`

**Changes:**
1. Add `import '../../../core/base/base_controller.dart';`
2. Change `extends GetxController` to `extends BaseController`

**No conflicts:** Has `isLoadingLanguages` (different name), no `isLoading` or `errorMessage`.

---

## Part B: Screen Migration (16 screens)

### Decision Matrix

| Screen | Has Controller? | Is Tab Child? | Is StatefulWidget? | Action |
|--------|----------------|---------------|--------------------|----|
| MainShellScreen | MainShellController | No (is shell) | No | Migrate to `BaseScreen<MainShellController>` |
| VocabularyScreen | VocabularyController | YES (tab) | No | **EXEMPT** -- tab child, keep StatelessWidget |
| ProfileScreen | ProfileController | YES (tab) | No | **EXEMPT** -- tab child, keep StatelessWidget |
| ChatHomeScreen | ChatHomeController | YES (tab) | No | **EXEMPT** -- tab child, keep StatelessWidget |
| ReadScreen | ReadController | YES (tab) | No | **EXEMPT** -- tab child, keep StatelessWidget |
| ForgotPasswordScreen | ForgotPasswordController | No | No | Migrate to `BaseScreen<ForgotPasswordController>` |
| NewPasswordScreen | ForgotPasswordController | No | No | Migrate to `BaseScreen<ForgotPasswordController>` |
| LoginEmailScreen | AuthController | No | No | Migrate to `BaseScreen<AuthController>` |
| SignupEmailScreen | AuthController | No | No | Migrate to `BaseScreen<AuthController>` |
| OtpVerificationScreen | ForgotPasswordController | No | No | Migrate to `BaseScreen<ForgotPasswordController>` |
| AiChatScreen | AiChatController | No | No | Migrate to `BaseScreen<AiChatController>` |
| SplashScreen | SplashController | No | No | Migrate to `BaseScreen<SplashController>` |
| WelcomeProblemScreen | None | No | YES | **EXEMPT** -- StatefulWidget |
| NativeLanguageScreen | OnboardingController | No | No | Migrate to `BaseScreen<OnboardingController>` |
| ScenarioGiftScreen | OnboardingController | No | No | Migrate to `BaseScreen<OnboardingController>` |
| LearningLanguageScreen | OnboardingController | No | No | Migrate to `BaseScreen<OnboardingController>` |

**Summary:** 10 screens to migrate, 4 tab-child exemptions, 1 StatefulWidget exemption, 1 shell screen to migrate.

---

### B1. `MainShellScreen` -- shell with IndexedStack

**File:** `lib/features/home/views/main-shell-screen.dart`

**Current:** `extends StatelessWidget`, uses `Get.find<MainShellController>()`, manual Scaffold

**Migration:**
1. Add imports for BaseScreen and MainShellController
2. Change to `extends BaseScreen<MainShellController>`
3. Remove `build()`, replace with `buildContent()` returning the IndexedStack body
4. Override `buildBottomNav()` to return `const BottomNavBar()`
5. Set `bool get useSafeArea => false;` (tab children handle their own SafeArea)
6. Set `bool get showLoadingOverlay => false;` (MainShellController is not an API controller)
7. Remove `Get.find<MainShellController>()` -- use `controller` from GetView

**Resulting code:**
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../chat/views/chat-home-screen.dart';
import '../../lessons/views/read-screen.dart';
import '../../vocabulary/views/vocabulary-screen.dart';
import '../../profile/views/profile-screen.dart';
import '../controllers/main-shell-controller.dart';
import '../widgets/bottom-nav-bar.dart';

class MainShellScreen extends BaseScreen<MainShellController> {
  const MainShellScreen({super.key});

  @override
  bool get useSafeArea => false;

  @override
  bool get showLoadingOverlay => false;

  @override
  Widget? buildBottomNav(BuildContext context) => const BottomNavBar();

  @override
  Widget buildContent(BuildContext context) {
    return Obx(() => IndexedStack(
      index: controller.selectedIndex.value,
      children: const [
        ChatHomeScreen(),
        ReadScreen(),
        VocabularyScreen(),
        ProfileScreen(),
      ],
    ));
  }
}
```

---

### B2. `SplashScreen`

**File:** `lib/features/onboarding/views/splash_screen.dart`

**Current:** `extends StatelessWidget`, no `Get.find`, manual Scaffold

**Migration:**
1. Change to `extends BaseScreen<SplashController>`
2. Add imports
3. Set `bool get useSafeArea => false;` (full-screen splash)
4. Set `bool get showLoadingOverlay => false;`
5. Override `backgroundColor => AppColors.primary`
6. Move body content to `buildContent()`
7. Wrap with `AnnotatedRegion` inside `buildContent()`

**Resulting code:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends BaseScreen<SplashController> {
  const SplashScreen({super.key});

  @override
  bool get useSafeArea => false;
  @override
  bool get showLoadingOverlay => false;
  @override
  Color? get backgroundColor => AppColors.primary;

  @override
  Widget buildContent(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logos/logo.png', width: 180, height: 180),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeIn,
              builder: (context, opacity, child) {
                return Opacity(opacity: opacity, child: child);
              },
              child: Column(
                children: [
                  const SizedBox(height: AppSizes.spacingL),
                  AppText('app_name'.tr, variant: AppTextVariant.h1,
                      fontSize: AppSizes.font10XL, color: Colors.white),
                  const SizedBox(height: AppSizes.spacingS),
                  AppText('splash_subtitle'.tr, variant: AppTextVariant.bodyLarge,
                      fontSize: AppSizes.fontL,
                      color: Colors.white.withValues(alpha: 0.8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### B3. `LoginEmailScreen`

**File:** `lib/features/auth/views/login_email_screen.dart`

**Migration:**
1. Change to `extends BaseScreen<AuthController>`
2. Set `bool get showLoadingOverlay => false;` (screen handles its own loading UI inline)
3. Set `Color? get backgroundColor => AppColors.background;`
4. Move Scaffold body content into `buildContent()`, remove the outer Scaffold/SafeArea (BaseScreen handles both)
5. Remove `Get.find<AuthController>()` -- use `controller`

**Note:** This screen has its own inline loading spinner in the submit button. BaseScreen's loading overlay is redundant, so disable it. The screen handles `isLoading` visually via `Obx`.

---

### B4. `SignupEmailScreen`

**File:** `lib/features/auth/views/signup_email_screen.dart`

**Same pattern as LoginEmailScreen:**
1. Change to `extends BaseScreen<AuthController>`
2. `showLoadingOverlay => false`, `backgroundColor => AppColors.background`
3. Move body into `buildContent()`, use `controller` instead of `ctrl`

---

### B5. `ForgotPasswordScreen`

**File:** `lib/features/auth/views/forgot_password_screen.dart`

**Migration:**
1. Change to `extends BaseScreen<ForgotPasswordController>`
2. `showLoadingOverlay => false`, `backgroundColor => AppColors.background`
3. Move body into `buildContent()`

---

### B6. `NewPasswordScreen`

**File:** `lib/features/auth/views/new_password_screen.dart`

**Same pattern as ForgotPasswordScreen.**

---

### B7. `OtpVerificationScreen`

**File:** `lib/features/auth/views/otp_verification_screen.dart`

**Same pattern as ForgotPasswordScreen.**

---

### B8. `AiChatScreen`

**File:** `lib/features/chat/views/ai_chat_screen.dart`

**Migration:**
1. Change to `extends BaseScreen<AiChatController>`
2. `showLoadingOverlay => false` (has custom loading), `backgroundColor => AppColors.background`
3. Move body into `buildContent()`, wrap with `AnnotatedRegion` inside
4. Remove `Get.find<AiChatController>()` -- use `controller`
5. Keep `_ErrorBanner` and `_ChatList` as private widget classes in same file (they are view-local helper widgets, not standalone screens)

---

### B9. `NativeLanguageScreen`

**File:** `lib/features/onboarding/views/native_language_screen.dart`

**Migration:**
1. Change to `extends BaseScreen<OnboardingController>`
2. `showLoadingOverlay => false`, `backgroundColor => AppColors.background`
3. Move body into `buildContent()`, remove Scaffold/SafeArea

---

### B10. `LearningLanguageScreen`

**File:** `lib/features/onboarding/views/learning_language_screen.dart`

**Same pattern as NativeLanguageScreen.**

---

### B11. `ScenarioGiftScreen`

**File:** `lib/features/onboarding/views/scenario_gift_screen.dart`

**Migration:**
1. Change to `extends BaseScreen<OnboardingController>`
2. `showLoadingOverlay => false`, `backgroundColor => AppColors.background`
3. Move body into `buildContent()`, wrap with `AnnotatedRegion` inside
4. Keep `_Header`, `_ScenarioGrid`, `_CtaButton` as private helpers in same file

---

### B-EXEMPT: Tab child screens (NO CHANGE)

These screens are rendered INSIDE `MainShellScreen`'s `IndexedStack`, which already has a Scaffold. Using `BaseScreen` would create nested Scaffolds.

**Add a comment to each file explaining the exemption:**

1. `lib/features/vocabulary/views/vocabulary-screen.dart` -- add comment: `/// Tab child screen — exempt from BaseScreen to avoid nested Scaffold`
2. `lib/features/profile/views/profile-screen.dart` -- same comment
3. `lib/features/chat/views/chat-home-screen.dart` -- same comment
4. `lib/features/lessons/views/read-screen.dart` -- same comment

### B-EXEMPT: `WelcomeProblemScreen` (NO CHANGE)

**File:** `lib/features/onboarding/views/welcome_problem_screen.dart`

This is a `StatefulWidget` needing `PageController` + `ValueNotifier` lifecycle. Exempt from base class. Add comment: `/// StatefulWidget — exempt from BaseScreen (needs State lifecycle for PageController)`

---

## Implementation Order

1. Migrate all 6 controllers first (Part A) -- compile check
2. Migrate screens one feature module at a time:
   - Auth screens (B3-B7) -- compile check
   - Chat screen (B8) -- compile check
   - Onboarding screens (B2, B9-B11) -- compile check
   - Shell screen (B1) -- compile check
3. Add exemption comments to tab-child screens and WelcomeProblemScreen
4. Run `flutter analyze` to verify no issues

## Todo List

- [ ] A1: Migrate MainShellController
- [ ] A2: Migrate AuthController (remove isLoading/errorMessage)
- [ ] A3: Migrate ForgotPasswordController (remove isLoading/errorMessage)
- [ ] A4: Migrate SplashController
- [ ] A5: Migrate AiChatController (remove isLoading/errorMessage)
- [ ] A6: Migrate OnboardingController
- [ ] Run `flutter analyze` after controller migration
- [ ] B3: Migrate LoginEmailScreen
- [ ] B4: Migrate SignupEmailScreen
- [ ] B5: Migrate ForgotPasswordScreen
- [ ] B6: Migrate NewPasswordScreen
- [ ] B7: Migrate OtpVerificationScreen
- [ ] B8: Migrate AiChatScreen
- [ ] B2: Migrate SplashScreen
- [ ] B9: Migrate NativeLanguageScreen
- [ ] B10: Migrate LearningLanguageScreen
- [ ] B11: Migrate ScenarioGiftScreen
- [ ] B1: Migrate MainShellScreen
- [ ] Add exemption comments to 4 tab-child screens + WelcomeProblemScreen
- [ ] Run `flutter analyze` -- zero errors
- [ ] Run `flutter test` -- all pass

## Success Criteria

- Zero controllers extend `GetxController` directly in `features/*/controllers/`
- All non-exempt screens extend `BaseScreen<T>` or `BaseStatelessScreen`
- Exempt screens have explanatory comments
- `flutter analyze` passes
- `flutter test` passes
- No nested Scaffold issues

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Removing `isLoading`/`errorMessage` breaks a view that uses local reference | High | Views already use `controller.isLoading` -- BaseController provides same field name and type (`RxBool`) |
| BaseScreen's SafeArea conflicts with screen's own SafeArea | Low | Set `useSafeArea => false` on screens that manage their own, or remove duplicate SafeArea from content |
| BaseScreen's Scaffold wrapping conflicts with AnnotatedRegion | Low | Put AnnotatedRegion inside buildContent(), it works fine inside Scaffold body |
| Auth screens' inline loading spinners conflict with LoadingOverlay | Low | Set `showLoadingOverlay => false` on these screens |
