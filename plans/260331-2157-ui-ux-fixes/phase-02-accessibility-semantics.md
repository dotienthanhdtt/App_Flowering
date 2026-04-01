# Phase 2: Accessibility Semantics

## Context
- Report: `plans/reports/ui-ux-review-260331-2149-flowering-app.md` §2.2
- Currently zero `Semantics` widgets across the app

## Overview
- **Priority:** CRITICAL
- **Status:** Pending
- **Description:** Add screen reader support to core shared widgets

## Key Insights
- Focus on shared widgets first — they propagate A11y to all screens
- Flutter's Material widgets provide *some* default semantics (buttons, text fields)
- Main gaps: custom widgets, icon-only actions, loading/error states, OTP field

## Requirements
- TalkBack/VoiceOver must be able to navigate all interactive elements
- Loading states must announce to screen readers
- Error states must announce to screen readers
- Decorative elements must be excluded from semantics tree

## Related Code Files
- **Modify:** `lib/shared/widgets/app_button.dart` (166 lines)
- **Modify:** `lib/shared/widgets/app_text_field.dart` (164 lines)
- **Modify:** `lib/shared/widgets/loading_widget.dart` (108 lines)
- **Modify:** `lib/shared/widgets/loading_overlay.dart` (61 lines)
- **Modify:** `lib/features/auth/widgets/otp_input_field.dart` (148 lines)

## Implementation Steps

### 1. `app_button.dart` — Add semantic label
Wrap the returned button in `Semantics`:
```dart
return Semantics(
  button: true,
  enabled: !isLoading,
  label: isLoading ? '$text, loading' : text,
  child: button,
);
```
At line 147, replace `return button;` with the Semantics wrapper.

### 2. `app_text_field.dart` — Semantic label for password toggle
The password toggle `IconButton` at line 108 needs a tooltip/semantic label:
```dart
IconButton(
  icon: Icon(
    _obscureText ? Icons.visibility_off : Icons.visibility,
    color: AppColors.textSecondaryColor,
    semanticLabel: _obscureText ? 'Show password' : 'Hide password',
  ),
  onPressed: () {
    setState(() => _obscureText = !_obscureText);
  },
)
```
Also: TextFormField already gets semantics from `label`/`hint` — Material handles this.

### 3. `loading_widget.dart` — Announce loading state
Wrap the `Center` widget in `Semantics`:
```dart
return Semantics(
  label: widget.message ?? 'Loading',
  liveRegion: true,
  child: Center(
    // ... existing code
  ),
);
```
Mark the flower icon as decorative:
```dart
child: ExcludeSemantics(
  child: Icon(
    Icons.local_florist,
    size: loadingSize * 0.6,
    color: glowColor,
  ),
),
```

### 4. `loading_overlay.dart` — Announce blocking overlay
The overlay should announce when it appears:
```dart
if (isLoading.value)
  Semantics(
    label: message ?? 'Loading, please wait',
    liveRegion: true,
    child: Container(
      color: Colors.black54,
      child: LoadingWidget(message: message),
    ),
  ),
```

### 5. `otp_input_field.dart` — Semantic group label
Wrap the `Row` in a semantic group:
```dart
return Semantics(
  label: 'Verification code, 6 digits',
  child: Row(
    // ... existing
  ),
);
```
Each `_OtpBox` TextField already gets default field semantics from Material.

## Todo
- [ ] Add Semantics wrapper to `AppButton` return
- [ ] Add `semanticLabel` to password toggle icon in `AppTextField`
- [ ] Add Semantics + ExcludeSemantics to `LoadingWidget`
- [ ] Add Semantics to `LoadingOverlay` overlay container
- [ ] Add Semantics group to `OtpInputField`
- [ ] Run `flutter analyze`
- [ ] Test with iOS VoiceOver or Android TalkBack

## Success Criteria
- All buttons announce their label and loading state
- Password toggle announces "Show/Hide password"
- Loading states announced as live regions
- OTP field grouped as "Verification code"
- `flutter analyze` passes

## Risk Assessment
- **Low risk:** Adding Semantics wrappers doesn't change visual output
- Must use `.tr` for any user-facing semantic labels
- `liveRegion: true` may over-announce on some screen readers — test
