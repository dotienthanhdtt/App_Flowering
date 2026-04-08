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

  static const _iosSttTimeout = Duration(seconds: 55);

  bool get _canRecordDuringSTT => Platform.isIOS;

  Future<VoiceInputService> init() async {
    _sttProvider = Get.find<SttProviderContract>();
    _recorderProvider = Get.find<AudioRecorderProviderContract>();
    _ttsService = Get.find<TtsService>();

    final available = await _sttProvider.initialize();
    sttAvailable.value = available;

    return this;
  }

  Future<void> startVoiceInput({String? language}) async {
    if (isListening.value) return;

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
