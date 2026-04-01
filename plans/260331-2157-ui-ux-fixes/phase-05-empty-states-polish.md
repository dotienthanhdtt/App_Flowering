# Phase 5: Empty States & Polish

## Context
- Report: `plans/reports/ui-ux-review-260331-2149-flowering-app.md` §4.3, §4.5

## Overview
- **Priority:** MEDIUM
- **Status:** Pending
- **Description:** Create reusable empty state widget and tune animation timings

## Related Code Files
- **Create:** `lib/shared/widgets/empty_state_widget.dart`
- **Modify:** `lib/app/routes/app-page-definitions-with-transitions.dart` (transition timings)
- **Modify:** `lib/features/chat/widgets/ai_typing_bubble.dart` (timing)
- **Modify:** `lib/shared/widgets/loading_widget.dart` (timing)

## Implementation Steps

### 1. Create `empty_state_widget.dart`
Reusable widget for empty lists, no data, offline states:

```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'app_text.dart';
import 'app_button.dart';

/// Generic empty state with icon, title, subtitle, and optional CTA.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.icon4XL + AppSizes.space4,
              height: AppSizes.icon4XL + AppSizes.space4,
              decoration: BoxDecoration(
                color: AppColors.primarySoftColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppSizes.icon3XL, color: AppColors.primaryColor),
            ),
            const SizedBox(height: AppSizes.space6),
            AppText(title, variant: AppTextVariant.h3, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.space2),
              AppText(
                subtitle!,
                variant: AppTextVariant.bodyMedium,
                color: AppColors.textSecondaryColor,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.space6),
              AppButton(
                text: actionLabel!,
                onPressed: onAction,
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

Usage example:
```dart
EmptyStateWidget(
  icon: Icons.chat_bubble_outline,
  title: 'no_conversations'.tr,
  subtitle: 'start_first_conversation'.tr,
  actionLabel: 'start_chat'.tr,
  onAction: () => Get.toNamed(AppRoutes.chat),
)
```

### 2. Tune animation timings

| File | Constant | Old | New |
|------|----------|-----|-----|
| `loading_widget.dart` | duration | 1500ms | 1200ms |
| `ai_typing_bubble.dart` | duration | 900ms | 800ms |
| `app-page-definitions-with-transitions.dart` | default transition | 300ms | 250ms |
| `app-page-definitions-with-transitions.dart` | splash fade | 500ms | 400ms |

### 3. Add translation keys
Add to both l10n files:
- `no_conversations` / `start_first_conversation` / `start_chat`
- `no_vocabulary` / `start_learning_vocabulary`
- `no_lessons_completed` / `explore_lessons`
- `no_internet` / `check_connection`

## Todo
- [ ] Create `lib/shared/widgets/empty_state_widget.dart`
- [ ] Add translation keys to `english-translations-en-us.dart`
- [ ] Add translation keys to `vietnamese-translations-vi-vn.dart`
- [ ] Update animation timings in 3 files
- [ ] Run `flutter analyze`

## Success Criteria
- `EmptyStateWidget` renders with icon + title + optional subtitle + optional CTA
- Animation timings feel snappier
- All translation keys present in both languages
- `flutter analyze` passes

## Risk Assessment
- **Low:** New widget, no existing code modified (except timings)
- Empty state widget follows existing patterns (uses AppText, AppButton, AppColors)
- Timing changes are subjective — may need user feedback
