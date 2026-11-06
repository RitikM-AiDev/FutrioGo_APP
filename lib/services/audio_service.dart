import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _currentRecordingPath;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  AudioPlayer get player => _player;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    final permitted = await _recorder.hasPermission();
    if (!permitted) {
      throw Exception('Microphone permission not granted');
    }

    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/futrio_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentRecordingPath = filePath;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );
    _isRecording = true;
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;

    final targetPath = path ?? _currentRecordingPath;
    if (targetPath != null && File(targetPath).existsSync()) {
      return targetPath;
    }
    return null;
  }

  Future<void> playAudio(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}

