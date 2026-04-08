# Auth Implementation Exploration Report

**Date:** April 4, 2026  
**Project:** Flowering Flutter App  
**Scope:** Complete authentication system analysis  
**Thoroughness:** Very Thorough

---

## Executive Summary

The Flutter app has a **partially implemented authentication system** with:
- ✅ Email/password auth (login/signup) fully implemented
- ✅ Forgot password flow (3-screen: email → OTP → reset) implemented
- ✅ Token storage and refresh mechanism in place
- ✅ Auth API endpoints defined
- ✅ Social auth UI components ready
- ⏳ Google/Apple sign-in SDKs installed but NOT implemented (TODO stubs)
- ✅ Firebase configuration present
- ✅ API interceptor for token handling

---

## 1. Google & Apple Sign-In Status

### Current State
**Both social auth methods are NOT yet implemented.**

**File:** `/lib/features/auth/controllers/auth_controller.dart` (lines 133-139)
```dart
// Social auth — implemented when native SDKs are configured
Future<void> signInWithGoogle() async {
  // TODO: implement google_sign_in
}

Future<void> signInWithApple() async {
  // TODO: implement sign_in_with_apple
}
```

### User Feedback
The app shows a "Coming Soon" snackbar when users tap social auth buttons:
**File:** `/lib/features/auth/widgets/login_gate_bottom_sheet.dart` (lines 15-24)
```dart
void _onSocialTap() {
  Get.snackbar(
    'auth_social_coming_soon'.tr,
    'auth_social_coming_soon_message'.tr,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(AppSizes.space4),
    backgroundColor: AppColors.surfaceColor,
    colorText: AppColors.textPrimaryColor,
  );
}
```

---

## 2. Auth Service Architecture

### Auth Controller
**File:** `/lib/features/auth/controllers/auth_controller.dart`
- Manages email/password authentication
- Form validation (email, password, full name)
- API calls to `/auth/register` and `/auth/login`
- Reads `onboarding_conversation_id` from StorageService to link sessions
- Handles auth success by saving tokens and navigating to `/home`
- Extends `BaseController` with GetX state management

**Key Methods:**
- `register()` — POST /auth/register with validation
- `login()` — POST /auth/login with validation
- `_handleAuthSuccess()` — saves tokens and navigates

### Auth Storage Service
**File:** `/lib/core/services/auth_storage.dart`
- Uses Hive for secure local storage
- Stores: `access_token`, `refresh_token`, `user_id`
- Provides getter methods and login state check
- Implements `GetxService` for dependency injection

**Key Methods:**
- `saveTokens(accessToken, refreshToken)` — save both tokens
- `getAccessToken()` — retrieve access token
- `getRefreshToken()` — retrieve refresh token
- `isLoggedIn` — check if user is authenticated

---

## 3. Auth API Calls

### Endpoints Defined
**File:** `/lib/core/constants/api_endpoints.dart`

```dart
// Email/Password Auth
static const String login = '/auth/login';
static const String register = '/auth/register';
static const String refreshToken = '/auth/refresh';
static const String logout = '/auth/logout';

// Social Auth (NOT YET IMPLEMENTED)
static const String loginGoogle = '/auth/google';     // POST
static const String loginApple = '/auth/apple';       // POST

// Password Recovery
static const String forgotPassword = '/auth/forgot-password';  // POST
static const String verifyOtp = '/auth/verify-otp';           // POST
static const String resetPassword = '/auth/reset-password';    // POST
```

### Request Format (Email/Password)

**POST /auth/register**
```json
{
  "name": "string",
  "email": "user@example.com",
  "password": "string",
  "conversation_id": "optional_string"
}
```

**POST /auth/login**
```json
{
  "email": "user@example.com",
  "password": "string",
  "conversation_id": "optional_string"
}
```

### Social Auth Endpoint Format (EXPECTED, NOT VERIFIED)
```json
POST /auth/google
{
  "idToken": "google_id_token",
  "accessToken": "google_access_token"
}

POST /auth/apple
{
  "identityToken": "apple_identity_token",
  "userIdentifier": "apple_user_id"
}
```

---

## 4. Auth Response Model

**File:** `/lib/features/auth/models/auth_response_model.dart`

```dart
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? json['accessToken'] ?? '',
      refreshToken: json['refresh_token'] ?? json['refreshToken'] ?? '',
      user: UserModel.fromJson(json['user']),
    );
  }
}
```

**Supports both snake_case and camelCase** from backend.

---

## 5. User Model

**File:** `/lib/shared/models/user_model.dart`

```dart
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? profilePicture;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

Handles both snake_case (`profile_picture`) and camelCase (`avatarUrl`) fields.

---

## 6. Auth Controller Logic

### Registration Flow
**File:** `/lib/features/auth/controllers/auth_controller.dart` (lines 63-92)

1. Validates form fields
2. POST to `/auth/register` with name, email, password, conversation_id
3. On success: calls `_handleAuthSuccess()` → saves tokens → navigates to `/home`
4. On failure: displays error message
5. Handles `ValidationException` and `ApiException`

### Login Flow
**File:** `/lib/features/auth/controllers/auth_controller.dart` (lines 94-120)

1. Validates form fields
2. POST to `/auth/login` with email, password, conversation_id
3. Same success/error handling as registration
4. No session linking (conversation_id optional)

### Forgot Password Flow
**File:** `/lib/features/auth/controllers/forgot_password_controller.dart`

1. **forgotPassword()** — POST `/auth/forgot-password` with email
2. **resendOtp()** — repeat forgot password request
3. **verifyOtp()** — POST `/auth/verify-otp` with email + otp → returns `reset_token`
4. **resetPassword()** — POST `/auth/reset-password` with reset_token + new password
5. Reset token stored in memory (not persisted)

---

## 7. API Interceptor (Token Handling)

**File:** `/lib/core/network/auth_interceptor.dart`

### Request Phase
- Adds `Authorization: Bearer {access_token}` to all requests (except `/auth/refresh`)
- Uses `QueuedInterceptor` to queue concurrent 401s

### Error Handling (401 Unauthorized)
1. If token refresh already in progress → waits for result
2. Calls `/auth/refresh` with refresh_token
3. On success → saves new tokens → retries original request
4. On failure → clears tokens → navigates to `/login`

### Key Implementation Details
- Separate Dio instance for refresh to avoid interceptor loop
- `_isRefreshing` flag prevents multiple concurrent refresh attempts
- Retry request includes new token in Authorization header

---

## 8. API Response Wrapper

**File:** `/lib/core/network/api_response.dart`

```dart
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code == 1;
  bool get isError => code != 1;
}
```

**Server Format:**
```json
{
  "code": 1,
  "message": "Success",
  "data": { "access_token": "...", "refresh_token": "...", "user": {...} }
}
```

---

## 9. Error Handling

**File:** `/lib/core/network/api_exceptions.dart`

Custom exception hierarchy:
- `NetworkException` — connection failed
- `TimeoutException` — request timeout
- `UnauthorizedException` — 401 status (session expired)
- `ForbiddenException` — 403 status
- `NotFoundException` — 404 status
- `ServerException` — 500+ status
- `ValidationException` — 422 status with field errors
- `ApiErrorException` — generic API error

Each includes `userMessage` for UI display.

---

## 10. Firebase Configuration

### iOS Configuration
**File:** `/ios/Runner/GoogleService-Info.plist`

```xml
<key>CLIENT_ID</key>
<string>898715197112-sgb3culvpmlsk755v9s0m066r6oesf58.apps.googleusercontent.com</string>

<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.898715197112-sgb3culvpmlsk755v9s0m066r6oesf58</string>

<key>PROJECT_ID</key>
<string>flowering-74b9e</string>

<key>BUNDLE_ID</key>
<string>edtech.language.flowering</string>

<key>IS_SIGNIN_ENABLED</key>
<true></true>
```

### Android Configuration
**File:** `/android/app/src/main/AndroidManifest.xml`
- No google-services.json found (expected location: `/android/app/google-services.json`)
- Standard Flutter app manifest with BILLING permission for RevenueCat

---

## 11. Pubspec Dependencies

**File:** `/pubspec.yaml`

### Auth-Related Dependencies
```yaml
# Social Auth
google_sign_in: ^6.2.2         # ✅ Installed but NOT implemented
sign_in_with_apple: ^6.1.4     # ✅ Installed but NOT implemented

# State Management
get: ^4.6.6

# Network
dio: ^5.4.0

# Local Storage
hive: ^2.2.3
hive_flutter: ^1.1.0
```

**Note:** No `firebase_auth` package installed. Implementation uses custom OAuth flow with backend API.

---

## 12. iOS Pods Configuration

**File:** `/ios/Podfile.lock` (excerpt)

Installed social auth pods:
- `google_sign_in_ios` (0.0.1) — Flutter plugin wrapper
- `GoogleSignIn` (~> 8.0) — Native Google Sign-In SDK
- `AppAuth` (>= 1.7.4) — OAuth 2.0 framework
- `sign_in_with_apple` (0.0.1) — Flutter plugin wrapper

All required dependencies are installed.

---

## 13. Auth UI Components

### Social Auth Button Widget
**File:** `/lib/features/auth/widgets/social_auth_button.dart`

- Generic button for Apple (dark style) or Google (outlined)
- Accepts provider enum and onTap callback
- Uses emoji icons (🍎 for Apple, 'G' for Google)

### Auth Text Field Widget
**File:** `/lib/features/auth/widgets/auth_text_field.dart`
- Reusable form field with label, hint, validation
- Password visibility toggle
- Custom styling matching app design

### Login Gate Bottom Sheet
**File:** `/lib/features/auth/widgets/login_gate_bottom_sheet.dart`

- Shown over Scenario Gift screen during onboarding
- Contains: Apple button, Google button, email signup button, login link
- Social buttons show "Coming Soon" snackbar

---

## 14. Auth Screens

### Login Gate (Screen 09)
**File:** `/lib/features/auth/widgets/login_gate_bottom_sheet.dart`
- Bottom sheet with Apple/Google/Email options
- Navigate to signup or login screens

### Signup Email (Screen 10)
**File:** `/lib/features/auth/views/signup_email_screen.dart`
- Full Name, Email, Password, Confirm Password fields
- Form validation with inline error messages
- Calls `AuthController.register()`
- Link to login screen

### Login Email (Screen 11)
**File:** `/lib/features/auth/views/login_email_screen.dart`
- Email, Password fields
- Social auth buttons (Apple/Google) at top
- "Forgot password?" link
- Calls `AuthController.login()`
- Link to signup screen

### Forgot Password (Screens 12-14)
**File:** `/lib/features/auth/controllers/forgot_password_controller.dart`
- Screen 12: Email input
- Screen 13: OTP verification with 47-second countdown
- Screen 14: New password input
- Masking of email for UX (e.g., "u***@example.com")

---

## 15. Dependency Injection

### Auth Binding
**File:** `/lib/features/auth/bindings/auth_binding.dart`

```dart
class AuthBinding extends Bindings {
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController());
  }
}
```

### Global Service Initialization
**File:** `/lib/app/global-dependency-injection-bindings.dart`

**Order (important for dependencies):**
1. `AuthStorage` — Hive box for tokens
2. `StorageService` — general preferences
3. `ConnectivityService` — network monitoring
4. `AudioService` — voice features
5. `ApiClient` — depends on AuthStorage
6. `RevenueCatService` — subscriptions
7. `SubscriptionService` — depends on multiple services
8. `TranslationService` — depends on ApiClient

---

## 16. Environment Configuration

**File:** `/lib/config/env_config.dart`

```dart
static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
static String get env => dotenv.env['ENV'] ?? 'development';
static bool get isDev => env == 'development';
static bool get isProd => env == 'production';
```

**.env.dev and .env.prod** exist but are not readable (empty or gitignored).

---

## 17. App Routes

**File:** `/lib/app/routes/app-route-constants.dart`

Auth-related routes:
```dart
static const String splash = '/';           // Splash
static const String login = '/login';       // Screen 11
static const String register = '/signup';   // Screen 10
static const String forgotPassword = '/forgot-password';
static const String otpVerification = '/otp-verification';
static const String newPassword = '/new-password';
```

Note: Login Gate (Screen 09) is a bottom sheet, not a route.

---

## 18. Main App Initialization

**File:** `/lib/main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Environment loading
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  await dotenv.load(fileName: '.env.$env');
  
  // Hive initialization
  await Hive.initFlutter();
  
  // Service initialization (AuthStorage + ApiClient setup)
  await initializeServices();
  
  runApp(const FloweringApp());
}
```

---

## Implementation Checklist (From Planning Docs)

**File:** `/plans/260228-1806-onboarding-second-half/phase-05-auth-feature.md`

- [x] Create AuthController with register/login/social stubs
- [x] Create AuthBinding
- [x] Create LoginGateBottomSheet widget
- [x] Create SocialAuthButton widget
- [x] Create AuthTextField widget
- [x] Create SignupEmailScreen
- [x] Create LoginEmailScreen
- [x] Wire Scenario Gift CTA to LoginGateBottomSheet
- [x] Wire OnboardingTopBar "Log in" link
- [x] Add form validation logic
- [x] Handle 409 email exists error on signup
- [x] Handle auth success → save tokens → navigate to /home
- [x] Clear sessionToken after successful auth
- [ ] **Implement Google Sign-In with google_sign_in package**
- [ ] **Implement Apple Sign-In with sign_in_with_apple package**
- [ ] **POST idToken/accessToken to `/auth/google` and `/auth/apple` endpoints**
- [ ] **Configure google-services.json for Android**
- [ ] **Configure iOS URL schemes for OAuth callbacks**

---

## Key Findings

### Strengths
1. ✅ Clean separation of concerns (Controller → Storage → Interceptor)
2. ✅ Comprehensive error handling with user-friendly messages
3. ✅ Token refresh mechanism prevents logout on expiry
4. ✅ Form validation with inline error messages
5. ✅ Forgot password flow fully implemented
6. ✅ Session linking via conversation_id (optional but thoughtful)
7. ✅ Firebase iOS config already in place

### Gaps to Address
1. ⏳ Google Sign-In NOT implemented (TODO stub only)
2. ⏳ Apple Sign-In NOT implemented (TODO stub only)
3. ❌ No google-services.json for Android (may need setup)
4. ❌ Social auth endpoints not tested/integrated
5. ❌ No idToken/accessToken parsing from native SDKs

### Security Notes
1. ✅ Passwords never logged
2. ✅ Tokens stored only in Hive (secure local storage)
3. ✅ Bearer token in Authorization header
4. ✅ Token refresh on 401 (automatic logout on invalid refresh)
5. ✅ Conversation token cleared after auth

---

## Next Steps for Social Auth Implementation

1. **GoogleSignIn Implementation**
   - Call `GoogleSignIn().signIn()` in `signInWithGoogle()`
   - Get `idToken` and `accessToken` from `GoogleSignInAccount`
   - POST both to `/auth/google`
   - Handle response as normal auth response

2. **AppleSignIn Implementation**
   - Call `SignInWithApple.getAppleIDCredential()` in `signInWithApple()`
   - Get `identityToken` and `userIdentifier`
   - POST to `/auth/apple`
   - Handle response as normal auth response

3. **Android Setup**
   - Download google-services.json from Firebase Console
   - Place in `/android/app/google-services.json`
   - Configure Gradle to apply google-services plugin

4. **iOS Setup**
   - Configure custom URL schemes for OAuth redirects
   - Test GoogleSignIn with physical device (simulator has limitations)

---

## File Structure Summary

```
lib/
├── features/auth/
│   ├── bindings/auth_binding.dart
│   ├── controllers/
│   │   ├── auth_controller.dart
│   │   └── forgot_password_controller.dart
│   ├── models/auth_response_model.dart
│   ├── views/
│   │   ├── signup_email_screen.dart
│   │   └── login_email_screen.dart
│   └── widgets/
│       ├── auth_text_field.dart
│       ├── login_gate_bottom_sheet.dart
│       └── social_auth_button.dart
├── core/
│   ├── constants/api_endpoints.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_exceptions.dart
│   │   ├── api_response.dart
│   │   ├── auth_interceptor.dart
│   │   └── http_logger_interceptor.dart
│   ├── services/auth_storage.dart
│   └── base/base_controller.dart
├── shared/models/user_model.dart
├── config/env_config.dart
├── app/
│   ├── global-dependency-injection-bindings.dart
│   └── routes/app-route-constants.dart
└── main.dart

ios/
├── Runner/GoogleService-Info.plist ✅
├── Podfile.lock (with google_sign_in_ios, sign_in_with_apple)
└── Runner/AppDelegate.swift

android/
├── app/src/main/AndroidManifest.xml
└── build.gradle.kts
```

---

## Unresolved Questions

1. What is the exact request/response format for `/auth/google` and `/auth/apple`?
2. Does the backend expect `idToken`, `accessToken`, `identityToken`, `userIdentifier`, or other fields?
3. Is Android google-services.json already configured on the backend, or needs setup?
4. Should social auth return same `AuthResponse` (access_token + refresh_token)?
5. Are there any additional scopes or permissions needed for social auth?

