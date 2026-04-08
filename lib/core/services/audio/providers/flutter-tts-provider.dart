import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../contracts/tts-provider-contract.dart';
import '../models/tts-event.dart';

class FlutterTtsProvider implements TtsProviderContract {
  final FlutterTts _flutterTts = FlutterTts();
  final _eventController = StreamController<TtsEvent>.broadcast();
  bool _isSpeaking = false;

  @override
  Future<void> initialize() async {
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _eventController.add(const TtsEvent(type: TtsEventType.start));
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _eventController.add(const TtsEvent(type: TtsEventType.complete));
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      _eventController.add(TtsEvent(
        type: TtsEventType.error,
        errorMessage: msg.toString(),
      ));
    });

    _flutterTts.setProgressHandler((text, start, end, word) {
      _eventController.add(TtsEvent(
        type: TtsEventType.progress,
        text: text,
        startOffset: start,
        endOffset: end,
      ));
    });

    _flutterTts.setPauseHandler(() {
      _eventController.add(const TtsEvent(type: TtsEventType.pause));
    });

    _flutterTts.setContinueHandler(() {
      _eventController.add(const TtsEvent(type: TtsEventType.resume));
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      _eventController.add(const TtsEvent(type: TtsEventType.cancel));
    });
  }

  @override
  Future<void> speak(String text, {String? language}) async {
    try {
      if (language != null) await _flutterTts.setLanguage(language);
      await _flutterTts.speak(text);
    } catch (e) {
      if (kDebugMode) print('TTS speak error: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      if (kDebugMode) print('TTS stop error: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      if (kDebugMode) print('TTS pause error: $e');
    }
  }

  @override
  Future<void> resume() async {
    // flutter_tts has no resume — no-op
  }

  @override
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  @override
  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<TtsEvent> get eventStream => _eventController.stream;

  @override
  void dispose() {
    _flutterTts.stop();
    _eventController.close();
  }
}
