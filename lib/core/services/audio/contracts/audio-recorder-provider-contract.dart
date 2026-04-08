abstract class AudioRecorderProviderContract {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<void> startRecording();
  Future<String?> stopRecording();
  Future<void> cancelRecording();
  bool get isRecording;
  Stream<double> get amplitudeStream;
  void dispose();
}
