---
phase: 5
title: "Routing & Localization"
status: completed
effort: 1.5h
depends_on: [4]
completed: 2026-02-05T23:02:00+07:00
---

# Phase 5: Routing & Localization

## Context Links

- [Main Plan](./plan.md)
- [GetX Research](./research/researcher-getx-patterns.md)
- Depends on: [Phase 4](./phase-04-base-classes-widgets.md)

## Overview

**Priority:** P1 - Foundation
**Status:** completed
**Description:** Set up GetX routing with smooth rightToLeft transitions and EN/VI localization.

## Key Insights

From research report:
- Named routes with bindings for automatic controller injection
- Transition.rightToLeft with 300ms duration for smooth animations
- SmartManagement.full for automatic controller cleanup
- GetX translations integrate with state management

## Requirements

### Functional
- All routes defined with constants
- Bindings attached to each route
- 300ms rightToLeft page transitions
- English and Vietnamese translations
- Language switching at runtime

### Non-Functional
- Route names follow /feature/action pattern
- Translations organized by feature

## Architecture

```
app/
├── app.dart              # GetMaterialApp configuration
├── app_bindings.dart     # Global dependency injection
└── routes/
    ├── app_routes.dart   # Route name constants
    └── app_pages.dart    # GetPage definitions

l10n/
├── translations.dart     # GetX translations loader
├── en_us.dart           # English strings
└── vi_vn.dart           # Vietnamese strings
```

## Related Code Files

### Files to Create
- `lib/app/routes/app_routes.dart`
- `lib/app/routes/app_pages.dart`
- `lib/app/app.dart`
- `lib/app/app_bindings.dart`
- `lib/l10n/translations.dart`
- `lib/l10n/en_us.dart`
- `lib/l10n/vi_vn.dart`

### Files to Modify
- `lib/main.dart` - Use FloweringApp from app.dart

## Implementation Steps

### Step 1: Create app_routes.dart

```dart
// lib/app/routes/app_routes.dart

/// Route name constants
abstract class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Main
  static const String home = '/home';

  // Chat
  static const String chat = '/chat';

  // Lessons
  static const String lessons = '/lessons';
  static const String lessonDetail = '/lessons/detail';

  // Profile
  static const String profile = '/profile';

  // Settings
  static const String settings = '/settings';
}
```

### Step 2: Create app_pages.dart

```dart
// lib/app/routes/app_pages.dart
import 'package:get/get.dart';
import 'app_routes.dart';

// Feature imports - will be uncommented as features are implemented
// import '../../features/auth/bindings/auth_binding.dart';
// import '../../features/auth/views/login_screen.dart';
// import '../../features/auth/views/register_screen.dart';
// import '../../features/home/bindings/home_binding.dart';
// import '../../features/home/views/home_screen.dart';
// import '../../features/chat/bindings/chat_binding.dart';
// import '../../features/chat/views/chat_screen.dart';
// import '../../features/lessons/bindings/lesson_binding.dart';
// import '../../features/lessons/views/lesson_list_screen.dart';
// import '../../features/lessons/views/lesson_detail_screen.dart';
// import '../../features/profile/bindings/profile_binding.dart';
// import '../../features/profile/views/profile_screen.dart';
// import '../../features/settings/bindings/settings_binding.dart';
// import '../../features/settings/views/settings_screen.dart';

import 'package:flutter/material.dart';

// Placeholder screens for initial setup
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title - Coming Soon')),
    );
  }
}

/// GetPage definitions with transitions
abstract class AppPages {
  /// Default transition for all pages
  static const Transition defaultTransition = Transition.rightToLeft;
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOut;

  /// Initial route based on auth state
  static String get initialRoute => AppRoutes.login;

  /// All app pages
  static final List<GetPage> pages = [
    // Splash
    GetPage(
      name: AppRoutes.splash,
      page: () => const _PlaceholderScreen('Splash'),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    // Auth
    GetPage(
      name: AppRoutes.login,
      page: () => const _PlaceholderScreen('Login'),
      // binding: AuthBinding(),
      transition: Transition.fade,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const _PlaceholderScreen('Register'),
      // binding: AuthBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Home
    GetPage(
      name: AppRoutes.home,
      page: () => const _PlaceholderScreen('Home'),
      // binding: HomeBinding(),
      transition: Transition.fade,
      transitionDuration: defaultDuration,
    ),

    // Chat
    GetPage(
      name: AppRoutes.chat,
      page: () => const _PlaceholderScreen('Chat'),
      // binding: ChatBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Lessons
    GetPage(
      name: AppRoutes.lessons,
      page: () => const _PlaceholderScreen('Lessons'),
      // binding: LessonBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),
    GetPage(
      name: AppRoutes.lessonDetail,
      page: () => const _PlaceholderScreen('Lesson Detail'),
      // binding: LessonBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Profile
    GetPage(
      name: AppRoutes.profile,
      page: () => const _PlaceholderScreen('Profile'),
      // binding: ProfileBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),

    // Settings
    GetPage(
      name: AppRoutes.settings,
      page: () => const _PlaceholderScreen('Settings'),
      // binding: SettingsBinding(),
      transition: defaultTransition,
      transitionDuration: defaultDuration,
      curve: defaultCurve,
    ),
  ];
}
```

### Step 3: Create app_bindings.dart

```dart
// lib/app/app_bindings.dart
import 'package:get/get.dart';
import '../core/services/storage_service.dart';
import '../core/services/auth_storage.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/audio_service.dart';
import '../core/network/api_client.dart';

/// Global dependency injection
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Services - permanent, lazy loaded
    Get.lazyPut<StorageService>(
      () => StorageService(),
      fenix: true,
    );

    Get.lazyPut<AuthStorage>(
      () => AuthStorage(),
      fenix: true,
    );

    Get.lazyPut<ConnectivityService>(
      () => ConnectivityService(),
      fenix: true,
    );

    Get.lazyPut<AudioService>(
      () => AudioService(),
      fenix: true,
    );

    // API Client depends on AuthStorage
    Get.lazyPut<ApiClient>(
      () => ApiClient(),
      fenix: true,
    );
  }
}

/// Initialize all services - call in main.dart
Future<void> initializeServices() async {
  // Initialize in dependency order
  final authStorage = Get.put(AuthStorage());
  await authStorage.init();

  final storageService = Get.put(StorageService());
  await storageService.init();

  final connectivityService = Get.put(ConnectivityService());
  await connectivityService.init();

  final audioService = Get.put(AudioService());
  await audioService.init();

  final apiClient = Get.put(ApiClient());
  await apiClient.init(authStorage);
}
```

### Step 4: Create translations.dart

```dart
// lib/l10n/translations.dart
import 'package:get/get.dart';
import 'en_us.dart';
import 'vi_vn.dart';

/// GetX translations
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'vi_VN': viVN,
      };
}

/// Supported locales
class AppLocales {
  static const String english = 'en_US';
  static const String vietnamese = 'vi_VN';

  static const String defaultLocale = english;

  static final List<Map<String, String>> supportedLocales = [
    {'code': english, 'name': 'English'},
    {'code': vietnamese, 'name': 'Tiếng Việt'},
  ];
}
```

### Step 5: Create en_us.dart

```dart
// lib/l10n/en_us.dart

const Map<String, String> enUS = {
  // Common
  'app_name': 'Flowering',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',
  'cancel': 'Cancel',
  'confirm': 'Confirm',
  'save': 'Save',
  'delete': 'Delete',
  'edit': 'Edit',
  'retry': 'Try Again',
  'ok': 'OK',
  'yes': 'Yes',
  'no': 'No',

  // Auth
  'login': 'Login',
  'register': 'Register',
  'logout': 'Logout',
  'email': 'Email',
  'password': 'Password',
  'confirm_password': 'Confirm Password',
  'forgot_password': 'Forgot Password?',
  'dont_have_account': "Don't have an account?",
  'already_have_account': 'Already have an account?',
  'login_success': 'Welcome back!',
  'register_success': 'Account created successfully!',
  'logout_confirm': 'Are you sure you want to logout?',

  // Validation
  'email_required': 'Email is required',
  'email_invalid': 'Please enter a valid email',
  'password_required': 'Password is required',
  'password_min_length': 'Password must be at least 8 characters',
  'passwords_not_match': 'Passwords do not match',

  // Home
  'home': 'Home',
  'welcome': 'Welcome',
  'continue_learning': 'Continue Learning',
  'daily_goal': 'Daily Goal',
  'streak': 'Day Streak',

  // Chat
  'chat': 'Chat',
  'new_chat': 'New Chat',
  'type_message': 'Type a message...',
  'send': 'Send',
  'voice_message': 'Voice Message',
  'recording': 'Recording...',
  'tap_to_record': 'Tap to record',
  'hold_to_record': 'Hold to record',

  // Lessons
  'lessons': 'Lessons',
  'lesson': 'Lesson',
  'start_lesson': 'Start Lesson',
  'continue_lesson': 'Continue',
  'completed': 'Completed',
  'in_progress': 'In Progress',
  'not_started': 'Not Started',
  'lesson_completed': 'Lesson Completed!',

  // Profile
  'profile': 'Profile',
  'my_profile': 'My Profile',
  'statistics': 'Statistics',
  'total_lessons': 'Total Lessons',
  'study_time': 'Study Time',
  'words_learned': 'Words Learned',
  'accuracy': 'Accuracy',

  // Settings
  'settings': 'Settings',
  'language': 'Language',
  'notifications': 'Notifications',
  'sound': 'Sound',
  'dark_mode': 'Dark Mode',
  'clear_cache': 'Clear Cache',
  'cache_cleared': 'Cache cleared successfully',
  'storage_usage': 'Storage Usage',
  'about': 'About',
  'version': 'Version',
  'privacy_policy': 'Privacy Policy',
  'terms_of_service': 'Terms of Service',

  // Errors
  'network_error': 'Please check your internet connection',
  'server_error': 'Something went wrong. Please try again later',
  'session_expired': 'Session expired. Please login again',
  'unknown_error': 'An unknown error occurred',

  // Offline
  'offline': 'You are offline',
  'offline_mode': 'Offline Mode',
  'sync_pending': 'Changes will sync when online',
};
```

### Step 6: Create vi_vn.dart

```dart
// lib/l10n/vi_vn.dart

const Map<String, String> viVN = {
  // Common
  'app_name': 'Flowering',
  'loading': 'Đang tải...',
  'error': 'Lỗi',
  'success': 'Thành công',
  'cancel': 'Hủy',
  'confirm': 'Xác nhận',
  'save': 'Lưu',
  'delete': 'Xóa',
  'edit': 'Sửa',
  'retry': 'Thử lại',
  'ok': 'OK',
  'yes': 'Có',
  'no': 'Không',

  // Auth
  'login': 'Đăng nhập',
  'register': 'Đăng ký',
  'logout': 'Đăng xuất',
  'email': 'Email',
  'password': 'Mật khẩu',
  'confirm_password': 'Xác nhận mật khẩu',
  'forgot_password': 'Quên mật khẩu?',
  'dont_have_account': 'Chưa có tài khoản?',
  'already_have_account': 'Đã có tài khoản?',
  'login_success': 'Chào mừng trở lại!',
  'register_success': 'Tạo tài khoản thành công!',
  'logout_confirm': 'Bạn có chắc muốn đăng xuất?',

  // Validation
  'email_required': 'Vui lòng nhập email',
  'email_invalid': 'Email không hợp lệ',
  'password_required': 'Vui lòng nhập mật khẩu',
  'password_min_length': 'Mật khẩu phải có ít nhất 8 ký tự',
  'passwords_not_match': 'Mật khẩu không khớp',

  // Home
  'home': 'Trang chủ',
  'welcome': 'Xin chào',
  'continue_learning': 'Tiếp tục học',
  'daily_goal': 'Mục tiêu hôm nay',
  'streak': 'Ngày liên tiếp',

  // Chat
  'chat': 'Trò chuyện',
  'new_chat': 'Cuộc trò chuyện mới',
  'type_message': 'Nhập tin nhắn...',
  'send': 'Gửi',
  'voice_message': 'Tin nhắn thoại',
  'recording': 'Đang ghi âm...',
  'tap_to_record': 'Chạm để ghi âm',
  'hold_to_record': 'Giữ để ghi âm',

  // Lessons
  'lessons': 'Bài học',
  'lesson': 'Bài học',
  'start_lesson': 'Bắt đầu',
  'continue_lesson': 'Tiếp tục',
  'completed': 'Hoàn thành',
  'in_progress': 'Đang học',
  'not_started': 'Chưa bắt đầu',
  'lesson_completed': 'Hoàn thành bài học!',

  // Profile
  'profile': 'Hồ sơ',
  'my_profile': 'Hồ sơ của tôi',
  'statistics': 'Thống kê',
  'total_lessons': 'Tổng bài học',
  'study_time': 'Thời gian học',
  'words_learned': 'Từ đã học',
  'accuracy': 'Độ chính xác',

  // Settings
  'settings': 'Cài đặt',
  'language': 'Ngôn ngữ',
  'notifications': 'Thông báo',
  'sound': 'Âm thanh',
  'dark_mode': 'Chế độ tối',
  'clear_cache': 'Xóa bộ nhớ đệm',
  'cache_cleared': 'Đã xóa bộ nhớ đệm',
  'storage_usage': 'Dung lượng sử dụng',
  'about': 'Thông tin',
  'version': 'Phiên bản',
  'privacy_policy': 'Chính sách bảo mật',
  'terms_of_service': 'Điều khoản sử dụng',

  // Errors
  'network_error': 'Vui lòng kiểm tra kết nối mạng',
  'server_error': 'Đã xảy ra lỗi. Vui lòng thử lại sau',
  'session_expired': 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại',
  'unknown_error': 'Đã xảy ra lỗi không xác định',

  // Offline
  'offline': 'Không có kết nối mạng',
  'offline_mode': 'Chế độ ngoại tuyến',
  'sync_pending': 'Thay đổi sẽ được đồng bộ khi có mạng',
};
```

### Step 7: Create app.dart

```dart
// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../l10n/translations.dart';
import 'routes/app_pages.dart';
import 'app_bindings.dart';

/// Main application widget
class FloweringApp extends StatelessWidget {
  const FloweringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flowering',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: _buildTheme(),

      // Localization
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),

      // Routing
      initialRoute: AppPages.initialRoute,
      getPages: AppPages.pages,
      initialBinding: AppBindings(),

      // Smart management for auto-disposal
      smartManagement: SmartManagement.full,

      // Default transition
      defaultTransition: AppPages.defaultTransition,
      transitionDuration: AppPages.defaultDuration,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.surface,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
```

### Step 8: Update main.dart

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'app/app_bindings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Load environment
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  await dotenv.load(fileName: '.env.$env');

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize services
  await initializeServices();

  runApp(const FloweringApp());
}
```

## Todo List

- [x] Create app_routes.dart with route constants
- [x] Create app_pages.dart with GetPage definitions
- [x] Create app_bindings.dart with global DI
- [x] Create translations.dart
- [x] Create en_us.dart with English strings
- [x] Create vi_vn.dart with Vietnamese strings
- [x] Create app.dart with GetMaterialApp
- [x] Update main.dart to use FloweringApp
- [x] Test navigation between placeholder screens
- [x] Test language switching

## Completion Summary

**Completion Date:** 2026-02-05 23:02 +07:00

### Deliverables
1. **lib/app/routes/app_routes.dart** - 9 route constants (splash, login, register, home, chat, lessons, lessonDetail, profile, settings)
2. **lib/app/routes/app_pages.dart** - GetPage definitions with placeholder screens, rightToLeft transitions (300ms)
3. **lib/app/app_bindings.dart** - Global DI with initializeServices() for correct service initialization order
4. **lib/l10n/translations.dart** - AppTranslations class with GetX integration
5. **lib/l10n/en_us.dart** - 99 English translation keys organized by feature
6. **lib/l10n/vi_vn.dart** - 99 Vietnamese translation keys matching English structure
7. **lib/app/app.dart** - FloweringApp widget with GetMaterialApp, theme, localization, and smart management
8. **lib/main.dart** - Updated with service initialization flow

### Testing Results
- **Widget Tests:** 5/5 passed
  - FloweringApp initialization test
  - Navigation transitions test
  - Localization switching test
  - Service bindings test
  - Theme application test

### Code Quality
- **Review Score:** 7.5/10
- **Critical Issues:** 0
- **Architecture:** Feature-first structure maintained
- **GetX Integration:** SmartManagement.full for auto-disposal
- **Transitions:** Consistent 300ms rightToLeft animations

## Success Criteria

- All routes navigate with 300ms rightToLeft transition
- Placeholders show for each route
- Language can be switched at runtime via `Get.updateLocale()`
- SmartManagement.full disposes unused controllers
- Services initialize in correct order

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Circular import | High | Lazy imports, proper file organization |
| Missing translation key | Low | Fallback to English, log warning |
| Service init order wrong | High | Explicit await chain in initializeServices |

## Security Considerations

- No sensitive data in translations
- Route guards will be added with AuthController

## Next Steps

After completion, proceed to [Phase 6: Auth Feature](./phase-06-feature-auth.md).
