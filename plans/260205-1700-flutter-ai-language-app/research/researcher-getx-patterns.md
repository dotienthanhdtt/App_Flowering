# GetX State Management Best Practices (2025-2026)

## 1. Controller Lifecycle & Memory Leak Prevention

### Proper Controller Disposal
```dart
class LanguageController extends GetxController {
  final StreamController _streamController = StreamController();
  final TextEditingController textController = TextEditingController();
  late Worker _everWorker;

  @override
  void onInit() {
    super.onInit();
    _everWorker = ever(selectedLanguage, _onLanguageChange);
  }

  @override
  void onClose() {
    // Critical: Dispose all resources
    _streamController.close();
    textController.dispose();
    _everWorker.dispose();
    super.onClose();
  }
}
```

### Dependency Injection Strategies
```dart
// Lazy loading (recommended for most cases)
Get.lazyPut<AuthController>(() => AuthController());

// Permanent (use sparingly - survives route changes)
Get.put<SettingsController>(SettingsController(), permanent: true);

// Tagged instances (multiple controllers of same type)
Get.put(LessonController(), tag: 'lesson_1');
Get.find<LessonController>(tag: 'lesson_1');

// SmartManagement modes
GetMaterialApp(
  smartManagement: SmartManagement.full, // Auto-dispose when not in use
);
```

## 2. Bindings Patterns for Feature-First Architecture

### Feature Module Structure
```
lib/
├── features/
│   ├── lessons/
│   │   ├── bindings/
│   │   │   └── lesson_binding.dart
│   │   ├── controllers/
│   │   │   └── lesson_controller.dart
│   │   └── views/
│   │       └── lesson_view.dart
```

### Binding Implementation
```dart
// features/lessons/bindings/lesson_binding.dart
class LessonBinding extends Bindings {
  @override
  void dependencies() {
    // Lazy injection
    Get.lazyPut<LessonRepository>(() => LessonRepositoryImpl());
    Get.lazyPut<LessonController>(
      () => LessonController(repository: Get.find()),
    );

    // Or fenix mode (recreates on demand)
    Get.lazyPut<VocabularyController>(
      () => VocabularyController(),
      fenix: true,
    );
  }
}

// Route configuration
GetPage(
  name: '/lesson',
  page: () => LessonView(),
  binding: LessonBinding(),
),
```

### Bindings Builder Pattern
```dart
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Global dependencies
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<StorageService>(StorageService(), permanent: true);
  }
}

// In main.dart
GetMaterialApp(
  initialBinding: AppBindings(),
  getPages: AppPages.routes,
);
```

## 3. Navigation with Custom Transitions

### Right-to-Left Animation
```dart
// Custom transition
Get.to(
  () => LessonDetailPage(),
  transition: Transition.rightToLeft,
  duration: Duration(milliseconds: 300),
);

// With named routes
GetPage(
  name: '/lesson-detail',
  page: () => LessonDetailPage(),
  transition: Transition.rightToLeft,
  transitionDuration: Duration(milliseconds: 300),
);

// Custom transition curve
Get.to(
  () => ProfilePage(),
  transition: Transition.rightToLeft,
  curve: Curves.easeInOut,
);
```

### Custom Transition Builder
```dart
GetPage(
  name: '/custom',
  page: () => CustomPage(),
  customTransition: CustomRightToLeftTransition(),
);

class CustomRightToLeftTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve ?? Curves.easeInOut,
      )),
      child: child,
    );
  }
}
```

## 4. Dependency Injection Best Practices

### Repository Pattern with GetX
```dart
// Abstract repository
abstract class ILessonRepository {
  Future<List<Lesson>> getLessons();
}

// Implementation
class LessonRepositoryImpl implements ILessonRepository {
  final ApiService _api = Get.find();

  @override
  Future<List<Lesson>> getLessons() async {
    return await _api.get('/lessons');
  }
}

// Binding
class LessonBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ILessonRepository>(() => LessonRepositoryImpl());
    Get.lazyPut(() => LessonController(Get.find<ILessonRepository>()));
  }
}

// Controller
class LessonController extends GetxController {
  final ILessonRepository repository;

  LessonController(this.repository);

  Future<void> fetchLessons() async {
    final lessons = await repository.getLessons();
  }
}
```

## 5. Reactive State (.obs) vs Simple State (GetBuilder)

### When to Use Each

**Use .obs + Obx for:**
- Complex reactive dependencies
- Automatic UI updates
- Real-time data streams
- Developer convenience

**Use GetBuilder for:**
- Maximum performance (10-20% faster)
- Simple state updates
- Explicit control over rebuilds
- Large lists with frequent updates

### Performance Comparison Examples

```dart
// Reactive approach (Obx) - Better for complex dependencies
class CounterController extends GetxController {
  final count = 0.obs;
  final isLoading = false.obs;

  void increment() => count.value++;
}

// View
Obx(() => Text('Count: ${controller.count}'))

// Simple approach (GetBuilder) - Better performance
class CounterController extends GetxController {
  int count = 0;
  bool isLoading = false;

  void increment() {
    count++;
    update(); // Manual rebuild trigger
  }

  void incrementWithId() {
    count++;
    update(['counter']); // Rebuild only specific ID
  }
}

// View
GetBuilder<CounterController>(
  id: 'counter',
  builder: (controller) => Text('Count: ${controller.count}'),
)
```

### Hybrid Approach (Recommended)
```dart
class LessonController extends GetxController {
  // Reactive for UI-bound values
  final lessons = <Lesson>[].obs;
  final isLoading = false.obs;

  // Simple for internal state
  int _currentPage = 0;
  String _cacheKey = '';

  // Use GetBuilder for performance-critical lists
  void updateLessonsList(List<Lesson> newLessons) {
    lessons.value = newLessons;
    update(['lessons-list']); // Explicit rebuild
  }
}

// View combines both
Column(
  children: [
    // Reactive for simple bindings
    Obx(() => controller.isLoading
      ? CircularProgressIndicator()
      : SizedBox()),

    // GetBuilder for performance-critical lists
    GetBuilder<LessonController>(
      id: 'lessons-list',
      builder: (c) => ListView.builder(
        itemCount: c.lessons.length,
        itemBuilder: (ctx, i) => LessonTile(c.lessons[i]),
      ),
    ),
  ],
)
```

## Key Recommendations

1. **Memory Management**: Always implement `onClose()` and dispose resources
2. **Bindings**: Use bindings for feature modules, avoid manual `Get.put()` in UI
3. **Navigation**: Prefer named routes with bindings over direct navigation
4. **DI**: Lazy injection for most cases, permanent only for global services
5. **State**: Use Obx for convenience, GetBuilder for performance-critical sections
6. **Workers**: Dispose workers (`ever`, `once`, `debounce`) in `onClose()`
7. **SmartManagement**: Use `SmartManagement.full` for automatic cleanup

## Unresolved Questions

- GetX vs Riverpod/Bloc for large-scale apps (team preference)
- Testing strategy for GetX controllers with complex dependencies
- Performance benchmarks for .obs vs GetBuilder in production apps with 1000+ widgets
