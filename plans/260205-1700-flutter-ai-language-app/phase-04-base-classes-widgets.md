---
phase: 4
title: "Base Classes & Shared Widgets"
status: completed
effort: 2h
depends_on: [2, 3]
---

# Phase 4: Base Classes & Shared Widgets

## Context Links

- [Main Plan](./plan.md)
- [Brainstorm Report](../reports/brainstorm-260205-1600-flutter-ai-language-app-architecture.md)
- Depends on: [Phase 2](./phase-02-network-layer.md), [Phase 3](./phase-03-core-services.md)

## Overview

**Priority:** P1 - Foundation
**Status:** completed
**Description:** Create base controller with API call wrapper, base screen with loading/error handling, and shared widgets with consistent styling.

## Key Insights

From brainstorm:
- BaseController provides isLoading, errorMessage, and apiCall wrapper
- BaseScreen wraps screens with SafeArea, loading overlay, error handling
- LoadingWidget: animated logo with pulsating glow effect
- Shared widgets ensure consistent styling across app

## Requirements

### Functional
- BaseController with apiCall wrapper that handles loading/error
- BaseScreen wrapping content with loading overlay
- Reusable widgets: AppButton, AppTextField, AppText, AppIcon
- LoadingWidget with animated pulsating glow
- ErrorWidget for displaying errors

### Non-Functional
- Widgets follow app color palette
- Consistent padding, sizing, typography
- Loading overlay blocks interaction

## Architecture

```
core/base/
├── base_controller.dart   # Common controller logic
└── base_screen.dart       # Common screen wrapper

shared/
├── widgets/
│   ├── app_button.dart
│   ├── app_text_field.dart
│   ├── app_text.dart
│   ├── app_icon.dart
│   ├── loading_widget.dart
│   ├── loading_overlay.dart
│   └── error_widget.dart
└── models/
    ├── user_model.dart
    └── api_error_model.dart
```

## Related Code Files

### Files to Create
- `lib/core/base/base_controller.dart`
- `lib/core/base/base_screen.dart`
- `lib/shared/widgets/app_button.dart`
- `lib/shared/widgets/app_text_field.dart`
- `lib/shared/widgets/app_text.dart`
- `lib/shared/widgets/app_icon.dart`
- `lib/shared/widgets/loading_widget.dart`
- `lib/shared/widgets/loading_overlay.dart`
- `lib/shared/widgets/error_widget.dart`
- `lib/shared/models/user_model.dart`
- `lib/shared/models/api_error_model.dart`
- `lib/core/utils/extensions.dart`
- `lib/core/utils/validators.dart`

## Implementation Steps

### Step 1: Create base_controller.dart

```dart
// lib/core/base/base_controller.dart
import 'package:get/get.dart';
import '../network/api_exceptions.dart';

/// Base controller with common loading/error handling
abstract class BaseController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// Wrap API calls with loading state and error handling
  Future<T?> apiCall<T>(
    Future<T> Function() call, {
    bool showLoading = true,
    void Function(T result)? onSuccess,
    void Function(ApiException error)? onError,
  }) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final result = await call();

      if (onSuccess != null) {
        onSuccess(result);
      }

      return result;
    } on ApiException catch (e) {
      errorMessage.value = e.userMessage;

      if (onError != null) {
        onError(e);
      } else {
        _showErrorSnackbar(e.userMessage);
      }

      return null;
    } catch (e) {
      const message = 'Something went wrong';
      errorMessage.value = message;

      if (onError != null) {
        onError(const ApiErrorException(
          message: 'Unknown error',
          userMessage: message,
        ));
      } else {
        _showErrorSnackbar(message);
      }

      return null;
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    if (Get.isSnackbarOpen) return;

    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show success snackbar
  void showSuccess(String message) {
    if (Get.isSnackbarOpen) return;

    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}
```

### Step 2: Create base_screen.dart

```dart
// lib/core/base/base_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/error_widget.dart' as app;
import 'base_controller.dart';

/// Base screen with loading overlay and error handling
abstract class BaseScreen<T extends BaseController> extends GetView<T> {
  const BaseScreen({super.key});

  /// Build screen content
  Widget buildContent(BuildContext context);

  /// Optional app bar
  PreferredSizeWidget? buildAppBar(BuildContext context) => null;

  /// Optional floating action button
  Widget? buildFab(BuildContext context) => null;

  /// Optional bottom navigation bar
  Widget? buildBottomNav(BuildContext context) => null;

  /// Background color
  Color? get backgroundColor => null;

  /// Whether to use safe area
  bool get useSafeArea => true;

  /// Whether to show loading overlay
  bool get showLoadingOverlay => true;

  /// Custom loading message
  String? get loadingMessage => null;

  @override
  Widget build(BuildContext context) {
    Widget content = buildContent(context);

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    // Wrap with loading overlay
    if (showLoadingOverlay) {
      content = LoadingOverlay(
        isLoading: controller.isLoading,
        message: loadingMessage,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildAppBar(context),
      body: content,
      floatingActionButton: buildFab(context),
      bottomNavigationBar: buildBottomNav(context),
    );
  }
}

/// Simple stateless screen without controller
abstract class BaseStatelessScreen extends StatelessWidget {
  const BaseStatelessScreen({super.key});

  Widget buildContent(BuildContext context);

  PreferredSizeWidget? buildAppBar(BuildContext context) => null;
  Widget? buildFab(BuildContext context) => null;
  Widget? buildBottomNav(BuildContext context) => null;
  Color? get backgroundColor => null;
  bool get useSafeArea => true;

  @override
  Widget build(BuildContext context) {
    Widget content = buildContent(context);

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildAppBar(context),
      body: content,
      floatingActionButton: buildFab(context),
      bottomNavigationBar: buildBottomNav(context),
    );
  }
}
```

### Step 3: Create loading_widget.dart

```dart
// lib/shared/widgets/loading_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Animated loading widget with pulsating glow
class LoadingWidget extends StatefulWidget {
  final String? message;
  final double? size;
  final Color? glowColor;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.glowColor,
  });

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
    final glowColor = widget.glowColor ?? AppColors.primary;
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
                      alpha: 0.3 + 0.2 * math.sin(_controller.value * 2 * math.pi),
                    ),
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
            child: Container(
              width: loadingSize,
              height: loadingSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.local_florist,
                size: loadingSize * 0.6,
                color: glowColor,
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

### Step 4: Create loading_overlay.dart

```dart
// lib/shared/widgets/loading_overlay.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'loading_widget.dart';

/// Loading overlay that blocks interaction
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
  Widget build(BuildContext context) {
    return Obx(() {
      return Stack(
        children: [
          child,
          if (isLoading.value)
            Container(
              color: Colors.black54,
              child: LoadingWidget(message: message),
            ),
        ],
      );
    });
  }
}

/// Show loading overlay as dialog
void showLoadingDialog({String? message}) {
  Get.dialog(
    PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LoadingWidget(message: message, size: 60),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

/// Hide loading dialog
void hideLoadingDialog() {
  if (Get.isDialogOpen ?? false) {
    Get.back();
  }
}
```

### Step 5: Create app_button.dart

```dart
// lib/shared/widgets/app_button.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, text, outline }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? 52.0;
    final buttonPadding = padding ?? const EdgeInsets.symmetric(horizontal: 24);

    Widget child = isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(text, style: _textStyle),
            ],
          );

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(isFullWidth ? double.infinity : 0, buttonHeight),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: child,
        );
        break;

      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            minimumSize: Size(isFullWidth ? double.infinity : 0, buttonHeight),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: child,
        );
        break;

      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 0, buttonHeight),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: AppColors.primary),
          ),
          child: child,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 0, buttonHeight),
            padding: buttonPadding,
          ),
          child: child,
        );
        break;
    }

    return button;
  }

  TextStyle get _textStyle {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
        return AppTextStyles.button;
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return AppTextStyles.button.copyWith(color: AppColors.primary);
    }
  }
}
```

### Step 6: Create app_text_field.dart

```dart
// lib/shared/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.focusNode,
    this.contentPadding,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.label),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textHint,
            ),
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscureText = !_obscureText);
                    },
                  )
                : widget.suffixIcon,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }
}
```

### Step 7: Create remaining widgets and models

```dart
// lib/shared/widgets/app_text.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';

enum AppTextVariant { h1, h2, h3, bodyLarge, bodyMedium, bodySmall, caption, label }

class AppText extends StatelessWidget {
  final String text;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _getStyle().copyWith(color: color),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _getStyle() {
    switch (variant) {
      case AppTextVariant.h1:
        return AppTextStyles.h1;
      case AppTextVariant.h2:
        return AppTextStyles.h2;
      case AppTextVariant.h3:
        return AppTextStyles.h3;
      case AppTextVariant.bodyLarge:
        return AppTextStyles.bodyLarge;
      case AppTextVariant.bodyMedium:
        return AppTextStyles.bodyMedium;
      case AppTextVariant.bodySmall:
        return AppTextStyles.bodySmall;
      case AppTextVariant.caption:
        return AppTextStyles.caption;
      case AppTextVariant.label:
        return AppTextStyles.label;
    }
  }
}
```

```dart
// lib/shared/widgets/app_icon.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final VoidCallback? onTap;

  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: size ?? 24,
      color: color ?? AppColors.textPrimary,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: iconWidget,
        ),
      );
    }

    return iconWidget;
  }
}
```

```dart
// lib/shared/widgets/error_widget.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'app_button.dart';
import 'app_text.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            AppText(
              message,
              variant: AppTextVariant.bodyLarge,
              textAlign: TextAlign.center,
              color: AppColors.textSecondary,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: 'Try Again',
                onPressed: onRetry,
                isFullWidth: false,
                variant: AppButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/shared/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? nativeLanguage;
  final String? targetLanguage;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.nativeLanguage,
    this.targetLanguage,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      nativeLanguage: json['native_language'] as String?,
      targetLanguage: json['target_language'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'native_language': nativeLanguage,
      'target_language': targetLanguage,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? nativeLanguage,
    String? targetLanguage,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

```dart
// lib/shared/models/api_error_model.dart
class ApiErrorModel {
  final int code;
  final String message;
  final Map<String, List<String>>? errors;

  const ApiErrorModel({
    required this.code,
    required this.message,
    this.errors,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? 'Unknown error',
      errors: _parseErrors(json['errors']),
    );
  }

  static Map<String, List<String>>? _parseErrors(dynamic errors) {
    if (errors is! Map) return null;
    return errors.map((key, value) => MapEntry(
          key.toString(),
          (value is List) ? value.map((e) => e.toString()).toList() : [value.toString()],
        ));
  }

  String get firstError {
    if (errors == null || errors!.isEmpty) return message;
    final firstKey = errors!.keys.first;
    return errors![firstKey]?.first ?? message;
  }
}
```

```dart
// lib/core/utils/validators.dart
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.length < min) {
      return '${fieldName ?? 'This field'} must be at least $min characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
```

```dart
// lib/core/utils/extensions.dart
extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get capitalizeWords {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  bool get isEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
}

extension DateTimeExtension on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get formatted {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }
}

extension DurationExtension on Duration {
  String get formatted {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (inHours > 0) {
      return '${inHours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
```

## Todo List

- [x] Create base_controller.dart with apiCall wrapper
- [x] Create base_screen.dart with loading overlay
- [x] Create loading_widget.dart with pulsating animation
- [x] Create loading_overlay.dart
- [x] Create app_button.dart with variants
- [x] Create app_text_field.dart with validation
- [x] Create app_text.dart with typography variants
- [x] Create app_icon.dart
- [x] Create error_widget.dart
- [x] Create user_model.dart
- [x] Create api_error_model.dart
- [x] Create validators.dart
- [x] Create extensions.dart
- [x] Test compilation with flutter analyze

## Success Criteria

- BaseController.apiCall handles loading/error automatically
- BaseScreen wraps content with loading overlay
- All widgets follow app color palette
- LoadingWidget shows animated pulsating glow
- AppButton has all variants working
- AppTextField shows/hides password, shows errors

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Widget inconsistency | Medium | Use shared constants everywhere |
| Animation performance | Low | Use simple transforms, avoid overdraw |

## Security Considerations

- Password field obscures text by default
- Validator functions don't log sensitive data

## Next Steps

After completion, proceed to [Phase 5: Routing & Localization](./phase-05-routing-localization.md).
