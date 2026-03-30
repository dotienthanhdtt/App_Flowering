import 'package:get/get.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../network/api_exceptions.dart';
import '../../shared/models/word-translation-model.dart';
import '../../shared/models/sentence-translation-model.dart';

/// Global translation service with in-memory caching.
/// Registered as permanent GetxService for reuse across chat contexts.
class TranslationService extends GetxService {
  final ApiClient _apiClient = Get.find();

  final Map<String, WordTranslationModel> _wordCache = {};
  final Map<String, SentenceTranslationModel> _sentenceCache = {};

  Future<WordTranslationModel> translateWord(
    String word, {
    String sourceLang = 'en',
    String targetLang = 'vi',
    String? conversationId,
  }) async {
    final key = word.toLowerCase().trim();
    if (_wordCache.containsKey(key)) return _wordCache[key]!;

    final response = await _apiClient.post<WordTranslationModel>(
      ApiEndpoints.translate,
      data: {
        'type': 'word',
        'text': word,
        'source_lang': sourceLang,
        'target_lang': targetLang,
        if (conversationId != null) 'conversation_id': conversationId,
      },
      fromJson: (data) =>
          WordTranslationModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.isSuccess && response.data != null) {
      _wordCache[key] = response.data!;
      return response.data!;
    }

    throw ApiErrorException(
      message: response.message,
      userMessage: response.message,
    );
  }

  Future<SentenceTranslationModel> translateSentence(
    String messageId, {
    String sourceLang = 'en',
    String targetLang = 'vi',
    String? conversationId,
  }) async {
    if (_sentenceCache.containsKey(messageId)) {
      return _sentenceCache[messageId]!;
    }

    final response = await _apiClient.post<SentenceTranslationModel>(
      ApiEndpoints.translate,
      data: {
        'type': 'sentence',
        'message_id': messageId,
        'source_lang': sourceLang,
        'target_lang': targetLang,
        if (conversationId != null) 'conversation_id': conversationId,
      },
      fromJson: (data) =>
          SentenceTranslationModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.isSuccess && response.data != null) {
      _sentenceCache[messageId] = response.data!;
      return response.data!;
    }

    throw ApiErrorException(
      message: response.message,
      userMessage: response.message,
    );
  }
}
