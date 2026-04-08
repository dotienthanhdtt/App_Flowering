import '../models/tts-event.dart';

abstract class TtsProviderContract {
  Future<void> initialize();
  Future<void> speak(String text, {String? language});
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> setLanguage(String language);
  Future<void> setRate(double rate);
  Future<void> setPitch(double pitch);
  bool get isSpeaking;
  Stream<TtsEvent> get eventStream;
  void dispose();
}
