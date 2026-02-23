---
phase: 1
title: "Project Setup & Dependencies"
status: completed
effort: 1h
---

# Phase 1: Project Setup & Dependencies

## Context Links

- [Main Plan](./plan.md)
- [Brainstorm Report](../reports/brainstorm-260205-1600-flutter-ai-language-app-architecture.md)

## Overview

**Priority:** P1 - Foundation
**Status:** completed
**Description:** Create folder structure, update pubspec.yaml, configure environment files.

## Key Insights

- Feature-first architecture isolates concerns per feature
- Environment separation via flutter_dotenv prevents accidental prod API calls
- Hive requires build_runner for type adapters

## Requirements

### Functional
- All folders under lib/ created per architecture diagram
- Dependencies installed and resolvable
- Environment configs for dev/prod

### Non-Functional
- Project compiles with `flutter build`
- No dependency conflicts

## Architecture

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── app_bindings.dart
│   └── routes/
│       ├── app_routes.dart
│       └── app_pages.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── api_endpoints.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_response.dart
│   │   ├── api_exceptions.dart
│   │   └── auth_interceptor.dart
│   ├── services/
│   │   ├── storage_service.dart
│   │   ├── auth_storage.dart
│   │   ├── connectivity_service.dart
│   │   └── audio_service.dart
│   ├── utils/
│   │   ├── extensions.dart
│   │   └── validators.dart
│   └── base/
│       ├── base_controller.dart
│       └── base_screen.dart
├── shared/
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_text.dart
│   │   ├── app_icon.dart
│   │   ├── loading_widget.dart
│   │   ├── loading_overlay.dart
│   │   └── error_widget.dart
│   └── models/
│       ├── user_model.dart
│       └── api_error_model.dart
├── features/
│   ├── auth/
│   │   ├── bindings/
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   ├── home/
│   │   ├── bindings/
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   ├── chat/
│   │   ├── bindings/
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   ├── lessons/
│   │   ├── bindings/
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   ├── profile/
│   │   ├── bindings/
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   └── settings/
│       ├── bindings/
│       ├── controllers/
│       └── views/
├── l10n/
│   ├── translations.dart
│   ├── en_us.dart
│   └── vi_vn.dart
└── config/
    └── env_config.dart
```

## Related Code Files

### Files to Create
- `lib/app/` - All subfolders and placeholder .dart files
- `lib/core/` - All subfolders
- `lib/shared/` - All subfolders
- `lib/features/` - All feature subfolders with bindings/controllers/views/widgets
- `lib/l10n/` - Localization folder
- `lib/config/env_config.dart`
- `.env.dev` and `.env.prod` at project root
- `assets/logos/` folder for logo assets

### Files to Modify
- `pubspec.yaml` - Add all dependencies and assets

## Implementation Steps

### Step 1: Create folder structure

```bash
# Core folders
mkdir -p lib/app/routes
mkdir -p lib/core/{constants,network,services,utils,base}
mkdir -p lib/shared/{widgets,models}
mkdir -p lib/l10n
mkdir -p lib/config

# Feature folders
for feature in auth home chat lessons profile settings; do
  mkdir -p lib/features/$feature/{bindings,controllers,views,widgets}
done

# Assets
mkdir -p assets/logos
mkdir -p assets/icons
mkdir -p assets/images
```

### Step 2: Update pubspec.yaml

```yaml
name: flowering
description: "AI Language Learning App"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.10.3

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

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

  # Connectivity
  connectivity_plus: ^6.0.3

  # Utils
  uuid: ^4.3.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.8

flutter:
  uses-material-design: true
  assets:
    - assets/logos/
    - assets/icons/
    - assets/images/
    - .env.dev
    - .env.prod
```

### Step 3: Create environment files

**.env.dev**
```
API_BASE_URL=https://dev-api.flowering.app
ENV=development
```

**.env.prod**
```
API_BASE_URL=https://api.flowering.app
ENV=production
```

### Step 4: Create env_config.dart

```dart
// lib/config/env_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get env => dotenv.env['ENV'] ?? 'development';
  static bool get isDev => env == 'development';
  static bool get isProd => env == 'production';
}
```

### Step 5: Create app_colors.dart

```dart
// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8F66);
  static const Color primaryDark = Color(0xFFE55A2B);

  // Secondary
  static const Color secondary = Color(0xFF2EC4B6);
  static const Color secondaryLight = Color(0xFF5DD9CD);
  static const Color secondaryDark = Color(0xFF20A99D);

  // Neutrals
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Chat
  static const Color userBubble = Color(0xFFFF6B35);
  static const Color aiBubble = Color(0xFFF3F4F6);
}
```

### Step 6: Create app_text_styles.dart

```dart
// lib/core/constants/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );
}
```

### Step 7: Create api_endpoints.dart

```dart
// lib/core/constants/api_endpoints.dart
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';

  // Lessons
  static const String lessons = '/lessons';
  static String lessonDetail(String id) => '/lessons/$id';

  // Chat
  static const String chatMessages = '/chat/messages';
  static const String chatSend = '/chat/send';
  static const String chatVoice = '/chat/voice';

  // Progress
  static const String progress = '/progress';
  static const String stats = '/progress/stats';
}
```

### Step 8: Create placeholder main.dart

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  await dotenv.load(fileName: '.env.$env');

  // Initialize Hive
  await Hive.initFlutter();

  runApp(const FloweringApp());
}

class FloweringApp extends StatelessWidget {
  const FloweringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flowering',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('Flowering App - Setup Complete'),
        ),
      ),
    );
  }
}
```

### Step 9: Run flutter pub get and verify

```bash
flutter pub get
flutter analyze
flutter build apk --debug --dart-define=ENV=dev
```

## Todo List

- [x] Create all folder structure under lib/
- [x] Update pubspec.yaml with dependencies
- [x] Create .env.dev and .env.prod files
- [x] Create env_config.dart
- [x] Create app_colors.dart
- [x] Create app_text_styles.dart
- [x] Create api_endpoints.dart
- [x] Update main.dart with initialization
- [x] Create assets folders
- [x] Run flutter pub get
- [x] Verify project compiles

## Success Criteria

- `flutter pub get` completes without errors
- `flutter analyze` shows no errors
- `flutter build apk --debug` succeeds
- All folders exist per architecture diagram
- Environment variables load correctly

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Dependency version conflicts | High | Pin specific versions, test together |
| Missing folders cause import errors | Medium | Create all folders upfront |
| dotenv not loading in release | High | Ensure assets are declared in pubspec |

## Security Considerations

- `.env.prod` should NOT contain secrets - only non-sensitive config
- Actual API keys should come from secure storage or be baked in CI/CD
- Add `.env.prod` to `.gitignore` if it contains any sensitive data

## Next Steps

After completion, proceed to [Phase 2: Core Network Layer](./phase-02-network-layer.md).
