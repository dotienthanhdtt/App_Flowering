// lib/core/services/audio_service.dart
import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Audio service for recording and playback
class AudioService extends GetxService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  final isRecording = false.obs;
  final isPlaying = false.obs;
  final recordingDuration = Duration.zero.obs;
  final playbackPosition = Duration.zero.obs;
  final playbackDuration = Duration.zero.obs;

  Timer? _recordingTimer;
  String? _currentRecordingPath;

  // Stream subscriptions for proper cleanup
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  /// Initialize audio service
  Future<AudioService> init() async {
    // Listen to player state changes and store subscriptions
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });

    _positionSubscription = _player.onPositionChanged.listen((position) {
      playbackPosition.value = position;
    });

    _durationSubscription = _player.onDurationChanged.listen((duration) {
      playbackDuration.value = duration;
    });

    return this;
  }

  // ─────────────────────────────────────────────────────────────────
  // Recording
  // ─────────────────────────────────────────────────────────────────

  /// Check if recording is permitted
  Future<bool> hasRecordPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording audio
  Future<String?> startRecording() async {
    if (isRecording.value) return null;

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return null;

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      isRecording.value = true;
      recordingDuration.value = Duration.zero;

      // Track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingDuration.value += const Duration(seconds: 1);
      });

      return _currentRecordingPath;
    } catch (e) {
      if (kDebugMode) {
        print('Recording error: $e');
      }
      isRecording.value = false;
      return null;
    }
  }

  /// Stop recording and return file path
  Future<String?> stopRecording() async {
    if (!isRecording.value) return null;

    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final path = await _recorder.stop();
      isRecording.value = false;

      return path;
    } catch (e) {
      if (kDebugMode) {
        print('Stop recording error: $e');
      }
      isRecording.value = false;
      return null;
    }
  }

  /// Cancel recording and delete file
  Future<void> cancelRecording() async {
    if (!isRecording.value) return;

    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      await _recorder.stop();
      isRecording.value = false;

      // Delete the file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentRecordingPath = null;
    } catch (e) {
      if (kDebugMode) {
        print('Cancel recording error: $e');
      }
      isRecording.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Playback
  // ─────────────────────────────────────────────────────────────────

  /// Play audio from file path
  Future<void> playFile(String path) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      if (kDebugMode) {
        print('Playback error: $e');
      }
    }
  }

  /// Play audio from URL
  Future<void> playUrl(String url) async {
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (e) {
      if (kDebugMode) {
        print('Playback from URL error: $e');
      }
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      if (kDebugMode) {
        print('Pause error: $e');
      }
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await _player.resume();
    } catch (e) {
      if (kDebugMode) {
        print('Resume error: $e');
      }
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _player.stop();
      playbackPosition.value = Duration.zero;
    } catch (e) {
      if (kDebugMode) {
        print('Stop playback error: $e');
      }
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      if (kDebugMode) {
        print('Seek error: $e');
      }
    }
  }

  /// Set playback speed
  Future<void> setPlaybackRate(double rate) async {
    try {
      await _player.setPlaybackRate(rate);
    } catch (e) {
      if (kDebugMode) {
        print('Set playback rate error: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────────────────────────

  /// Delete recording file
  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  void onClose() {
    _recordingTimer?.cancel();
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.onClose();
  }
}
