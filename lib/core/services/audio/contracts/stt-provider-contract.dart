import '../models/stt-result.dart';

abstract class SttProviderContract {
  Future<bool> initialize();
  Future<void> startListening({String? language});
  Future<void> stopListening();
  Future<void> cancel();
  bool get isListening;
  bool get isAvailable;
  Stream<SttResult> get resultStream;
  Future<List<String>> getAvailableLanguages();
  void dispose();
}
