# Phase 01 — Model + Service + Endpoint

## Context Links
- API contract: `docs/api_docs/translate-api.md`
- Existing models: `lib/shared/models/`
- Existing services: `lib/core/services/`
- Endpoints: `lib/core/constants/api_endpoints.dart`
- DI bindings: `lib/core/services/global-dependency-injection-bindings.dart`

## Overview
- **Priority:** High (blocks Phase 2 and 3)
- **Status:** Pending
- **Description:** Create the data model for word translation responses, build `TranslationService` with API calls + in-memory caching, add endpoint constant, register service in DI.

## Key Insights
- `ChatMessage.id` is client-generated in onboarding (`ai_xxx`). Sentence translate needs a real backend `messageId` — add optional `backendMessageId` field.
- Word translation returns `vocabularyId` (word saved to user's vocab on backend).
- Sentence translation caches by `messageId`; word translation caches by lowercase word string.

## Requirements

### Functional
- `WordTranslationModel` with fields: `original`, `translation`, `partOfSpeech`, `pronunciation`, `definition`, `examples` (List<String>), `vocabularyId`
- `SentenceTranslationModel` with fields: `messageId`, `original`, `translation`
- `TranslationService.translateWord(String word)` — calls API, caches result, returns model
- `TranslationService.translateSentence(String messageId)` — calls API, caches result, returns model
- In-memory `Map` caches (cleared on service dispose)

### Non-Functional
- Cache hit returns instantly without API call
- Error states propagated via return type or thrown exception (follow existing `ApiException` pattern)

## Architecture

```
Controller → TranslationService → ApiClient → POST /ai/translate
                ↓ cache hit
            WordTranslationModel / SentenceTranslationModel
```

## Related Code Files

### Create
| File | Purpose |
|------|---------|
| `lib/shared/models/word-translation-model.dart` | Word translate response model |
| `lib/shared/models/sentence-translation-model.dart` | Sentence translate response model |
| `lib/core/services/translation-service.dart` | API calls + caching singleton |

### Edit
| File | Change |
|------|--------|
| `lib/core/constants/api_endpoints.dart` | Add `translate` endpoint constant |
| `lib/core/services/global-dependency-injection-bindings.dart` | Register `TranslationService` |
| `lib/features/chat/models/chat_message_model.dart` | Add optional `backendMessageId` field |

## Implementation Steps

### 1. Add API endpoint constant
In `api_endpoints.dart`, add under `// Chat` section:
```dart
static const String translate = '/ai/translate'; // POST
```

### 2. Create WordTranslationModel
File: `lib/shared/models/word-translation-model.dart`
```dart
class WordTranslationModel {
  final String original;
  final String translation;
  final String partOfSpeech;
  final String pronunciation;
  final String definition;
  final List<String> examples;
  final String vocabularyId;

  WordTranslationModel({required all fields});

  factory WordTranslationModel.fromJson(Map<String, dynamic> json) {
    // Parse examples as List<String> from json['examples']
  }
}
```

### 3. Create SentenceTranslationModel
File: `lib/shared/models/sentence-translation-model.dart`
```dart
class SentenceTranslationModel {
  final String messageId;
  final String original;
  final String translation;

  factory SentenceTranslationModel.fromJson(Map<String, dynamic> json);
}
```

### 4. Update ChatMessage model
Add optional `backendMessageId` field:
```dart
final String? backendMessageId; // Real server message ID for sentence translation
```
Update constructor. No breaking changes — field is nullable with no default needed beyond null.

### 5. Create TranslationService
File: `lib/core/services/translation-service.dart`

```dart
class TranslationService extends GetxService {
  final ApiClient _apiClient = Get.find();

  final Map<String, WordTranslationModel> _wordCache = {};
  final Map<String, SentenceTranslationModel> _sentenceCache = {};

  Future<WordTranslationModel> translateWord(String word) async {
    final key = word.toLowerCase().trim();
    if (_wordCache.containsKey(key)) return _wordCache[key]!;

    final response = await _apiClient.post<WordTranslationModel>(
      ApiEndpoints.translate,
      data: {'type': 'word', 'text': word},
      fromJson: (data) => WordTranslationModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.isSuccess && response.data != null) {
      _wordCache[key] = response.data!;
      return response.data!;
    }
    throw ApiException(response.message);
  }

  Future<SentenceTranslationModel> translateSentence(String messageId) async {
    if (_sentenceCache.containsKey(messageId)) return _sentenceCache[messageId]!;

    final response = await _apiClient.post<SentenceTranslationModel>(
      ApiEndpoints.translate,
      data: {'type': 'sentence', 'messageId': messageId},
      fromJson: (data) => SentenceTranslationModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.isSuccess && response.data != null) {
      _sentenceCache[messageId] = response.data!;
      return response.data!;
    }
    throw ApiException(response.message);
  }
}
```

### 6. Register in DI
In `global-dependency-injection-bindings.dart`, add:
```dart
Get.put(TranslationService(), permanent: true);
```

## Todo List
- [ ] Add `translate` endpoint to `api_endpoints.dart`
- [ ] Create `WordTranslationModel`
- [ ] Create `SentenceTranslationModel`
- [ ] Add `backendMessageId` to `ChatMessage`
- [ ] Create `TranslationService` with caching
- [ ] Register `TranslationService` in DI bindings
- [ ] Verify compilation with `flutter analyze`

## Success Criteria
- Models parse sample JSON correctly
- Service compiles, is injectable via `Get.find<TranslationService>()`
- Cache returns same instance on second call without API hit
- `flutter analyze` passes with no errors

## Risk Assessment
| Risk | Mitigation |
|------|------------|
| API contract changes | Models are simple DTOs, easy to update |
| `backendMessageId` never populated in onboarding | Sentence translate checks for null and skips |

## Next Steps
- Phase 02 uses `WordTranslationModel` to populate the bottom sheet UI
- Phase 03 wires the service into `AiChatController` and bubble
