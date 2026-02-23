---
phase: 7
title: "Feature - Home"
status: pending
effort: 1.5h
depends_on: [6]
---

# Phase 7: Feature - Home

## Context Links

- [Main Plan](./plan.md)
- Depends on: [Phase 6](./phase-06-feature-auth.md)

## Overview

**Priority:** P2 - Core Feature
**Status:** pending
**Description:** Implement home screen with learning progress, daily goals, and quick actions.

## Key Insights

- Home is the main dashboard after login
- Shows user progress, streak, daily goals
- Quick navigation to lessons, chat, profile
- Fetches data on screen load

## Requirements

### Functional
- Display welcome message with user name
- Show learning streak and daily progress
- Quick action cards for lessons, chat
- Pull-to-refresh for data update

### Non-Functional
- Smooth loading state
- Cached data shown while refreshing
- Responsive layout

## Architecture

```
features/home/
├── bindings/
│   └── home_binding.dart
├── controllers/
│   └── home_controller.dart
├── views/
│   └── home_screen.dart
└── widgets/
    ├── progress_card.dart
    └── quick_action_card.dart
```

## Related Code Files

### Files to Create
- `lib/features/home/bindings/home_binding.dart`
- `lib/features/home/controllers/home_controller.dart`
- `lib/features/home/views/home_screen.dart`
- `lib/features/home/widgets/progress_card.dart`
- `lib/features/home/widgets/quick_action_card.dart`

### Files to Modify
- `lib/app/routes/app_pages.dart` - Uncomment home imports

## Implementation Steps

### Step 1: Create home_binding.dart

```dart
// lib/features/home/bindings/home_binding.dart
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
```

### Step 2: Create home_controller.dart

```dart
// lib/features/home/controllers/home_controller.dart
import 'package:get/get.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/auth_storage.dart';
import '../../../shared/models/user_model.dart';

class HomeController extends BaseController {
  final ApiClient _api = Get.find();
  final AuthStorage _authStorage = Get.find();

  // User data
  final Rxn<UserModel> user = Rxn<UserModel>();

  // Progress data
  final streak = 0.obs;
  final dailyProgress = 0.0.obs; // 0.0 to 1.0
  final totalLessonsCompleted = 0.obs;
  final totalStudyMinutes = 0.obs;
  final wordsLearned = 0.obs;

  // Recent lessons
  final recentLessons = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
  }

  /// Fetch all home screen data
  Future<void> fetchHomeData() async {
    await Future.wait([
      fetchUserProfile(),
      fetchProgress(),
      fetchRecentLessons(),
    ]);
  }

  /// Refresh data (pull-to-refresh)
  Future<void> refreshData() async {
    await fetchHomeData();
  }

  /// Fetch user profile
  Future<void> fetchUserProfile() async {
    await apiCall(
      () async {
        final response = await _api.get<Map<String, dynamic>>(
          ApiEndpoints.profile,
          fromJson: (data) => data as Map<String, dynamic>,
        );

        if (response.isSuccess && response.data != null) {
          user.value = UserModel.fromJson(response.data!);
        }

        return response;
      },
      showLoading: false,
    );
  }

  /// Fetch learning progress
  Future<void> fetchProgress() async {
    await apiCall(
      () async {
        final response = await _api.get<Map<String, dynamic>>(
          ApiEndpoints.progress,
          fromJson: (data) => data as Map<String, dynamic>,
        );

        if (response.isSuccess && response.data != null) {
          final data = response.data!;
          streak.value = data['streak'] as int? ?? 0;
          dailyProgress.value = (data['daily_progress'] as num?)?.toDouble() ?? 0.0;
          totalLessonsCompleted.value = data['total_lessons'] as int? ?? 0;
          totalStudyMinutes.value = data['study_minutes'] as int? ?? 0;
          wordsLearned.value = data['words_learned'] as int? ?? 0;
        }

        return response;
      },
      showLoading: false,
    );
  }

  /// Fetch recent lessons
  Future<void> fetchRecentLessons() async {
    await apiCall(
      () async {
        final response = await _api.get<List<dynamic>>(
          ApiEndpoints.lessons,
          queryParameters: {'limit': 3, 'sort': 'recent'},
          fromJson: (data) => data as List<dynamic>,
        );

        if (response.isSuccess && response.data != null) {
          recentLessons.value = response.data!
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }

        return response;
      },
      showLoading: false,
    );
  }

  /// Get greeting based on time of day
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Get user display name
  String get displayName => user.value?.name ?? 'Learner';
}
```

### Step 3: Create home_screen.dart

```dart
// lib/features/home/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/home_controller.dart';
import '../widgets/progress_card.dart';
import '../widgets/quick_action_card.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.user.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStreakCard(),
                  const SizedBox(height: 16),
                  _buildProgressSection(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildRecentLessons(),
                ],
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              controller.greeting,
              variant: AppTextVariant.bodyMedium,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Obx(() => AppText(
                  controller.displayName,
                  variant: AppTextVariant.h2,
                )),
          ],
        ),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.profile),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => AppText(
                    '${controller.streak.value} ${'streak'.tr}',
                    variant: AppTextVariant.h2,
                    color: Colors.white,
                  )),
              const SizedBox(height: 4),
              AppText(
                'Keep it up!',
                variant: AppTextVariant.bodyMedium,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText('daily_goal'.tr, variant: AppTextVariant.h3),
        const SizedBox(height: 12),
        Obx(() => ProgressCard(
              progress: controller.dailyProgress.value,
              label: 'Daily Progress',
              icon: Icons.track_changes,
            )),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText('continue_learning'.tr, variant: AppTextVariant.h3),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'lessons'.tr,
                icon: Icons.book,
                color: AppColors.secondary,
                onTap: () => Get.toNamed(AppRoutes.lessons),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                title: 'chat'.tr,
                icon: Icons.chat_bubble,
                color: AppColors.primary,
                onTap: () => Get.toNamed(AppRoutes.chat),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentLessons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText('lessons'.tr, variant: AppTextVariant.h3),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.lessons),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.recentLessons.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AppText(
                  'No lessons yet',
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return Column(
            children: controller.recentLessons
                .map((lesson) => _buildLessonItem(lesson))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildLessonItem(Map<String, dynamic> lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.book,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  lesson['title'] as String? ?? 'Lesson',
                  variant: AppTextVariant.bodyLarge,
                ),
                const SizedBox(height: 4),
                AppText(
                  '${lesson['progress'] ?? 0}% complete',
                  variant: AppTextVariant.caption,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      onTap: (index) {
        switch (index) {
          case 0:
            break; // Already on home
          case 1:
            Get.toNamed(AppRoutes.lessons);
            break;
          case 2:
            Get.toNamed(AppRoutes.chat);
            break;
          case 3:
            Get.toNamed(AppRoutes.profile);
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: 'home'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.book),
          label: 'lessons'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.chat),
          label: 'chat'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: 'profile'.tr,
        ),
      ],
    );
  }
}
```

### Step 4: Create progress_card.dart

```dart
// lib/features/home/widgets/progress_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_text.dart';

class ProgressCard extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;
  final IconData icon;
  final Color? color;

  const ProgressCard({
    super.key,
    required this.progress,
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? AppColors.primary;
    final percentage = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: progressColor, size: 20),
                  const SizedBox(width: 8),
                  AppText(label, variant: AppTextVariant.label),
                ],
              ),
              AppText(
                '$percentage%',
                variant: AppTextVariant.h3,
                color: progressColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: progressColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 5: Create quick_action_card.dart

```dart
// lib/features/home/widgets/quick_action_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_text.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            AppText(
              title,
              variant: AppTextVariant.bodyLarge,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                AppText(
                  'Start',
                  variant: AppTextVariant.caption,
                  color: color,
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## Todo List

- [ ] Create home_binding.dart
- [ ] Create home_controller.dart with data fetching
- [ ] Create home_screen.dart with dashboard UI
- [ ] Create progress_card.dart widget
- [ ] Create quick_action_card.dart widget
- [ ] Update app_pages.dart with home screen
- [ ] Test pull-to-refresh
- [ ] Test navigation to other screens

## Success Criteria

- Home screen shows after login
- User name displays in header
- Streak card shows current streak
- Daily progress bar updates
- Quick actions navigate correctly
- Pull-to-refresh works
- Bottom nav switches screens

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Multiple API calls slow load | Medium | Parallel fetching, show cached |
| Empty state looks broken | Low | Add proper empty state UI |

## Security Considerations

- No sensitive data displayed
- User data fetched with auth token

## Next Steps

After completion, proceed to [Phase 8: Chat Feature](./phase-08-feature-chat.md).
