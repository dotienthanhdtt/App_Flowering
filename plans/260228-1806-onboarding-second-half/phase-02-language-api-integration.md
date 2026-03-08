# Phase 02 — Language API Integration (Screens 05-06)

## Overview
- **Priority:** P1
- **Status:** Complete
- **Effort:** 2h
- **Blocked by:** Phase 01

Replace hardcoded language lists with real `GET /languages` API data. Add loading states and offline fallback.

## Key Insights

- Current: static lists in `OnboardingLanguage` with 7 native + 6 learning languages
- API: `GET /languages` returns `{ code: 1, data: [...] }` with UUID ids, flagUrl, enabled status
- Languages rarely change → cache 24h in StorageService
- Must preserve existing UX: list cards for native, 2-col grid for learning

## Requirements

### Functional
- Fetch languages from `GET /languages` on screen load
- Show loading skeleton while fetching
- Cache response in StorageService for 24h
- Use cached/fallback data when offline
- Store selected language IDs (not just codes) for `/onboarding/start`

### Non-functional
- < 2s load time for language screen
- Graceful degradation when API unavailable

## Related Code Files

### Modify
- `lib/features/onboarding/controllers/onboarding_controller.dart` — add language fetching + selection by ID
- `lib/features/onboarding/views/native_language_screen.dart` — add loading state
- `lib/features/onboarding/views/learning_language_screen.dart` — add loading state
- `lib/features/onboarding/widgets/language_card.dart` — support flagUrl (network image) + emoji fallback

### Create
- `lib/features/onboarding/services/onboarding_language_service.dart` — API + cache logic

## Architecture

```
NativeLanguageScreen / LearningLanguageScreen
  → OnboardingController
    → OnboardingLanguageService
      → ApiClient.get('/languages')
      → StorageService (cache)
      → Fallback static list
```

## Implementation Steps

### 1. Create OnboardingLanguageService

```dart
class OnboardingLanguageService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  static const _cacheKey = 'languages_cache';
  static const _cacheTimestampKey = 'languages_cache_timestamp';
  static const _cacheDuration = Duration(hours: 24);

  Future<List<OnboardingLanguage>> getLanguages() async {
    // 1. Check cache validity
    // 2. If valid cache → return cached
    // 3. If no cache or expired → fetch from API
    // 4. On API success → cache + return
    // 5. On API failure → return cached (even if expired) or fallback
  }
}
```

### 2. Update OnboardingController

Add to controller:
```dart
final languages = <OnboardingLanguage>[].obs;
final isLoadingLanguages = true.obs;
String? selectedNativeLanguageId;  // UUID for API
String? selectedLearningLanguageId;

Future<void> loadLanguages() async {
  isLoadingLanguages.value = true;
  try {
    languages.value = await _languageService.getLanguages();
  } finally {
    isLoadingLanguages.value = false;
  }
}

List<OnboardingLanguage> get nativeLanguages =>
    languages.where((l) => l.type == 'native' || l.isNative).toList();
List<OnboardingLanguage> get learningLanguages =>
    languages.where((l) => l.type == 'learning' || l.isLearning).toList();
```

### 3. Update Language Screens

Both screens need:
- `Obx` wrapping the language list
- Loading skeleton when `isLoadingLanguages.value == true`
- Error state with retry button when list is empty + not loading

### 4. Update LanguageCard Widget

Support `flagUrl` from API:
- If `flagUrl` non-null → `CachedNetworkImage` or `Image.network` with emoji fallback
- If `flagUrl` null → use emoji flag as before

### 5. Register OnboardingLanguageService

In `onboarding_binding.dart`:
```dart
Get.lazyPut<OnboardingLanguageService>(() => OnboardingLanguageService(
  Get.find<ApiClient>(),
  Get.find<StorageService>(),
));
```

## Todo List

- [x] Create OnboardingLanguageService with API + cache logic
- [x] Update OnboardingController with language fetching
- [x] Update NativeLanguageScreen with loading/error states
- [x] Update LearningLanguageScreen with loading/error states
- [x] Update LanguageCard to support network flag images
- [x] Register service in OnboardingBinding
- [x] Test offline fallback behavior
- [x] Run `flutter analyze`

## Success Criteria

- Languages load from API on fresh install
- Cached data used on subsequent visits within 24h
- Offline mode shows fallback/cached languages
- Selected language IDs available for `/onboarding/start`

## Risk Assessment

- **API response format mismatch** → validate with backend team, use flexible fromJson
- **Flag image loading latency** → use placeholder/emoji while loading
- **Breaking existing screens** → test 05-06 thoroughly after changes

## Next Steps

→ Phase 03: AI Chat Real API
