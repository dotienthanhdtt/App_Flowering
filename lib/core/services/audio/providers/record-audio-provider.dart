import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../contracts/audio-recorder-provider-contract.dart';

class RecordAudioProvider implements AudioRecorderProviderContract {
  final AudioRecorder _recorder = AudioRecorder();
  final _amplitudeController = StreamController<double>.broadcast();
  bool _isRecording = false;
  String? _currentPath;
  Timer? _amplitudeTimer;

  /// Sweep stale `voice_input_*.m4a` files in the temp dir. Should be called
  /// once on app start / service init — failed-upload recordings that the
  /// recorder process didn't get to clean up accumulate here over time.
  /// Safe threshold: files older than 1 hour are considered orphaned.
  static Future<void> cleanupStaleRecordings({
    Duration maxAge = const Duration(hours: 1),
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      if (!await dir.exists()) return;
      final now = DateTime.now();
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!name.startsWith('voice_input_') || !name.endsWith('.m4a')) continue;
        try {
          final stat = await entity.stat();
          if (now.difference(stat.modified) > maxAge) {
            await entity.delete();
          }
        } catch (_) {
          // ignore — file may have been deleted underneath us
        }
      }
    } catch (e) {
      if (kDebugMode) print('cleanupStaleRecordings error: $e');
    }
  }

  @override
  Future<bool> hasPermission() async => await _recorder.hasPermission();

  @override
  Future<bool> requestPermission() async => await _recorder.hasPermission();

  @override
  Future<void> startRecording() async {
    if (_isRecording) return;
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentPath = '${dir.path}/voice_input_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentPath!,
      );
      _isRecording = true;

      _amplitudeTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) async {
          try {
            final amp = await _recorder.getAmplitude();
            final db = amp.current;
            _amplitudeController.add(((db + 60) / 60).clamp(0.0, 1.0));
          } catch (_) {
            _amplitudeController.add(0.0);
          }
        },
      );
    } catch (e) {
      if (kDebugMode) print('RecordAudioProvider startRecording error: $e');
      _isRecording = false;
    }
  }

  @override
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      _amplitudeTimer?.cancel();
      _amplitudeTimer = null;
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      if (kDebugMode) print('RecordAudioProvider stopRecording error: $e');
      _isRecording = false;
      return null;
    }
  }

  @override
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    try {
      _amplitudeTimer?.cancel();
      _amplitudeTimer = null;
      await _recorder.stop();
      _isRecording = false;
      if (_currentPath != null) {
        final file = File(_currentPath!);
        if (await file.exists()) await file.delete();
        _currentPath = null;
      }
    } catch (e) {
      if (kDebugMode) print('RecordAudioProvider cancelRecording error: $e');
      _isRecording = false;
    }
  }

  @override
  bool get isRecording => _isRecording;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  void dispose() {
    _amplitudeTimer?.cancel();
    _recorder.dispose();
    _amplitudeController.close();
  }
}
