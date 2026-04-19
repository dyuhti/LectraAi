import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioChunkRecorder {
  AudioChunkRecorder({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> startChunk() async {
    if (_isRecording) return;
    final path = await _createRecordingPath();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _isRecording = true;
  }

  Future<String?> stopChunk() async {
    if (!_isRecording) return null;
    _isRecording = false;
    return _recorder.stop();
  }

  Future<void> pause() async {
    if (!_isRecording) return;
    await _recorder.pause();
  }

  Future<void> resume() async {
    if (!_isRecording) return;
    await _recorder.resume();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }

  Future<String> _createRecordingPath() async {
    final dir = await getTemporaryDirectory();
    final fileName = 'lecture_chunk_${DateTime.now().millisecondsSinceEpoch}.wav';
    return p.join(dir.path, fileName);
  }
}
