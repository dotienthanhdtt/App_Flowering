import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' show SpeechListenOptions;
import '../contracts/stt-provider-contract.dart';
import '../models/stt-result.dart';

class SpeechToTextProvider implements SttProviderContract {
  final SpeechToText _speechToText = SpeechToText();
  final _resultController = StreamController<SttResult>.broadcast();
  bool _isAvailable = false;

  @override
  Future<bool> initialize() async {
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (error) {
          if (kDebugMode) print('STT error: ${error.errorMsg}');
        },
        onStatus: (status) {
          if (kDebugMode) print('STT status: $status');
        },
      );
    } catch (e) {
      if (kDebugMode) print('STT init error: $e');
      _isAvailable = false;
    }
    return _isAvailable;
  }

  @override
  Future<void> startListening({String? language}) async {
    if (!_isAvailable) return;
    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _resultController.add(SttResult(
            text: result.recognizedWords,
            isFinal: result.finalResult,
            confidence: result.confidence,
          ));
        },
        localeId: language,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('STT startListening error: $e');
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (e) {
      if (kDebugMode) print('STT stopListening error: $e');
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _speechToText.cancel();
    } catch (e) {
      if (kDebugMode) print('STT cancel error: $e');
    }
  }

  @override
  bool get isListening => _speechToText.isListening;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Stream<SttResult> get resultStream => _resultController.stream;

  @override
  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speechToText.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _resultController.close();
  }
}
