# Brainstorm Report: AI Language Learning App Architecture

**Date:** 2026-02-05
**Status:** Agreed

---

## Problem Statement

Create a Flutter codebase for an AI-powered language learning app that:
- Enables personalized learning content
- Supports voice and text chat with AI (via backend API)
- Targets intermediate learners
- Supports Vietnamese and English
- Uses GetX state management
- Requires smooth navigation animations
- Needs basic offline support

---

## Agreed Architecture: Feature-First with GetX

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp with GetMaterialApp
│   ├── app_bindings.dart           # Global dependency injection
│   └── routes/
│       ├── app_routes.dart         # Route name constants
│       └── app_pages.dart          # GetPage definitions with transitions
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Color palette (light only)
│   │   ├── app_text_styles.dart    # Typography
│   │   └── api_endpoints.dart      # API URL constants
│   ├── network/
│   │   ├── api_client.dart         # Single Dio client with interceptors
│   │   ├── api_response.dart       # Generic response wrapper {code, message, data}
│   │   ├── api_exceptions.dart     # Custom exception types
│   │   └── auth_interceptor.dart   # Bearer token + refresh token logic
│   ├── services/
│   │   ├── storage_service.dart    # Hive local storage with size limits
│   │   ├── auth_storage.dart       # Token storage (access + refresh)
│   │   ├── audio_service.dart      # Recording + playback
│   │   └── connectivity_service.dart # Online/offline detection
│   ├── utils/
│   │   ├── extensions.dart         # Dart extensions
│   │   └── validators.dart         # Form validation
│   └── base/
│       ├── base_controller.dart    # Common controller logic
│       └── base_screen.dart        # Common screen wrapper
├── shared/
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_text.dart
│   │   ├── app_icon.dart
│   │   ├── loading_widget.dart       # Animated logo with pulsating glow
│   │   ├── loading_overlay.dart
│   │   └── error_widget.dart
│   └── models/
│       ├── user_model.dart
│       └── api_error_model.dart
├── features/
│   ├── auth/
│   │   ├── bindings/auth_binding.dart
│   │   ├── controllers/auth_controller.dart
│   │   ├── views/login_screen.dart
│   │   ├── views/register_screen.dart
│   │   └── widgets/auth_form.dart
│   ├── home/
│   │   ├── bindings/home_binding.dart
│   │   ├── controllers/home_controller.dart
│   │   ├── views/home_screen.dart
│   │   └── widgets/progress_card.dart
│   ├── chat/
│   │   ├── bindings/chat_binding.dart
│   │   ├── controllers/chat_controller.dart
│   │   ├── controllers/voice_chat_controller.dart
│   │   ├── views/chat_screen.dart
│   │   └── widgets/
│   │       ├── message_bubble.dart
│   │       ├── voice_recorder.dart
│   │       └── chat_input.dart
│   ├── lessons/
│   │   ├── bindings/lesson_binding.dart
│   │   ├── controllers/lesson_controller.dart
│   │   ├── views/lesson_list_screen.dart
│   │   ├── views/lesson_detail_screen.dart
│   │   └── widgets/lesson_card.dart
│   ├── profile/
│   │   ├── bindings/profile_binding.dart
│   │   ├── controllers/profile_controller.dart
│   │   ├── views/profile_screen.dart
│   │   └── widgets/stats_widget.dart
│   └── settings/
│       ├── bindings/settings_binding.dart
│       ├── controllers/settings_controller.dart
│       └── views/settings_screen.dart
├── l10n/
│   ├── translations.dart           # GetX translations loader
│   ├── en_us.dart                  # English strings
│   └── vi_vn.dart                  # Vietnamese strings
└── config/
    └── env_config.dart             # Dev/prod environment switch
```

---

## Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  get: ^4.6.6

  # Network
  dio: ^5.4.0

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Audio
  record: ^5.0.4
  audioplayers: ^5.2.1

  # Localization
  intl: ^0.19.0

  # Environment
  flutter_dotenv: ^5.1.0

  # UI
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
```

---

## Design Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| State Management | GetX | Explicit requirement |
| Navigation | GetX routes with transitions | Smooth animations, consistency |
| API Layer | Single Dio client | Centralized error handling, token refresh |
| Offline Storage | Hive | Fast, simple, no SQL overhead |
| Audio | record + audioplayers | Separate recording/playback concerns |
| Localization | GetX translations | Integrates with state management |
| File Naming | snake_case | Flutter standard |
| Environment | flutter_dotenv | Dev/prod config separation |

---

## Core Components

### 1. Base Screen
Common wrapper handling:
- Loading states
- Error display
- SafeArea
- AppBar consistency
- Never throws exceptions to user

### 2. API Client
Single Dio instance with:
- Auth token interceptor
- Error mapping to user-friendly messages
- Retry logic for network failures
- Offline queue for pending requests

### 3. Base API Response

All API responses follow this structure:

```dart
// api_response.dart
class ApiResponse<T> {
  final int code;        // 1 = success, others = error codes
  final String message;  // User-friendly message
  final T? data;         // Response payload

  bool get isSuccess => code == 1;
}
```

**Response codes:**
| Code | Meaning |
|------|---------|
| 1 | Success |
| 0 | General error |
| -1 | Validation error |
| 401 | Unauthorized (trigger refresh) |
| 403 | Forbidden |
| 500 | Server error |

### 4. Authentication Flow

**Token Storage (Hive):**
```dart
// auth_storage.dart
class AuthStorage {
  static const _boxName = 'auth';

  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> get accessToken;
  Future<String?> get refreshToken;
  Future<void> clearTokens();
}
```

**Bearer Token Interceptor:**
```dart
// auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(options, handler) {
    final token = AuthStorage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(error, handler) async {
    if (error.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry original request with new token
        return handler.resolve(await _retry(error.requestOptions));
      }
      // Refresh failed, logout user
      Get.find<AuthController>().logout();
    }
    handler.next(error);
  }

  Future<bool> _refreshToken() async {
    try {
      final response = await Dio().post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': await AuthStorage.refreshToken},
      );
      if (response.data['code'] == 1) {
        await AuthStorage.saveTokens(
          response.data['data']['access_token'],
          response.data['data']['refresh_token'],
        );
        return true;
      }
    } catch (_) {}
    return false;
  }
}
```

**Token Lifecycle:**
1. Login → Save access + refresh tokens
2. API call → Attach Bearer token header
3. 401 response → Auto-refresh token
4. Refresh success → Retry original request
5. Refresh fail → Logout, redirect to login

### 3. Shared Widgets
Reusable components with consistent styling:
- AppButton (primary, secondary, text variants)
- AppTextField (with validation)
- AppText (typography presets)
- AppIcon (consistent sizing)

---

## Environment Setup

```
.env.dev
.env.prod
```

Load via `flutter_dotenv` in main.dart before runApp.

---

## Navigation Animation

```dart
GetPage(
  name: '/chat',
  page: () => ChatScreen(),
  binding: ChatBinding(),
  transition: Transition.rightToLeft,
  transitionDuration: Duration(milliseconds: 300),
)
```

---

## Offline Strategy

1. Cache lesson content in Hive on first load
2. Queue chat messages when offline
3. Sync pending messages when connectivity restored
4. Show offline indicator in UI
5. Disable voice features when offline (requires API)

### Storage Limits

| Cache Type | Max Size | Eviction Policy | TTL |
|------------|----------|-----------------|-----|
| Lessons | 100 MB | LRU | 30 days |
| Chat messages | 10 MB | FIFO | 7 days |
| User preferences | 1 MB | None | Never |
| Pending sync queue | 5 MB | FIFO | Until synced |

**Implementation in `storage_service.dart`:**
- Check available storage before caching
- Track cache size per category
- Auto-cleanup on app startup if limits exceeded
- Provide manual "Clear Cache" in settings
- Show storage usage in settings screen

---

## Image Caching Strategy

Using `cached_network_image` with custom configuration:

```dart
// In app_bindings.dart
DefaultCacheManager().emptyCache(); // Clear on version update

// Cache config
CachedNetworkImage(
  imageUrl: url,
  memoryCache: 100, // Keep 100 images in memory
  placeholder: (context, url) => ShimmerPlaceholder(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fadeInDuration: Duration(milliseconds: 200),
)
```

| Image Type | Memory Cache | Disk Cache | Max Size |
|------------|--------------|------------|----------|
| Avatars | 50 items | 7 days | 50 MB |
| Lesson images | 30 items | 30 days | 100 MB |
| Chat media | 20 items | 3 days | 50 MB |

**Optimizations:**
- Preload next lesson images during current lesson
- Use thumbnail URLs for lists, full res on detail
- Compress before upload (max 1MB)
- WebP format preference where supported

---

## API Loading State

Centralized loading handling via `BaseController`:

```dart
// base_controller.dart
abstract class BaseController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<T?> apiCall<T>(Future<T> Function() call) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      return await call();
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
```

**Custom Loading Widget:**
```dart
// loading_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;
  final double? size;
  final Color? glowColor;

  const LoadingWidget({super.key, this.message, this.size, this.glowColor});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? Colors.orange;
    final loadingSize = widget.size ?? 80.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Container(
              width: loadingSize + 20,
              height: loadingSize + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Pulsating glow effect
                  BoxShadow(
                    color: glowColor.withValues(
                      alpha: 0.3 + 0.2 * math.sin(_controller.value * 2 * math.pi)),
                    blurRadius: 30 + 10 * math.sin(_controller.value * 2 * math.pi),
                    spreadRadius: 5 + 5 * math.sin(_controller.value * 2 * math.pi),
                  ),
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.15),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: child,
                ),
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logos/logo.png',
                width: loadingSize,
                height: loadingSize,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            Text(
              widget.message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

**Loading Overlay using Custom Widget:**
```dart
// loading_overlay.dart
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final RxBool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) => Obx(() {
    return Stack(children: [
      child,
      if (isLoading.value)
        Container(
          color: Colors.black54,
          child: LoadingWidget(message: message),
        ),
    ]);
  });
}
```

**Features:**
- Blocks UI during API calls
- Shows spinner with semi-transparent overlay
- Auto-displays error snackbar on failure
- Prevents double-tap/submit issues
- Skeleton loaders for list screens

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Audio permission denied | Graceful fallback to text-only mode |
| Large controller files | Split by responsibility (ChatController, VoiceChatController) |
| API changes | Versioned endpoints, response validation |
| Memory leaks | Dispose controllers properly via GetX lifecycle |

---

## Success Criteria

- [ ] Clean project structure matching agreed architecture
- [ ] All shared widgets implemented with consistent styling
- [ ] Base screen handling loading/error states
- [ ] API client with proper error handling
- [ ] GetX navigation with smooth animations
- [ ] Localization for EN/VI working
- [ ] Dev/prod environment separation
- [ ] Basic offline caching functional
- [ ] Storage limits enforced with LRU eviction
- [ ] Image caching with preloading strategy
- [ ] Centralized API loading state via BaseController

---

## Next Steps

1. Initialize project structure with folders
2. Add dependencies to pubspec.yaml
3. Implement core layer (network, services, base classes)
4. Create shared widgets
5. Set up routing and localization
