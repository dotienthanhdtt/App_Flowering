---
phase: 6
title: "Feature - Auth"
status: pending
effort: 2h
depends_on: [5]
---

# Phase 6: Feature - Auth

## Context Links

- [Main Plan](./plan.md)
- [GetX Research](./research/researcher-getx-patterns.md)
- Depends on: [Phase 5](./phase-05-routing-localization.md)

## Overview

**Priority:** P1 - Core Feature
**Status:** pending
**Description:** Implement authentication feature with login, register screens and auth controller.

## Key Insights

- AuthController manages login state globally
- Tokens stored via AuthStorage (Phase 3)
- Navigation guards redirect unauthenticated users
- Form validation using Validators (Phase 4)

## Requirements

### Functional
- Login with email/password
- Register with email/password/name
- Logout with confirmation
- Auto-redirect to home on successful login
- Redirect to login when token expires

### Non-Functional
- Loading state during API calls
- Error messages for validation/API errors
- Smooth transitions between auth screens

## Architecture

```
features/auth/
├── bindings/
│   └── auth_binding.dart
├── controllers/
│   └── auth_controller.dart
├── views/
│   ├── login_screen.dart
│   └── register_screen.dart
└── widgets/
    └── auth_form.dart
```

## Related Code Files

### Files to Create
- `lib/features/auth/bindings/auth_binding.dart`
- `lib/features/auth/controllers/auth_controller.dart`
- `lib/features/auth/views/login_screen.dart`
- `lib/features/auth/views/register_screen.dart`
- `lib/features/auth/widgets/auth_form.dart`

### Files to Modify
- `lib/app/routes/app_pages.dart` - Uncomment auth imports and bindings

## Implementation Steps

### Step 1: Create auth_binding.dart

```dart
// lib/features/auth/bindings/auth_binding.dart
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
```

### Step 2: Create auth_controller.dart

```dart
// lib/features/auth/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/auth_storage.dart';
import '../../../shared/models/user_model.dart';
import '../../../app/routes/app_routes.dart';

class AuthController extends BaseController {
  final ApiClient _api = Get.find();
  final AuthStorage _authStorage = Get.find();

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  // Form key for validation
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();

  // User state
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  bool get isLoggedIn => _authStorage.isLoggedIn;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.onClose();
  }

  /// Login with email and password
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    final result = await apiCall(() async {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
      );

      if (response.isSuccess && response.data != null) {
        await _authStorage.saveTokens(
          accessToken: response.data!['access_token'] as String,
          refreshToken: response.data!['refresh_token'] as String,
        );

        if (response.data!['user'] != null) {
          currentUser.value = UserModel.fromJson(
            response.data!['user'] as Map<String, dynamic>,
          );
          await _authStorage.saveUserId(currentUser.value!.id);
        }

        return response;
      }

      throw Exception(response.message);
    });

    if (result != null) {
      _clearForms();
      showSuccess('login_success'.tr);
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Register new account
  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) return;

    final result = await apiCall(() async {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'password_confirmation': confirmPasswordController.text,
        },
      );

      if (response.isSuccess && response.data != null) {
        await _authStorage.saveTokens(
          accessToken: response.data!['access_token'] as String,
          refreshToken: response.data!['refresh_token'] as String,
        );

        if (response.data!['user'] != null) {
          currentUser.value = UserModel.fromJson(
            response.data!['user'] as Map<String, dynamic>,
          );
          await _authStorage.saveUserId(currentUser.value!.id);
        }

        return response;
      }

      throw Exception(response.message);
    });

    if (result != null) {
      _clearForms();
      showSuccess('register_success'.tr);
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('logout'.tr),
        content: Text('logout_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await apiCall(
      () async {
        // Call logout API (optional, for invalidating token server-side)
        try {
          await _api.post(ApiEndpoints.logout);
        } catch (_) {
          // Ignore API errors on logout
        }

        await _authStorage.clearTokens();
        currentUser.value = null;

        return true;
      },
      showLoading: false,
    );

    Get.offAllNamed(AppRoutes.login);
  }

  /// Navigate to register screen
  void goToRegister() {
    _clearForms();
    Get.toNamed(AppRoutes.register);
  }

  /// Navigate to login screen
  void goToLogin() {
    _clearForms();
    Get.back();
  }

  void _clearForms() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    nameController.clear();
  }
}
```

### Step 3: Create login_screen.dart

```dart
// lib/features/auth/views/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends BaseScreen<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: controller.loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),

            // Logo/Title
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.local_florist,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    'app_name'.tr,
                    variant: AppTextVariant.h1,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Email field
            AppTextField(
              label: 'email'.tr,
              hint: 'Enter your email',
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              prefixIcon: const Icon(Icons.email_outlined),
            ),

            const SizedBox(height: 16),

            // Password field
            AppTextField(
              label: 'password'.tr,
              hint: 'Enter your password',
              controller: controller.passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: Validators.password,
              prefixIcon: const Icon(Icons.lock_outlined),
              onSubmitted: (_) => controller.login(),
            ),

            const SizedBox(height: 8),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password
                },
                child: Text('forgot_password'.tr),
              ),
            ),

            const SizedBox(height: 24),

            // Login button
            AppButton(
              text: 'login'.tr,
              onPressed: controller.login,
            ),

            const SizedBox(height: 24),

            // Register link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  'dont_have_account'.tr,
                  variant: AppTextVariant.bodyMedium,
                  color: AppColors.textSecondary,
                ),
                TextButton(
                  onPressed: controller.goToRegister,
                  child: Text('register'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 4: Create register_screen.dart

```dart
// lib/features/auth/views/register_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends BaseScreen<AuthController> {
  const RegisterScreen({super.key});

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('register'.tr),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: controller.registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // Name field
            AppTextField(
              label: 'Name',
              hint: 'Enter your name',
              controller: controller.nameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.required(value, 'Name'),
              prefixIcon: const Icon(Icons.person_outlined),
            ),

            const SizedBox(height: 16),

            // Email field
            AppTextField(
              label: 'email'.tr,
              hint: 'Enter your email',
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              prefixIcon: const Icon(Icons.email_outlined),
            ),

            const SizedBox(height: 16),

            // Password field
            AppTextField(
              label: 'password'.tr,
              hint: 'Enter your password',
              controller: controller.passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
              prefixIcon: const Icon(Icons.lock_outlined),
            ),

            const SizedBox(height: 16),

            // Confirm password field
            AppTextField(
              label: 'confirm_password'.tr,
              hint: 'Confirm your password',
              controller: controller.confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (value) => Validators.confirmPassword(
                value,
                controller.passwordController.text,
              ),
              prefixIcon: const Icon(Icons.lock_outlined),
              onSubmitted: (_) => controller.register(),
            ),

            const SizedBox(height: 32),

            // Register button
            AppButton(
              text: 'register'.tr,
              onPressed: controller.register,
            ),

            const SizedBox(height: 24),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  'already_have_account'.tr,
                  variant: AppTextVariant.bodyMedium,
                  color: AppColors.textSecondary,
                ),
                TextButton(
                  onPressed: controller.goToLogin,
                  child: Text('login'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 5: Create auth_form.dart (optional reusable widget)

```dart
// lib/features/auth/widgets/auth_form.dart
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../core/utils/validators.dart';

/// Reusable auth form fields
class AuthEmailField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const AuthEmailField({
    super.key,
    required this.controller,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Email',
      hint: 'Enter your email',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction ?? TextInputAction.next,
      validator: Validators.email,
      prefixIcon: const Icon(Icons.email_outlined),
      onSubmitted: onSubmitted,
    );
  }
}

class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const AuthPasswordField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label ?? 'Password',
      hint: hint ?? 'Enter your password',
      controller: controller,
      obscureText: true,
      textInputAction: textInputAction ?? TextInputAction.done,
      validator: validator ?? Validators.password,
      prefixIcon: const Icon(Icons.lock_outlined),
      onSubmitted: onSubmitted,
    );
  }
}
```

### Step 6: Update app_pages.dart

Update the imports and page definitions to use real screens:

```dart
// In lib/app/routes/app_pages.dart - update these sections:

import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';

// Update the auth pages:
GetPage(
  name: AppRoutes.login,
  page: () => const LoginScreen(),
  binding: AuthBinding(),
  transition: Transition.fade,
  transitionDuration: defaultDuration,
),
GetPage(
  name: AppRoutes.register,
  page: () => const RegisterScreen(),
  binding: AuthBinding(),
  transition: defaultTransition,
  transitionDuration: defaultDuration,
  curve: defaultCurve,
),
```

## Todo List

- [ ] Create auth_binding.dart
- [ ] Create auth_controller.dart with login/register/logout
- [ ] Create login_screen.dart with form
- [ ] Create register_screen.dart with form
- [ ] Create auth_form.dart with reusable fields
- [ ] Update app_pages.dart with real screens
- [ ] Test login flow end-to-end
- [ ] Test register flow end-to-end
- [ ] Test logout with confirmation

## Success Criteria

- Login form validates email/password
- Register form validates all fields including password match
- Loading overlay shows during API calls
- Error messages display for validation failures
- Successful login navigates to home
- Logout clears tokens and navigates to login

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Token not saved properly | High | Test with debugger, verify Hive box |
| Form validation bypassed | Medium | Always call validate() before submit |
| Memory leak from controllers | Medium | Dispose TextEditingControllers in onClose |

## Security Considerations

- Password field obscured by default
- Tokens cleared on logout
- No password stored locally
- Confirm password not sent to API (just for validation)

## Next Steps

After completion, proceed to [Phase 7: Home Feature](./phase-07-feature-home.md).
