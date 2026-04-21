import 'package:get/get.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../network/api_exceptions.dart';
import '../../shared/models/word-translation-model.dart';
import '../../shared/models/sentence-translation-model.dart';

/// Global translation service. Every call hits the API — no memoization.
/// Registered as permanent GetxService for reuse across chat contexts.
class TranslationService extends GetxService {
  final ApiClient _apiClient = Get.find();

  Future<WordTranslationModel> translateWord(
    String word, {
    String sourceLang = 'en',
    String targetLang = 'vi',
    String? conversationId,
  }) async {
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
      return response.data!;
    }

    throw ApiErrorException(
      message: response.message,
      userMessage: response.message,
    );
  }

  /// Translate a sentence by text content directly (no server message_id needed).
  /// Used by scenario chat where messages are created locally without server IDs.
  Future<SentenceTranslationModel> translateContent(
    String text, {
    String sourceLang = 'en',
    String targetLang = 'vi',
    String? conversationId,
  }) async {
    final response = await _apiClient.post<SentenceTranslationModel>(
      ApiEndpoints.translate,
      data: {
        'type': 'SENTENCE',
        'text': text,
        'source_lang': sourceLang,
        'target_lang': targetLang,
        if (conversationId != null) 'conversation_id': conversationId,
      },
      fromJson: (data) =>
          SentenceTranslationModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    }

    throw ApiErrorException(
      message: response.message,
      userMessage: response.message,
    );
  }
}
