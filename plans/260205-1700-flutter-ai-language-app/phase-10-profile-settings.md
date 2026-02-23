---
phase: 10
title: "Feature - Profile & Settings"
status: pending
effort: 1.5h
depends_on: [6, 7]
---

# Phase 10: Feature - Profile & Settings

## Context Links

- [Main Plan](./plan.md)
- Depends on: [Phase 6](./phase-06-feature-auth.md), [Phase 7](./phase-07-feature-home.md)

## Overview

**Priority:** P3 - Supporting Feature
**Status:** pending
**Description:** Implement profile screen with statistics and settings screen with cache management and language switching.

## Key Insights

- Profile shows learning statistics
- Settings includes language switch, cache clear, storage usage
- Logout triggers from settings
- Storage usage calculated from StorageService

## Requirements

### Functional
- Display user profile with avatar, name, email
- Show learning statistics (lessons, time, words, accuracy)
- Language switching (EN/VI)
- Clear cache with confirmation
- Show storage usage breakdown
- Logout from settings

### Non-Functional
- Instant language switch via GetX
- Cache clear shows loading
- Stats update on screen load

## Architecture

```
features/profile/
├── bindings/
│   └── profile_binding.dart
├── controllers/
│   └── profile_controller.dart
├── views/
│   └── profile_screen.dart
└── widgets/
    └── stats_widget.dart

features/settings/
├── bindings/
│   └── settings_binding.dart
├── controllers/
│   └── settings_controller.dart
└── views/
    └── settings_screen.dart
```

## Related Code Files

### Files to Create
- `lib/features/profile/bindings/profile_binding.dart`
- `lib/features/profile/controllers/profile_controller.dart`
- `lib/features/profile/views/profile_screen.dart`
- `lib/features/profile/widgets/stats_widget.dart`
- `lib/features/settings/bindings/settings_binding.dart`
- `lib/features/settings/controllers/settings_controller.dart`
- `lib/features/settings/views/settings_screen.dart`

## Implementation Steps

### Step 1: Create profile_binding.dart

```dart
// lib/features/profile/bindings/profile_binding.dart
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
```

### Step 2: Create profile_controller.dart

```dart
// lib/features/profile/controllers/profile_controller.dart
import 'package:get/get.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../shared/models/user_model.dart';

class ProfileController extends BaseController {
  final ApiClient _api = Get.find();

  final user = Rxn<UserModel>();

  // Statistics
  final totalLessons = 0.obs;
  final studyMinutes = 0.obs;
  final wordsLearned = 0.obs;
  final accuracy = 0.0.obs;
  final streak = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    fetchStats();
  }

  /// Fetch user profile
  Future<void> fetchProfile() async {
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
      showLoading: user.value == null,
    );
  }

  /// Fetch learning statistics
  Future<void> fetchStats() async {
    await apiCall(
      () async {
        final response = await _api.get<Map<String, dynamic>>(
          ApiEndpoints.stats,
          fromJson: (data) => data as Map<String, dynamic>,
        );

        if (response.isSuccess && response.data != null) {
          final data = response.data!;
          totalLessons.value = data['total_lessons'] as int? ?? 0;
          studyMinutes.value = data['study_minutes'] as int? ?? 0;
          wordsLearned.value = data['words_learned'] as int? ?? 0;
          accuracy.value = (data['accuracy'] as num?)?.toDouble() ?? 0.0;
          streak.value = data['streak'] as int? ?? 0;
        }

        return response;
      },
      showLoading: false,
    );
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchProfile(),
      fetchStats(),
    ]);
  }

  /// Format study time
  String get formattedStudyTime {
    final hours = studyMinutes.value ~/ 60;
    final mins = studyMinutes.value % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}
```

### Step 3: Create profile_screen.dart

```dart
// lib/features/profile/views/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/profile_controller.dart';
import '../widgets/stats_widget.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.user.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 32),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildAchievements(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader() {
    return Obx(() {
      final user = controller.user.value;

      return Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: user?.avatarUrl != null
                ? NetworkImage(user!.avatarUrl!)
                : null,
            child: user?.avatarUrl == null
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primary,
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Name
          AppText(
            user?.name ?? 'Learner',
            variant: AppTextVariant.h2,
          ),
          const SizedBox(height: 4),

          // Email
          AppText(
            user?.email ?? '',
            variant: AppTextVariant.bodyMedium,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),

          // Streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Obx(() => AppText(
                      '${controller.streak.value} ${'streak'.tr}',
                      variant: AppTextVariant.label,
                      color: AppColors.warning,
                    )),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText('statistics'.tr, variant: AppTextVariant.h3),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Obx(() => StatsWidget(
                    icon: Icons.book,
                    value: controller.totalLessons.value.toString(),
                    label: 'total_lessons'.tr,
                    color: AppColors.primary,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => StatsWidget(
                    icon: Icons.timer,
                    value: controller.formattedStudyTime,
                    label: 'study_time'.tr,
                    color: AppColors.secondary,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Obx(() => StatsWidget(
                    icon: Icons.abc,
                    value: controller.wordsLearned.value.toString(),
                    label: 'words_learned'.tr,
                    color: AppColors.info,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => StatsWidget(
                    icon: Icons.check_circle,
                    value: '${(controller.accuracy.value * 100).round()}%',
                    label: 'accuracy'.tr,
                    color: AppColors.success,
                  )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText('Achievements', variant: AppTextVariant.h3),
          const SizedBox(height: 16),
          Center(
            child: AppText(
              'Coming soon!',
              variant: AppTextVariant.bodyMedium,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 4: Create stats_widget.dart

```dart
// lib/features/profile/widgets/stats_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_text.dart';

class StatsWidget extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatsWidget({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          AppText(
            value,
            variant: AppTextVariant.h2,
            color: color,
          ),
          const SizedBox(height: 4),
          AppText(
            label,
            variant: AppTextVariant.caption,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
```

### Step 5: Create settings_binding.dart

```dart
// lib/features/settings/bindings/settings_binding.dart
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
```

### Step 6: Create settings_controller.dart

```dart
// lib/features/settings/controllers/settings_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/auth_storage.dart';
import '../../../l10n/translations.dart';
import '../../../app/routes/app_routes.dart';

class SettingsController extends BaseController {
  final StorageService _storage = Get.find();
  final AuthStorage _authStorage = Get.find();

  // Settings state
  final currentLanguage = AppLocales.english.obs;
  final notificationsEnabled = true.obs;
  final soundEnabled = true.obs;

  // Storage info
  final lessonsCacheSize = 0.obs;
  final chatCacheSize = 0.obs;
  final totalCacheSize = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _updateStorageInfo();
  }

  void _loadSettings() {
    // Load from preferences
    currentLanguage.value =
        _storage.getPreference<String>('language') ?? AppLocales.english;
    notificationsEnabled.value =
        _storage.getPreference<bool>('notifications') ?? true;
    soundEnabled.value = _storage.getPreference<bool>('sound') ?? true;
  }

  void _updateStorageInfo() {
    lessonsCacheSize.value = _storage.lessonsCacheSize;
    chatCacheSize.value = _storage.chatCacheSize;
    totalCacheSize.value = _storage.totalCacheSize;
  }

  /// Change app language
  Future<void> changeLanguage(String locale) async {
    currentLanguage.value = locale;
    await _storage.setPreference('language', locale);

    // Update GetX locale
    final parts = locale.split('_');
    Get.updateLocale(Locale(parts[0], parts.length > 1 ? parts[1] : null));
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool value) async {
    notificationsEnabled.value = value;
    await _storage.setPreference('notifications', value);
  }

  /// Toggle sound
  Future<void> toggleSound(bool value) async {
    soundEnabled.value = value;
    await _storage.setPreference('sound', value);
  }

  /// Clear all cache
  Future<void> clearCache() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('clear_cache'.tr),
        content: Text(
          'This will delete all cached lessons and chat messages. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'confirm'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await apiCall(
      () async {
        await _storage.clearAllCaches();
        _updateStorageInfo();
        return true;
      },
      onSuccess: (_) {
        showSuccess('cache_cleared'.tr);
      },
    );
  }

  /// Logout
  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('logout'.tr),
        content: Text('logout_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _authStorage.clearTokens();
    Get.offAllNamed(AppRoutes.login);
  }

  /// Format bytes to human readable
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

### Step 7: Create settings_screen.dart

```dart
// lib/features/settings/views/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../l10n/translations.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Preferences',
            [
              _buildLanguageTile(),
              _buildSwitchTile(
                icon: Icons.notifications,
                title: 'notifications'.tr,
                value: controller.notificationsEnabled,
                onChanged: controller.toggleNotifications,
              ),
              _buildSwitchTile(
                icon: Icons.volume_up,
                title: 'sound'.tr,
                value: controller.soundEnabled,
                onChanged: controller.toggleSound,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Storage',
            [
              _buildStorageInfo(),
              _buildActionTile(
                icon: Icons.delete_outline,
                title: 'clear_cache'.tr,
                subtitle: 'Free up storage space',
                onTap: controller.clearCache,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'About',
            [
              _buildInfoTile(
                icon: Icons.info_outline,
                title: 'version'.tr,
                subtitle: '1.0.0',
              ),
              _buildActionTile(
                icon: Icons.description_outlined,
                title: 'privacy_policy'.tr,
                onTap: () {
                  // Open privacy policy
                },
              ),
              _buildActionTile(
                icon: Icons.gavel_outlined,
                title: 'terms_of_service'.tr,
                onTap: () {
                  // Open terms
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Account',
            [
              _buildActionTile(
                icon: Icons.logout,
                title: 'logout'.tr,
                onTap: controller.logout,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: AppText(
            title,
            variant: AppTextVariant.label,
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageTile() {
    return Obx(() {
      final currentLang = controller.currentLanguage.value;
      final langName = AppLocales.supportedLocales
          .firstWhere((l) => l['code'] == currentLang)['name'];

      return ListTile(
        leading: const Icon(Icons.language, color: AppColors.primary),
        title: Text('language'.tr),
        subtitle: Text(langName ?? 'English'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLanguageDialog(),
      );
    });
  }

  void _showLanguageDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('language'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLocales.supportedLocales.map((locale) {
            return Obx(() => RadioListTile<String>(
                  title: Text(locale['name']!),
                  value: locale['code']!,
                  groupValue: controller.currentLanguage.value,
                  onChanged: (value) {
                    if (value != null) {
                      controller.changeLanguage(value);
                      Get.back();
                    }
                  },
                ));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required RxBool value,
    required Function(bool) onChanged,
  }) {
    return Obx(() => SwitchListTile(
          secondary: Icon(icon, color: AppColors.primary),
          title: Text(title),
          value: value.value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ));
  }

  Widget _buildStorageInfo() {
    return Obx(() => ListTile(
          leading: const Icon(Icons.storage, color: AppColors.primary),
          title: Text('storage_usage'.tr),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildStorageRow(
                'Lessons',
                controller.lessonsCacheSize.value,
                AppColors.secondary,
              ),
              const SizedBox(height: 4),
              _buildStorageRow(
                'Chat',
                controller.chatCacheSize.value,
                AppColors.primary,
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${controller.formatBytes(controller.totalCacheSize.value)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildStorageRow(String label, int bytes, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ${controller.formatBytes(bytes)}',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
```

## Todo List

- [ ] Create profile_binding.dart
- [ ] Create profile_controller.dart with stats
- [ ] Create profile_screen.dart
- [ ] Create stats_widget.dart
- [ ] Create settings_binding.dart
- [ ] Create settings_controller.dart with cache management
- [ ] Create settings_screen.dart
- [ ] Update app_pages.dart
- [ ] Test language switching
- [ ] Test cache clearing
- [ ] Test storage usage display
- [ ] Test logout flow

## Success Criteria

- Profile shows user info and statistics
- Stats grid displays all metrics
- Language switches instantly
- Cache clear shows confirmation
- Storage usage breakdown accurate
- Logout clears tokens and navigates to login

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Language change breaks UI | Medium | Test all strings in both languages |
| Cache size inaccurate | Low | Use conservative estimates |

## Security Considerations

- Logout clears all tokens
- No sensitive data exposed in settings
- Cache clear removes all local data

## Next Steps

After Phase 10 completion:
1. Run full test pass across all features
2. Fix any integration issues
3. Add unit tests for controllers
4. Performance optimization
5. Deploy to staging
