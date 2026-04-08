import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../storage_service.dart';
import 'contracts/tts-provider-contract.dart';
import 'models/tts-event.dart';

class TtsService extends GetxService {
  late final TtsProviderContract _provider;
  late final StorageService _storageService;

  final isSpeaking = false.obs;
  final currentText = ''.obs;

  final Queue<String> _speakQueue = Queue();
  bool _isProcessingQueue = false;
  StreamSubscription<TtsEvent>? _eventSub;

  static const _autoPlayKey = 'tts_auto_play';
  static const _rateKey = 'tts_rate';
  static const _pitchKey = 'tts_pitch';

  Future<TtsService> init() async {
    _provider = Get.find<TtsProviderContract>();
    _storageService = Get.find<StorageService>();

    await _provider.initialize();

    final rate = _storageService.getPreference<double>(_rateKey) ?? 0.5;
    final pitch = _storageService.getPreference<double>(_pitchKey) ?? 1.0;
    await _provider.setRate(rate);
    await _provider.setPitch(pitch);

    _eventSub = _provider.eventStream.listen(_onProviderEvent);

    return this;
  }

  void _onProviderEvent(TtsEvent event) {
    switch (event.type) {
      case TtsEventType.start:
        isSpeaking.value = true;
      case TtsEventType.complete:
      case TtsEventType.cancel:
        isSpeaking.value = false;
        currentText.value = '';
        _isProcessingQueue = false;
        _processQueue();
      case TtsEventType.error:
        if (kDebugMode) print('TTS error: ${event.errorMessage}');
        isSpeaking.value = false;
        currentText.value = '';
        _isProcessingQueue = false;
        _processQueue();
      default:
        break;
    }
  }

  Future<void> speak(String text, {String? language}) async {
    if (_speakQueue.length >= 10) return;
    _speakQueue.add(text);
    if (!_isProcessingQueue) _processQueue();
  }

  void _processQueue() {
    if (_speakQueue.isEmpty || _isProcessingQueue) return;
    _isProcessingQueue = true;
    final text = _speakQueue.removeFirst();
    currentText.value = text;
    _provider.speak(text);
  }

  Future<void> stopForVoiceInput() async {
    _speakQueue.clear();
    _isProcessingQueue = false;
    await _provider.stop();
    isSpeaking.value = false;
    currentText.value = '';
  }

  Future<void> stop() async => stopForVoiceInput();

  Future<void> pause() async => _provider.pause();

  Future<void> resume() async => _provider.resume();

  bool get autoPlayEnabled =>
      _storageService.getPreference<bool>(_autoPlayKey) ?? false;

  Future<void> setAutoPlay(bool value) async =>
      _storageService.setPreference(_autoPlayKey, value);

  Future<void> setRate(double rate) async {
    await _storageService.setPreference(_rateKey, rate);
    await _provider.setRate(rate);
  }

  Future<void> setPitch(double pitch) async {
    await _storageService.setPreference(_pitchKey, pitch);
    await _provider.setPitch(pitch);
  }

  @override
  void onClose() {
    _eventSub?.cancel();
    _speakQueue.clear();
    _provider.dispose();
    super.onClose();
  }
}
