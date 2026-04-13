# Code Standards & Conventions

## File Naming Conventions

### Dart Files

**All Dart files:** Use snake_case

```
✅ Good:
- app_colors.dart
- auth_controller.dart
- user_model.dart
- api_client.dart

❌ Bad:
- AppColors.dart
- authController.dart
- UserModel.dart
```

### Feature Folders

**All folders:** Use lowercase with underscores

```
✅ Good:
lib/features/auth/
lib/core/constants/
lib/shared/widgets/

❌ Bad:
lib/features/Auth/
lib/Core/Constants/
```

## Code Structure Standards

### Class Naming

```dart
// Classes: PascalCase
class UserModel {}
class AuthController extends GetxController {}
class ApiClient {}

// Private constructors for utility classes
class AppColors {
  AppColors._();  // Prevents instantiation
  static const Color primary = Color(0xFFFF7A27);
}
```

### Variable Naming

```dart
// Variables: camelCase
final String userName = 'John';
final int messageCount = 5;

// Private variables: _camelCase
final String _apiKey = 'secret';

// Constants: lowerCamelCase (Dart convention)
static const int maxRetries = 3;

// Reactive variables: camelCase.obs
final isLoading = false.obs;
final userName = ''.obs;
```

### Function Naming

```dart
// Functions: camelCase
void sendMessage() {}
Future<void> fetchUserData() async {}

// Private functions: _camelCase
void _handleError() {}
```

### File Organization

**Maximum 200 lines per file** - Split when exceeded

```dart
// 1. Imports (grouped and sorted)
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';

// 2. Class definition
class LoginScreen extends StatelessWidget {
  // 3. Constructor
  const LoginScreen({super.key});

  // 4. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }

  // 5. Helper methods
  void _onLoginPressed() {}
}
```

## Architecture Standards

### Feature-First Structure

Each feature follows this exact structure:

```
features/{feature_name}/
├── bindings/
│   └── {feature}_binding.dart
├── controllers/
│   └── {feature}_controller.dart
├── views/
│   └── {feature}_screen.dart
└── widgets/
    └── {feature}_widget.dart
```

### Controller Standards

> **Rule:** All feature controllers MUST extend `BaseController`, never `GetxController` directly.

`BaseController` provides `isLoading`, `errorMessage`, `apiCall()`, `showSuccess()`, `clearError()` — do NOT redeclare these fields.

```dart
class AuthController extends BaseController {
  // 1. Dependencies (injected via Get.find)
  final ApiClient _apiClient = Get.find();
  final AuthStorage _authStorage = Get.find();

  // 2. Feature-specific reactive state (.obs)
  // NOTE: isLoading and errorMessage are inherited from BaseController
  final obscurePassword = true.obs;

  // 3. Non-reactive state (complex objects)
  UserModel? currentUser;

  // 4. Lifecycle methods
  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  @override
  void onClose() {
    // Dispose workers, streams, controllers
    super.onClose();
  }

  // 5. Public methods — use inherited apiCall() or manual try/catch with inherited isLoading
  Future<void> login(String email, String password) async {
    await apiCall(
      () => _apiClient.post(ApiEndpoints.login, data: {...}),
      onSuccess: (result) { /* handle */ },
    );
  }

  // 6. Private helper methods
  void _handleError(dynamic error) {}
}
```

### View (Screen) Standards

> **Rule:** All feature screens with a controller MUST extend `BaseScreen<T>`. Tab child screens and StatefulWidget screens are exempt.

`BaseScreen<T>` provides Scaffold, SafeArea, and optional loading overlay. Override `buildContent()` instead of `build()`.

```dart
class LoginScreen extends BaseScreen<AuthController> {
  const LoginScreen({super.key});

  @override
  bool get showLoadingOverlay => false; // screen handles inline loading
  @override
  Color? get backgroundColor => AppColors.background;

  @override
  Widget buildContent(BuildContext context) {
    // Use `controller` (inherited from GetView) instead of Get.find()
    return Column(
      children: [
        AppTextField(
          label: 'email'.tr,
          onChanged: (value) => controller.email.value = value,
        ),
        Obx(() => AppButton(
          text: 'login'.tr,
          isLoading: controller.isLoading.value,
          onPressed: controller.login,
        )),
      ],
    );
  }
}
```

**Exemptions:**
- Tab child screens (in IndexedStack) — use plain `StatelessWidget`, no Scaffold
- StatefulWidget screens needing `State` lifecycle — add comment explaining why

**BaseScreen vs Shared Widgets:**
- `BaseScreen` provides universal behaviors (Scaffold, SafeArea, LoadingOverlay) — every screen gets these.
- Feature-specific behaviors (pull-to-refresh, pagination, etc.) belong as **opt-in shared widgets** (`PullToRefreshList`, etc.), not in BaseScreen. Only screens that need them compose them in.
- Rule: don't add to BaseScreen unless it applies to ALL screens.

### Widget Standards

```dart
// Shared widgets should be reusable and configurable
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Text(text, style: AppTextStyles.button),
    );
  }
}
```

## State Management Standards

### When to Use .obs vs GetBuilder

**Use .obs for:**
- Simple values (bool, String, int)
- Single widget updates
- Frequently changing values

```dart
final isLoading = false.obs;
final userName = ''.obs;

// In view
Obx(() => Text(controller.userName.value))
```

**Use GetBuilder for:**
- Complex objects
- Lists
- Multiple widget updates
- Performance-critical sections

```dart
List<Message> messages = [];

// In view
GetBuilder<ChatController>(
  builder: (controller) => ListView.builder(
    itemCount: controller.messages.length,
    itemBuilder: (context, index) => MessageWidget(controller.messages[index]),
  ),
)
```

### Worker Usage

```dart
@override
void onInit() {
  super.onInit();

  // React to every change
  ever(userName, (value) => print('Username: $value'));

  // React once
  once(isAuthenticated, (_) => Get.toNamed('/home'));

  // Debounce (wait for user to stop typing)
  debounce(searchQuery, (_) => search(), time: Duration(seconds: 1));

  // Interval (batch updates)
  interval(messageList, (_) => syncMessages(), time: Duration(seconds: 5));
}
```

## Error Handling Standards

### Try-Catch Pattern

```dart
Future<void> fetchData() async {
  try {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await _apiClient.get('/endpoint');
    // Process response

  } on ApiException catch (e) {
    // Handle API errors
    errorMessage.value = e.message;
    Get.snackbar('error'.tr, e.message);

  } on NetworkException catch (e) {
    // Handle network errors
    errorMessage.value = 'no_internet'.tr;

  } catch (e) {
    // Handle unexpected errors
    errorMessage.value = 'unknown_error'.tr;
    if (kDebugMode) {
      print('Unexpected error: $e');
    }
  } finally {
    isLoading.value = false;
  }
}
```

### Custom Exception Types

```dart
// lib/core/network/api_exceptions.dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException('connection_timeout'.tr, null);
      case DioExceptionType.receiveTimeout:
        return ApiException('receive_timeout'.tr, null);
      case DioExceptionType.badResponse:
        return ApiException(
          error.response?.data['message'] ?? 'server_error'.tr,
          error.response?.statusCode,
        );
      default:
        return ApiException('network_error'.tr, null);
    }
  }
}
```

## Network Layer Standards

### API Client Usage

```dart
// Singleton instance via GetX
final apiClient = Get.find<ApiClient>();

// GET request
final response = await apiClient.get<UserModel>(
  ApiEndpoints.profile,
  fromJson: (data) => UserModel.fromJson(data),
);

// POST request
final response = await apiClient.post<AuthResponse>(
  ApiEndpoints.login,
  data: {'email': email, 'password': password},
  fromJson: (data) => AuthResponse.fromJson(data),
);

// File upload
await apiClient.uploadFile(
  ApiEndpoints.uploadAvatar,
  filePath: imagePath,
  fieldName: 'avatar',
  onSendProgress: (sent, total) {
    print('Progress: ${(sent / total * 100).toFixed(0)}%');
  },
);
```

### Error Handling Pattern

```dart
Future<void> fetchData() async {
  try {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await apiClient.get<DataModel>(
      ApiEndpoints.data,
      fromJson: (json) => DataModel.fromJson(json),
    );

    if (response.isSuccess) {
      data.value = response.data;
    } else {
      errorMessage.value = response.message;
    }

  } on NetworkException catch (e) {
    errorMessage.value = 'No internet connection';
    Get.snackbar('Network Error', e.userMessage);

  } on TimeoutException catch (e) {
    errorMessage.value = 'Request timeout';
    Get.snackbar('Timeout', e.userMessage);

  } on UnauthorizedException catch (e) {
    // Auth interceptor handles redirect to login
    errorMessage.value = 'Session expired';

  } on ValidationException catch (e) {
    errorMessage.value = e.userMessage;
    if (e.errors != null) {
      // Show field-specific errors
      e.errors!.forEach((field, messages) {
        print('$field: ${messages.join(", ")}');
      });
    }

  } on ServerException catch (e) {
    errorMessage.value = 'Server error';
    Get.snackbar('Server Error', e.userMessage);

  } on ApiException catch (e) {
    errorMessage.value = e.userMessage;
    Get.snackbar('Error', e.userMessage);

  } catch (e) {
    errorMessage.value = 'Unexpected error';
    if (kDebugMode) {
      print('Unexpected error: $e');
    }

  } finally {
    isLoading.value = false;
  }
}
```

### API Response Wrapping

```dart
// Server returns: { "code": 1, "message": "Success", "data": {...} }

class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  bool get isSuccess => code == 1;
  bool get isError => code != 1;
}

// Usage in controller
final response = await apiClient.get<UserModel>(
  ApiEndpoints.profile,
  fromJson: (data) => UserModel.fromJson(data),
);

if (response.isSuccess && response.data != null) {
  currentUser.value = response.data!;
} else {
  showError(response.message);
}
```

### Custom Exception Types

**Available Exception Types:**
- `NetworkException` - No internet connection
- `TimeoutException` - Request timeout
- `UnauthorizedException` - 401, token expired
- `ForbiddenException` - 403, no permission
- `NotFoundException` - 404, resource not found
- `ServerException` - 5xx server errors
- `ValidationException` - 422, field validation errors
- `ApiErrorException` - Generic API errors

**Exception Properties:**
```dart
abstract class ApiException {
  final String message;        // Technical message
  final String userMessage;    // User-friendly message
  final int? statusCode;       // HTTP status code
  final dynamic originalError; // Original Dio exception
}
```

**Validation Exception Usage:**
```dart
try {
  await apiClient.post(ApiEndpoints.register, data: formData);
} on ValidationException catch (e) {
  if (e.errors != null) {
    e.errors!.forEach((field, messages) {
      // Show error under specific form field
      formErrors[field] = messages.first;
    });
  }
}
```

## Storage Standards

### Hive Box Management

```dart
// lib/core/services/storage_service.dart
class StorageService {
  static const String _userBox = 'user_data';
  static const String _lessonsBox = 'lessons_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_userBox);
    await Hive.openBox(_lessonsBox);
  }

  Box get userBox => Hive.box(_userBox);
  Box get lessonsBox => Hive.box(_lessonsBox);

  Future<void> saveUser(UserModel user) async {
    await userBox.put('current_user', user.toJson());
  }

  UserModel? getUser() {
    final data = userBox.get('current_user');
    return data != null ? UserModel.fromJson(data) : null;
  }
}
```

### Token Storage with AuthStorage

```dart
// lib/core/services/auth_storage.dart
class AuthStorage extends GetxService {
  late Box<String> _box;

  Future<AuthStorage> init() async {
    _box = await Hive.openBox<String>('auth');
    return this;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put('access_token', accessToken);
    await _box.put('refresh_token', refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _box.get('access_token');
  }

  bool get isLoggedIn => getAccessToken() != null;

  Future<void> clearTokens() async {
    await _box.delete('access_token');
    await _box.delete('refresh_token');
  }
}
```

## Model Standards

### JSON Serialization

**IMPORTANT:** All API JSON keys use `snake_case`. Dart property names use `camelCase`. Map keys in `fromJson`/`toJson` MUST match backend API snake_case keys.

```dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String profilePicture;  // Dart property: camelCase
  final bool emailVerified;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePicture,
    required this.emailVerified,
    this.updatedAt,
  });

  // ✅ Correct: JSON keys are snake_case (match backend API)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profilePicture: json['profile_picture'] as String? ?? '',  // snake_case key
      emailVerified: json['email_verified'] as bool? ?? false,    // snake_case key
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)          // snake_case key
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,    // snake_case key
      'email_verified': emailVerified,       // snake_case key
      'updated_at': updatedAt?.toIso8601String(),  // snake_case key
    };
  }
}
```

**Pattern Rules:**
1. Dart property names → always `camelCase` (Dart convention)
2. JSON keys in `fromJson`/`toJson` → always `snake_case` (API contract)
3. Type safety: Cast values with `as Type?` and provide defaults in `fromJson`
4. DateTime handling: Always use `DateTime.parse()` for ISO 8601 strings

### Backward Compatibility for Cached Data

When migrating old camelCase data in Hive cache to snake_case API format, add fallback reads:

```dart
factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    profilePicture: json['profile_picture'] as String?
        ?? json['avatarUrl'] as String?  // Fallback to old camelCase key
        ?? '',
    emailVerified: json['email_verified'] as bool?
        ?? json['emailVerified'] as bool?  // Fallback to old camelCase key
        ?? false,
  );
}
```

This allows safe migration without requiring cache wipe on app update.

## Localization Standards

### Translation Keys

```dart
// lib/l10n/en_us.dart
class EnUs {
  static const Map<String, String> translations = {
    'app_name': 'Flowering',
    'login': 'Login',
    'email': 'Email',
    'password': 'Password',
    'welcome_user': 'Welcome, @name!',
    'error_invalid_email': 'Please enter a valid email',
  };
}

// Usage
Text('app_name'.tr)
Text('welcome_user'.trParams({'name': userName}))
```

## Testing Standards

### Unit Tests

```dart
void main() {
  group('AuthController', () {
    late AuthController controller;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      Get.put<ApiClient>(mockApiClient);
      controller = AuthController();
    });

    tearDown(() {
      Get.reset();
    });

    test('login success sets user', () async {
      when(mockApiClient.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => Response(data: {'token': 'abc'}));

      await controller.login('test@email.com', 'password');

      expect(controller.isLoading.value, false);
      expect(controller.errorMessage.value, '');
    });
  });
}
```

## Performance Standards

### Memory Management

```dart
class ChatController extends GetxController {
  late Worker _messageWorker;
  StreamSubscription? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _messageWorker = ever(messages, (_) => _syncMessages());
    _connectivitySubscription = connectivityService.stream.listen(_onConnectivityChanged);
  }

  @override
  void onClose() {
    // CRITICAL: Dispose all resources
    _messageWorker.dispose();
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
```

### Build Optimization

```dart
// Use const constructors
const SizedBox(height: 16)
const Icon(Icons.home)

// Extract widgets to methods or separate widgets if > 50 lines
Widget _buildHeader() {
  return Container(...);
}

// Use ListView.builder for lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

## Code Quality Checklist

Before committing code, verify:

- ✅ No compile errors
- ✅ No linting warnings (critical ones)
- ✅ Files under 200 lines
- ✅ All TODOs resolved or documented
- ✅ Error handling present
- ✅ Resources disposed in onClose()
- ✅ Translations used (no hardcoded strings)
- ✅ Constants used (no magic numbers)
- ✅ Meaningful variable names
- ✅ Comments for complex logic
- ✅ app size, color, constants always use in `lib/core/constants/` and `lib/core/utils/`

## Git Commit Standards

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(auth): add login functionality

Implement login screen with email/password validation.
Add JWT token storage using AuthStorage (Hive).

Closes #123

---

fix(chat): resolve message duplication issue

Messages were duplicating due to improper stream handling.
Fixed by disposing old subscriptions before creating new ones.

---

refactor(home): extract widgets to improve readability

Split HomeScreen into smaller widgets for better maintainability.
Each widget is now under 100 lines.
```

## Constants Usage

### Color Constants

```dart
// ✅ Good
Container(color: AppColors.primary)

// ❌ Bad
Container(color: Color(0xFFFF9500))
```

### Text Style Constants

```dart
// ✅ Good
Text('Hello', style: AppTextStyles.h1)

// ❌ Bad
Text('Hello', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))
```

### API Endpoint Constants

```dart
// ✅ Good
_apiClient.get(ApiEndpoints.login)

// ❌ Bad
_apiClient.get('/auth/login')
```

## Documentation Standards

### Class Documentation

```dart
/// Controller managing user authentication state and operations.
///
/// Handles login, registration, token refresh, and logout.
/// Uses [AuthStorage] for secure token persistence.
class AuthController extends GetxController {
  // Implementation
}
```

### Method Documentation

```dart
/// Authenticates user with email and password.
///
/// Throws [ApiException] if authentication fails.
/// Returns [UserModel] on success.
Future<UserModel> login(String email, String password) async {
  // Implementation
}
```

## Security Standards

### Input Validation

```dart
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'email_required'.tr;
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'invalid_email'.tr;
  }
  return null;
}
```

### Sensitive Data Handling

```dart
// ✅ Good - Use AuthStorage for tokens
await authStorage.saveTokens(accessToken: token, refreshToken: refresh);

// ✅ Good - No sensitive data in logs
if (kDebugMode) {
  print('Login successful for user: ${user.id}');
}

// ❌ Bad - Don't log sensitive data
print('User credentials: $email, $password');

// ✅ Good - Separate user cache from token storage
// Tokens: AuthStorage (Hive 'auth' box)
// Cache: StorageService (Hive 'lessons_cache', 'chat_cache' boxes)
```

## GetX Service Pattern

### Service Definition

```dart
/// Storage service with LRU/FIFO cache eviction.
class StorageService extends GetxService {
  late Box<String> _box;

  /// Initialize service - called once at app startup
  Future<StorageService> init() async {
    _box = await Hive.openBox<String>('storage');
    return this;
  }

  @override
  void onClose() {
    _box.close();
    super.onClose();
  }
}
```

### Service Registration

```dart
// Global bindings (app_bindings.dart)
class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiClient>(() => ApiClient());
    Get.lazyPut<StorageService>(() => StorageService());
    Get.lazyPut<AuthStorage>(() => AuthStorage());
  }
}
```

### Service Usage

```dart
// In controllers or other services
final storage = Get.find<StorageService>();
await storage.init();

// Access service methods
final data = storage.getLesson('lesson_1');
```

### Service Best Practices

- Extend `GetxService` for persistent services
- Implement `init()` for async initialization
- Override `onClose()` for resource cleanup
- Use `Get.lazyPut()` for lazy initialization
- Services persist until manually removed
- Proper disposal prevents memory leaks
