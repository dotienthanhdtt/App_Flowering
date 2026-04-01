# Phase 4: Haptic Feedback & Loading Improvements

## Context
- Report: `plans/reports/ui-ux-review-260331-2149-flowering-app.md` §3.1, §3.2

## Overview
- **Priority:** HIGH
- **Status:** Pending
- **Description:** Add haptic feedback to buttons and add timeout/cancel to loading overlay

## Related Code Files
- **Modify:** `lib/shared/widgets/app_button.dart` (166 lines)
- **Modify:** `lib/shared/widgets/loading_overlay.dart` (61 lines)
- **Modify:** `lib/features/auth/widgets/otp_input_field.dart` (148 lines)

## Implementation Steps

### 1. `app_button.dart` — Haptic on tap
Already imports `flutter/services.dart` is NOT present. Add import and wrap onPressed:

At top, add:
```dart
import 'package:flutter/services.dart';
```

For each button variant, the `onPressed` callback needs haptic. Best approach: wrap in the build method before the switch. Create a local callback:
```dart
final effectiveOnPressed = (isLoading || onPressed == null)
    ? null
    : () {
        HapticFeedback.lightImpact();
        onPressed!();
      };
```
Then use `effectiveOnPressed` instead of `isLoading ? null : onPressed` in all 4 variants.

### 2. `otp_input_field.dart` — Haptic on digit entry
Already imports `flutter/services.dart`. In `_onChanged`, add haptic when a digit is entered:
```dart
void _onChanged(int index, String value) {
  if (value.isNotEmpty) {
    HapticFeedback.selectionClick();
  }
  // ... rest of existing logic
}
```

### 3. `loading_overlay.dart` — Add timeout with auto-dismiss
Add optional timeout parameter (default 30s). When timeout fires, dismiss and show error:

```dart
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final RxBool isLoading;
  final String? message;
  final Duration timeout;
  final VoidCallback? onTimeout;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.timeout = const Duration(seconds: 30),
    this.onTimeout,
  });
```

For the dialog variant `showLoadingDialog`, add auto-dismiss:
```dart
void showLoadingDialog({
  String? message,
  Duration timeout = const Duration(seconds: 30),
}) {
  Get.dialog(
    PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.space8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
          child: LoadingWidget(message: message, size: AppSizes.space16),
        ),
      ),
    ),
    barrierDismissible: false,
  );

  // Auto-dismiss after timeout
  Future.delayed(timeout, () {
    if (Get.isDialogOpen ?? false) {
      hideLoadingDialog();
    }
  });
}
```

## Todo
- [ ] Add `HapticFeedback.lightImpact()` to `AppButton` onPressed
- [ ] Add `HapticFeedback.selectionClick()` to OTP digit entry
- [ ] Add timeout auto-dismiss to `showLoadingDialog`
- [ ] Add `timeout` and `onTimeout` params to `LoadingOverlay`
- [ ] Run `flutter analyze`

## Success Criteria
- Buttons produce light haptic on tap (testable on physical device)
- OTP digit entry produces selection click haptic
- Loading dialog auto-dismisses after 30s if API hangs
- No compile errors

## Risk Assessment
- **Low:** Haptic is additive — no existing behavior changes
- **Medium:** Loading timeout must not dismiss while a valid long operation runs
  - Mitigation: 30s is generous; callers can override with longer timeout
- Haptic doesn't work on iOS simulator — must test on device
