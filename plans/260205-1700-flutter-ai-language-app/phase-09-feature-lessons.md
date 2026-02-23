---
phase: 9
title: "Feature - Lessons"
status: pending
effort: 2h
depends_on: [7]
---

# Phase 9: Feature - Lessons

## Context Links

- [Main Plan](./plan.md)
- [Storage Service](./phase-03-core-services.md)
- Depends on: [Phase 7](./phase-07-feature-home.md)

## Overview

**Priority:** P2 - Core Feature
**Status:** pending
**Description:** Implement lessons list and detail screens with offline caching using LRU eviction.

## Key Insights

- Lessons cached with LRU eviction (100MB limit)
- List view shows progress per lesson
- Detail view has lesson content and exercises
- Offline access to cached lessons

## Requirements

### Functional
- List all available lessons
- Show lesson progress status
- View lesson detail with content
- Cache lessons for offline access
- Filter lessons by status/category

### Non-Functional
- LRU cache eviction at 100MB
- Fast list scrolling with lazy loading
- Smooth transition to detail view

## Architecture

```
features/lessons/
├── bindings/
│   └── lesson_binding.dart
├── controllers/
│   └── lesson_controller.dart
├── models/
│   └── lesson_model.dart
├── views/
│   ├── lesson_list_screen.dart
│   └── lesson_detail_screen.dart
└── widgets/
    └── lesson_card.dart
```

## Related Code Files

### Files to Create
- `lib/features/lessons/bindings/lesson_binding.dart`
- `lib/features/lessons/controllers/lesson_controller.dart`
- `lib/features/lessons/models/lesson_model.dart`
- `lib/features/lessons/views/lesson_list_screen.dart`
- `lib/features/lessons/views/lesson_detail_screen.dart`
- `lib/features/lessons/widgets/lesson_card.dart`

## Implementation Steps

### Step 1: Create lesson_model.dart

```dart
// lib/features/lessons/models/lesson_model.dart
enum LessonStatus { notStarted, inProgress, completed }

class LessonModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String category;
  final int durationMinutes;
  final int totalExercises;
  final int completedExercises;
  final LessonStatus status;
  final List<LessonSection>? sections;
  final DateTime? lastAccessedAt;

  const LessonModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.category,
    required this.durationMinutes,
    required this.totalExercises,
    this.completedExercises = 0,
    this.status = LessonStatus.notStarted,
    this.sections,
    this.lastAccessedAt,
  });

  double get progress => totalExercises > 0
      ? completedExercises / totalExercises
      : 0.0;

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String? ?? 'General',
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      totalExercises: json['total_exercises'] as int? ?? 0,
      completedExercises: json['completed_exercises'] as int? ?? 0,
      status: _parseStatus(json['status'] as String?),
      sections: (json['sections'] as List<dynamic>?)
          ?.map((e) => LessonSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'duration_minutes': durationMinutes,
      'total_exercises': totalExercises,
      'completed_exercises': completedExercises,
      'status': status.name,
      'sections': sections?.map((e) => e.toJson()).toList(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
    };
  }

  static LessonStatus _parseStatus(String? status) {
    switch (status) {
      case 'in_progress':
        return LessonStatus.inProgress;
      case 'completed':
        return LessonStatus.completed;
      default:
        return LessonStatus.notStarted;
    }
  }

  LessonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    int? durationMinutes,
    int? totalExercises,
    int? completedExercises,
    LessonStatus? status,
    List<LessonSection>? sections,
    DateTime? lastAccessedAt,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalExercises: totalExercises ?? this.totalExercises,
      completedExercises: completedExercises ?? this.completedExercises,
      status: status ?? this.status,
      sections: sections ?? this.sections,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}

class LessonSection {
  final String id;
  final String title;
  final String content;
  final String type; // 'text', 'audio', 'exercise'
  final bool isCompleted;

  const LessonSection({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.isCompleted = false,
  });

  factory LessonSection.fromJson(Map<String, dynamic> json) {
    return LessonSection(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'is_completed': isCompleted,
    };
  }
}
```

### Step 2: Create lesson_binding.dart

```dart
// lib/features/lessons/bindings/lesson_binding.dart
import 'package:get/get.dart';
import '../controllers/lesson_controller.dart';

class LessonBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LessonController>(() => LessonController());
  }
}
```

### Step 3: Create lesson_controller.dart

```dart
// lib/features/lessons/controllers/lesson_controller.dart
import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/storage_service.dart';
import '../models/lesson_model.dart';

class LessonController extends BaseController {
  final ApiClient _api = Get.find();
  final StorageService _storage = Get.find();

  final lessons = <LessonModel>[].obs;
  final selectedLesson = Rxn<LessonModel>();
  final selectedFilter = 'all'.obs;

  static const String _cacheKeyPrefix = 'lesson_';

  List<LessonModel> get filteredLessons {
    switch (selectedFilter.value) {
      case 'in_progress':
        return lessons.where((l) => l.status == LessonStatus.inProgress).toList();
      case 'completed':
        return lessons.where((l) => l.status == LessonStatus.completed).toList();
      case 'not_started':
        return lessons.where((l) => l.status == LessonStatus.notStarted).toList();
      default:
        return lessons.toList();
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchLessons();
  }

  /// Fetch all lessons
  Future<void> fetchLessons() async {
    await apiCall(
      () async {
        // Load from cache first
        _loadFromCache();

        // Fetch from server
        final response = await _api.get<List<dynamic>>(
          ApiEndpoints.lessons,
          fromJson: (data) => data as List<dynamic>,
        );

        if (response.isSuccess && response.data != null) {
          lessons.value = response.data!
              .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _saveListToCache();
        }

        return response;
      },
      showLoading: lessons.isEmpty,
    );
  }

  /// Fetch lesson detail
  Future<void> fetchLessonDetail(String lessonId) async {
    // Check cache first
    final cached = _storage.getLesson('$_cacheKeyPrefix$lessonId');
    if (cached != null) {
      try {
        selectedLesson.value = LessonModel.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    await apiCall(
      () async {
        final response = await _api.get<Map<String, dynamic>>(
          ApiEndpoints.lessonDetail(lessonId),
          fromJson: (data) => data as Map<String, dynamic>,
        );

        if (response.isSuccess && response.data != null) {
          selectedLesson.value = LessonModel.fromJson(response.data!);
          _saveLessonToCache(selectedLesson.value!);
        }

        return response;
      },
      showLoading: selectedLesson.value == null,
    );
  }

  /// Start or continue lesson
  Future<void> startLesson(String lessonId) async {
    await fetchLessonDetail(lessonId);
    // Navigate handled by view
  }

  /// Mark section as completed
  Future<void> completeSection(String lessonId, String sectionId) async {
    await apiCall(
      () async {
        final response = await _api.post(
          '${ApiEndpoints.lessonDetail(lessonId)}/sections/$sectionId/complete',
        );

        if (response.isSuccess) {
          // Update local state
          if (selectedLesson.value != null) {
            final sections = selectedLesson.value!.sections?.map((s) {
              if (s.id == sectionId) {
                return LessonSection(
                  id: s.id,
                  title: s.title,
                  content: s.content,
                  type: s.type,
                  isCompleted: true,
                );
              }
              return s;
            }).toList();

            selectedLesson.value = selectedLesson.value!.copyWith(
              sections: sections,
              completedExercises: selectedLesson.value!.completedExercises + 1,
            );
            _saveLessonToCache(selectedLesson.value!);
          }
        }

        return response;
      },
      showLoading: false,
    );
  }

  /// Set filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  /// Clear selected lesson
  void clearSelection() {
    selectedLesson.value = null;
  }

  void _loadFromCache() {
    // Load lesson list from preferences
    final cached = _storage.getPreference<String>('lessons_list');
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List<dynamic>;
        lessons.value = list
            .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
  }

  void _saveListToCache() {
    final json = jsonEncode(lessons.map((l) => l.toJson()).toList());
    _storage.setPreference('lessons_list', json);
  }

  Future<void> _saveLessonToCache(LessonModel lesson) async {
    final json = jsonEncode(lesson.toJson());
    await _storage.saveLesson('$_cacheKeyPrefix${lesson.id}', json);
  }
}
```

### Step 4: Create lesson_list_screen.dart

```dart
// lib/features/lessons/views/lesson_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/lesson_controller.dart';
import '../widgets/lesson_card.dart';

class LessonListScreen extends GetView<LessonController> {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('lessons'.tr),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.lessons.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final lessons = controller.filteredLessons;

              if (lessons.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 64,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 16),
                      AppText(
                        'No lessons found',
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchLessons,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return LessonCard(
                      lesson: lesson,
                      onTap: () {
                        controller.fetchLessonDetail(lesson.id);
                        Get.toNamed(
                          AppRoutes.lessonDetail,
                          arguments: lesson.id,
                        );
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'value': 'all', 'label': 'All'},
      {'value': 'in_progress', 'label': 'In Progress'},
      {'value': 'completed', 'label': 'Completed'},
      {'value': 'not_started', 'label': 'New'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Obx(() => Row(
            children: filters.map((filter) {
              final isSelected = controller.selectedFilter.value == filter['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter['label']!),
                  selected: isSelected,
                  onSelected: (_) => controller.setFilter(filter['value']!),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }
}
```

### Step 5: Create lesson_detail_screen.dart

```dart
// lib/features/lessons/views/lesson_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../shared/widgets/app_button.dart';
import '../controllers/lesson_controller.dart';
import '../models/lesson_model.dart';

class LessonDetailScreen extends GetView<LessonController> {
  const LessonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final lesson = controller.selectedLesson.value;

        if (controller.isLoading.value && lesson == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (lesson == null) {
          return Center(
            child: AppText('Lesson not found', color: AppColors.textSecondary),
          );
        }

        return CustomScrollView(
          slivers: [
            _buildHeader(lesson),
            _buildContent(lesson),
          ],
        );
      }),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(LessonModel lesson) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(lesson.title),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              if (lesson.imageUrl != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.network(
                      lesson.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Positioned(
                bottom: 60,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    _buildInfoChip(
                      Icons.timer,
                      '${lesson.durationMinutes} min',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.school,
                      '${lesson.totalExercises} exercises',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LessonModel lesson) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Progress
          _buildProgressSection(lesson),
          const SizedBox(height: 24),

          // Description
          AppText('About this lesson', variant: AppTextVariant.h3),
          const SizedBox(height: 8),
          AppText(
            lesson.description,
            variant: AppTextVariant.bodyMedium,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),

          // Sections
          if (lesson.sections != null && lesson.sections!.isNotEmpty) ...[
            AppText('Sections', variant: AppTextVariant.h3),
            const SizedBox(height: 12),
            ...lesson.sections!.map((section) => _buildSectionItem(section, lesson.id)),
          ],
        ]),
      ),
    );
  }

  Widget _buildProgressSection(LessonModel lesson) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText('Progress', variant: AppTextVariant.label),
              AppText(
                '${(lesson.progress * 100).round()}%',
                variant: AppTextVariant.h3,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: lesson.progress,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          AppText(
            '${lesson.completedExercises} of ${lesson.totalExercises} completed',
            variant: AppTextVariant.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionItem(LessonSection section, String lessonId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: section.isCompleted
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            section.isCompleted
                ? Icons.check_circle
                : _getSectionIcon(section.type),
            color: section.isCompleted ? AppColors.success : AppColors.primary,
          ),
        ),
        title: AppText(section.title, variant: AppTextVariant.bodyLarge),
        subtitle: AppText(
          section.type.capitalize!,
          variant: AppTextVariant.caption,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to section detail
          // controller.completeSection(lessonId, section.id);
        },
      ),
    );
  }

  IconData _getSectionIcon(String type) {
    switch (type) {
      case 'audio':
        return Icons.headphones;
      case 'exercise':
        return Icons.edit;
      default:
        return Icons.article;
    }
  }

  Widget _buildBottomBar() {
    return Obx(() {
      final lesson = controller.selectedLesson.value;
      if (lesson == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: AppButton(
            text: lesson.status == LessonStatus.notStarted
                ? 'start_lesson'.tr
                : 'continue_lesson'.tr,
            onPressed: () {
              // Start/continue lesson
            },
          ),
        ),
      );
    });
  }
}
```

### Step 6: Create lesson_card.dart

```dart
// lib/features/lessons/widgets/lesson_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/lesson_model.dart';

class LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Image
            if (lesson.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: lesson.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 120,
                    color: AppColors.divider,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 120,
                    color: AppColors.divider,
                    child: const Icon(Icons.image, color: AppColors.textHint),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusBadge(),
                      const SizedBox(width: 8),
                      AppText(
                        lesson.category,
                        variant: AppTextVariant.caption,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    lesson.title,
                    variant: AppTextVariant.h3,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    lesson.description,
                    variant: AppTextVariant.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        '${lesson.durationMinutes} min',
                        variant: AppTextVariant.caption,
                      ),
                      const Spacer(),
                      if (lesson.progress > 0) ...[
                        SizedBox(
                          width: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: lesson.progress,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation(
                                lesson.status == LessonStatus.completed
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppText(
                          '${(lesson.progress * 100).round()}%',
                          variant: AppTextVariant.caption,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (lesson.status) {
      case LessonStatus.completed:
        color = AppColors.success;
        text = 'Completed';
        break;
      case LessonStatus.inProgress:
        color = AppColors.warning;
        text = 'In Progress';
        break;
      default:
        color = AppColors.info;
        text = 'New';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

## Todo List

- [ ] Create lesson_model.dart with LessonSection
- [ ] Create lesson_binding.dart
- [ ] Create lesson_controller.dart with caching
- [ ] Create lesson_list_screen.dart with filters
- [ ] Create lesson_detail_screen.dart with sections
- [ ] Create lesson_card.dart widget
- [ ] Update app_pages.dart
- [ ] Test offline access to cached lessons
- [ ] Test LRU eviction (fill 100MB)

## Success Criteria

- Lesson list shows with progress indicators
- Filter chips work correctly
- Lesson detail loads from cache when offline
- LRU eviction works at 100MB limit
- Smooth navigation transitions
- Progress updates reflect in UI

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Cache corruption | Medium | JSON parse in try-catch, fallback to API |
| Large lesson content | Medium | Stream content, show loading |
| Stale cached data | Low | Background refresh, pull-to-refresh |

## Security Considerations

- No sensitive data in lesson content
- Cache stored locally only

## Next Steps

After completion, proceed to [Phase 10: Profile & Settings](./phase-10-profile-settings.md).
