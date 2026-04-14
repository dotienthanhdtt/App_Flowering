import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'contracts/audio-recorder-provider-contract.dart';
import 'contracts/stt-provider-contract.dart';
import 'models/stt-result.dart';
import 'models/voice-input-result.dart';
import 'tts-service.dart';

class VoiceInputService extends GetxService {
  late final SttProviderContract _sttProvider;
  late final AudioRecorderProviderContract _recorderProvider;
  late final TtsService _ttsService;

  final isListening = false.obs;
  final partialText = ''.obs;
  final amplitude = 0.0.obs;
  final sttAvailable = false.obs;
  final listeningDuration = Duration.zero.obs;

  Timer? _timeoutTimer;
  Timer? _durationTimer;
  StreamSubscription<SttResult>? _sttSub;
  StreamSubscription<double>? _amplitudeSub;

  /// STT is only initialized on first mic tap — deferring permission prompts
  /// from app startup to the moment the user actually requests voice input.
  bool _sttInitialized = false;

  static const _iosSttTimeout = Duration(seconds: 55);

  bool get _canRecordDuringSTT => Platform.isIOS;

  Future<VoiceInputService> init() async {
    _sttProvider = Get.find<SttProviderContract>();
    _recorderProvider = Get.find<AudioRecorderProviderContract>();
    _ttsService = Get.find<TtsService>();

    // Optimistically show mic button — real availability is confirmed on first
    // tap via [_ensureSttInitialized]. This avoids prompting for microphone
    // permission at app launch.
    sttAvailable.value = true;

    return this;
  }

  /// Initialize STT lazily. This triggers the OS microphone / speech
  /// recognition permission prompt on iOS, so it must only be called in
  /// response to an explicit user action (e.g. tapping the mic icon).
  Future<bool> _ensureSttInitialized() async {
    if (_sttInitialized) return sttAvailable.value;
    _sttInitialized = true;
    final available = await _sttProvider.initialize();
    sttAvailable.value = available;
    return available;
  }

  Future<void> startVoiceInput({String? language}) async {
    if (isListening.value) return;

    // Lazy STT init — triggers permission prompt on first tap only.
    final ready = await _ensureSttInitialized();
    if (!ready) return;

    // Stop TTS first to avoid audio session conflict
    await _ttsService.stopForVoiceInput();

    partialText.value = '';
    amplitude.value = 0.0;
    listeningDuration.value = Duration.zero;

    await _sttProvider.startListening(language: language);
    isListening.value = true;

    _sttSub = _sttProvider.resultStream.listen((result) {
      partialText.value = result.text;
    });

    // iOS: record audio in parallel for backend transcription + amplitude
    if (_canRecordDuringSTT) {
      await _recorderProvider.startRecording();
      _amplitudeSub = _recorderProvider.amplitudeStream.listen((amp) {
        amplitude.value = amp;
      });
    }

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      listeningDuration.value += const Duration(seconds: 1);
    });

    // 55s safety timeout (Apple hard limit is 60s)
    _timeoutTimer = Timer(_iosSttTimeout, () => stopVoiceInput());
  }

  Future<VoiceInputResult> stopVoiceInput() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _sttSub?.cancel();
    _sttSub = null;
    _amplitudeSub?.cancel();
    _amplitudeSub = null;

    final text = partialText.value;
    await _sttProvider.stopListening();

    String? audioPath;
    if (_canRecordDuringSTT) {
      audioPath = await _recorderProvider.stopRecording();
    }

    isListening.value = false;
    amplitude.value = 0.0;

    return VoiceInputResult(
      transcribedText: text,
      audioFilePath: audioPath,
      isPartial: false,
    );
  }

  Future<void> cancelVoiceInput() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _sttSub?.cancel();
    _sttSub = null;
    _amplitudeSub?.cancel();
    _amplitudeSub = null;

    await _sttProvider.cancel();
    if (_canRecordDuringSTT) {
      await _recorderProvider.cancelRecording();
    }

    isListening.value = false;
    partialText.value = '';
    amplitude.value = 0.0;
    listeningDuration.value = Duration.zero;
  }

  @override
  void onClose() {
    _timeoutTimer?.cancel();
    _durationTimer?.cancel();
    _sttSub?.cancel();
    _amplitudeSub?.cancel();
    _sttProvider.dispose();
    _recorderProvider.dispose();
    super.onClose();
  }
}
