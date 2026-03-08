# Phase 05 — Auth Feature: Login Gate, Signup, Login (Screens 09-11)

## Overview
- **Priority:** P1
- **Status:** Completed
- **Effort:** 4h
- **Blocked by:** Phase 04

Build the authentication feature: Login Gate bottom sheet (09), Signup Email (10), Login Email (11).

## Key Insights

- Login Gate is a bottom sheet over dimmed Scenario Gift — not a separate route
- All auth endpoints receive `sessionToken` to link onboarding session with user account
- Social auth (Google/Apple) requires native SDK config — implement button UI with TODO stubs
- After successful auth → store tokens in AuthStorage → navigate to `/home`
- AuthController manages all auth state + API calls
- Signup validation: email format, password >= 8 chars, passwords match
- Login has "Forgot password?" → Screen 12

## Requirements

### Functional

**Screen 09 — Login Gate Bottom Sheet:**
- Overlay on Scenario Gift with dimmed background
- Apple sign-in button (iOS style)
- Google sign-in button
- "Sign up with email" button → Screen 10
- "Already have an account? Log in" link → Screen 11

**Screen 10 — Signup Email:**
- Fields: Full Name, Email, Password, Confirm Password
- Client-side validation
- `POST /auth/register` with `sessionToken`
- Handle 409 "Email already registered"
- On success → store tokens → `/home`

**Screen 11 — Login Email:**
- Fields: Email, Password
- `POST /auth/login` with `sessionToken`
- Social auth buttons (Apple + Google)
- "Forgot password?" link → Screen 12
- On success → store tokens → `/home`

### Non-functional
- Form validation messages via `.tr` translations
- Secure password field with visibility toggle
- Loading state on submit buttons

## Related Code Files

### Create
- `lib/features/auth/bindings/auth_binding.dart`
- `lib/features/auth/controllers/auth_controller.dart`
- `lib/features/auth/views/signup_email_screen.dart`
- `lib/features/auth/views/login_email_screen.dart`
- `lib/features/auth/widgets/login_gate_bottom_sheet.dart`
- `lib/features/auth/widgets/social_auth_button.dart`
- `lib/features/auth/widgets/auth_text_field.dart`

### Modify
- `lib/features/onboarding/views/scenario_gift_screen.dart` — wire CTA to LoginGateBottomSheet
- `lib/features/onboarding/widgets/onboarding_top_bar.dart` — wire "Log in" link

## Architecture

```
ScenarioGiftScreen
  → showModalBottomSheet → LoginGateBottomSheet
      ├── Apple button → TODO: sign_in_with_apple SDK
      ├── Google button → TODO: google_sign_in SDK
      ├── Email button → Get.toNamed(AppRoutes.signup)
      └── "Log in" link → Get.toNamed(AppRoutes.login)

SignupEmailScreen → AuthController.register()
  → POST /auth/register { fullName, email, password, sessionToken }
  → On success: AuthStorage.saveTokens() → Get.offAllNamed('/home')

LoginEmailScreen → AuthController.login()
  → POST /auth/login { email, password, sessionToken }
  → On success: AuthStorage.saveTokens() → Get.offAllNamed('/home')
```

## Implementation Steps

### 1. Create AuthController

```dart
class AuthController extends GetxController {
  final ApiClient _apiClient = Get.find();
  final AuthStorage _authStorage = Get.find();
  final StorageService _storageService = Get.find();

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Form fields
  final fullName = ''.obs;
  final email = ''.obs;
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;

  String? get _sessionToken =>
      _storageService.getPreference('onboarding_session_token');

  // Validation
  String? validateEmail(String? value) { ... }
  String? validatePassword(String? value) { ... }
  String? validateConfirmPassword(String? value) { ... }
  String? validateFullName(String? value) { ... }

  Future<void> register() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.post<AuthResponse>(
        ApiEndpoints.register,
        data: {
          'fullName': fullName.value,
          'email': email.value,
          'password': password.value,
          if (_sessionToken != null) 'sessionToken': _sessionToken,
        },
        fromJson: (data) => AuthResponse.fromJson(data),
      );
      if (response.isSuccess && response.data != null) {
        await _handleAuthSuccess(response.data!);
      }
    } on ValidationException catch (e) {
      errorMessage.value = e.firstError;
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() async {
    // Similar to register but with email + password only
  }

  Future<void> _handleAuthSuccess(AuthResponse auth) async {
    await _authStorage.saveTokens(auth.accessToken, auth.refreshToken);
    await _authStorage.saveUserId(auth.user.id);
    _storageService.removePreference('onboarding_session_token');
    Get.offAllNamed(AppRoutes.home);
  }

  // Social auth stubs
  Future<void> signInWithGoogle() async {
    // TODO: Implement when google_sign_in package is configured
  }

  Future<void> signInWithApple() async {
    // TODO: Implement when sign_in_with_apple package is configured
  }
}
```

### 2. Create AuthBinding

```dart
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
```

### 3. Create LoginGateBottomSheet

- DraggableScrollableSheet with 60% initial size
- Rounded top corners (24px radius)
- White background
- Content: logo/title, Apple button, Google button, email button, login link
- Use `SocialAuthButton` widget for Apple/Google

### 4. Create AuthTextField Widget

Reusable text field matching app design:
- 12px border radius, 16px horizontal padding, 1.5px border
- Label, hint, error text support
- Password visibility toggle
- Validation callback

### 5. Create SignupEmailScreen

Form with: fullName, email, password, confirmPassword
- `Form` widget with `GlobalKey<FormState>` for validation
- Submit button calls `controller.register()`
- "Already have an account? Log in" link at bottom

### 6. Create LoginEmailScreen

Form with: email, password
- Social auth buttons at top (Apple + Google)
- "or" divider
- Email/password fields
- "Forgot password?" link → Screen 12
- Submit button calls `controller.login()`

### 7. Wire OnboardingTopBar "Log in" Link

Update the TODO in `onboarding_top_bar.dart`:
```dart
onTap: () => Get.toNamed(AppRoutes.login),
```

## Todo List

- [ ] Create AuthController with register/login/social stubs
- [ ] Create AuthBinding
- [ ] Create LoginGateBottomSheet widget
- [ ] Create SocialAuthButton widget
- [ ] Create AuthTextField widget
- [ ] Create SignupEmailScreen
- [ ] Create LoginEmailScreen
- [ ] Wire Scenario Gift CTA to LoginGateBottomSheet
- [ ] Wire OnboardingTopBar "Log in" link
- [ ] Add form validation logic
- [ ] Handle 409 email exists error on signup
- [ ] Handle auth success → save tokens → navigate to /home
- [ ] Clear sessionToken after successful auth
- [ ] Run `flutter analyze`

## Success Criteria

- Login Gate shows as bottom sheet over Scenario Gift
- Signup form validates and submits to API
- Login form validates and submits to API
- Auth success saves tokens and navigates to /home
- sessionToken cleared after auth
- Social auth buttons present (with TODO handlers)

## Risk Assessment

- **Social auth SDK not configured** → buttons present but show "Coming soon" toast on tap
- **sessionToken null** → auth still works without linking (graceful degradation)
- **Form validation UX** → show errors inline under each field, not just top banner

## Security Considerations

- Passwords never logged
- sessionToken cleared after auth linking
- Tokens stored only in AuthStorage (Hive)

## Next Steps

→ Phase 06: Forgot Password Flow
