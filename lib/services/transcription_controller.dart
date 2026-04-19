import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:smart_lecture_notes/services/api_service.dart';
import 'package:smart_lecture_notes/services/audio_service.dart';

typedef TranscriptUpdate = void Function(String transcript);
typedef ProcessingUpdate = void Function(bool isProcessing);
typedef ErrorUpdate = void Function(String message);

class LiveTranscriptionController {
  LiveTranscriptionController({
    AudioChunkRecorder? audioRecorder,
    TranscriptionApiService? apiService,
    required TranscriptUpdate onTranscript,
    required ProcessingUpdate onProcessingChanged,
    ErrorUpdate? onError,
    Duration chunkDuration = const Duration(milliseconds: 3000),
    Duration chunkGap = const Duration(milliseconds: 500),
  })  : _audioRecorder = audioRecorder ?? AudioChunkRecorder(),
        _apiService = apiService ?? TranscriptionApiService(),
        _onTranscript = onTranscript,
        _onProcessingChanged = onProcessingChanged,
        _onError = onError,
        _chunkDuration = chunkDuration,
        _chunkGap = chunkGap;

  final AudioChunkRecorder _audioRecorder;
  final TranscriptionApiService _apiService;
  final TranscriptUpdate _onTranscript;
  final ProcessingUpdate _onProcessingChanged;
  final ErrorUpdate? _onError;
  final Duration _chunkDuration;
  final Duration _chunkGap;

  Future<void> _loopTask = Future.value();
  Completer<void>? _pendingDrain;

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isStopping = false;
  int _pendingRequests = 0;
  bool _lastProcessing = false;

  String _transcript = '';

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  bool get isProcessing => _pendingRequests > 0;
  String get transcript => _transcript;

  Future<bool> start() async {
    if (_isRecording) return true;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return false;

    _isRecording = true;
    _isPaused = false;
    _isStopping = false;
    _transcript = '';
    _pendingRequests = 0;
    _lastProcessing = false;
    _notifyProcessing();

    _loopTask = _recordLoop();
    return true;
  }

  Future<void> pause() async {
    if (!_isRecording || _isPaused) return;
    _isPaused = true;
    await _flushCurrentChunk();
    await _loopTask;
  }

  Future<void> resume() async {
    if (!_isRecording || !_isPaused) return;
    _isPaused = false;
    _loopTask = _recordLoop();
  }

  Future<String> stop() async {
    if (!_isRecording && !_isStopping) return _transcript;
    _isRecording = false;
    _isPaused = false;
    _isStopping = true;

    await _flushCurrentChunk();
    await _loopTask;
    await _waitForPendingRequests();

    _isStopping = false;
    return _transcript;
  }

  Future<void> dispose() async {
    await _audioRecorder.dispose();
    _apiService.dispose();
  }

  Future<void> _recordLoop() async {
    while (_isRecording && !_isPaused) {
      try {
        await _audioRecorder.startChunk();
        await Future.delayed(_chunkDuration);
        if (!_isRecording || _isPaused) break;

        final path = await _audioRecorder.stopChunk();
        if (path != null && path.isNotEmpty) {
          _sendChunk(path);
        }

        if (!_isRecording || _isPaused) break;
        await Future.delayed(_chunkGap);
      } catch (_) {
        _onError?.call('Recording issue, retrying...');
      }
    }
  }

  Future<void> _flushCurrentChunk() async {
    if (!_audioRecorder.isRecording) return;
    final path = await _audioRecorder.stopChunk();
    if (path != null && path.isNotEmpty) {
      _sendChunk(path);
    }
  }

  void _sendChunk(String path) {
    _pendingRequests++;
    _notifyProcessing();
    unawaited(_processChunk(path));
  }

  Future<void> _processChunk(String path) async {
    try {
      print('[CONTROLLER] Processing chunk: $path');
      final text = await _apiService.transcribeAudio(path);
      final cleaned = _cleanText(text);
      
      print('[CONTROLLER] Raw text length: ${text.length}');
      print('[CONTROLLER] Cleaned text: $cleaned');
      
      if (cleaned.isEmpty) {
        print('[CONTROLLER] Empty transcription, skipping');
        return;
      }

      _transcript = _mergeTranscript(_transcript, cleaned);
      print('[CONTROLLER] Updated transcript: $_transcript');
      _onTranscript(_transcript);
    } catch (e) {
      print('[CONTROLLER] Exception during transcription: $e');
      _onError?.call('Network issue, retrying...');
    } finally {
      _pendingRequests = math.max(0, _pendingRequests - 1);
      _notifyProcessing();
      try {
        File(path).delete().catchError((_) {
          print('[CONTROLLER] Failed to delete temp file: $path');
        });
      } catch (_) {}
      if (_pendingRequests == 0 && _pendingDrain != null) {
        _pendingDrain?.complete();
        _pendingDrain = null;
      }
    }
  }

  Future<void> _waitForPendingRequests() {
    if (_pendingRequests == 0) return Future.value();
    _pendingDrain ??= Completer<void>();
    return _pendingDrain!.future;
  }

  void _notifyProcessing() {
    final isProcessing = _pendingRequests > 0 || _isStopping;
    if (_lastProcessing == isProcessing) return;
    _lastProcessing = isProcessing;
    _onProcessingChanged(isProcessing);
  }

  String _cleanText(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _mergeTranscript(String base, String chunk) {
    final baseText = base.trim();
    final chunkText = chunk.trim();
    
    if (baseText.isEmpty) return chunkText;
    if (chunkText.isEmpty) return baseText;

    // Split into words for overlap detection
    final baseWords = _splitWords(baseText);
    final chunkWords = _splitWords(chunkText);
    
    if (baseWords.isEmpty || chunkWords.isEmpty) {
      return _mergeSentences(baseText, chunkText);
    }

    // Find overlap: check up to 15 words (default 1-1.5 sec of speech)
    final maxOverlap = math.min(15, math.min(baseWords.length, chunkWords.length));
    var overlap = 0;

    for (var size = maxOverlap; size >= 1; size--) {
      if (_overlapMatches(baseWords, chunkWords, size)) {
        overlap = size;
        print('[CONTROLLER] Overlap detected: $overlap words');
        break;
      }
    }

    // Remove overlapped words from chunk
    final trimmedChunk = chunkWords.skip(overlap).join(' ').trim();
    if (trimmedChunk.isEmpty) return baseText;
    
    return _mergeSentences(baseText, trimmedChunk);
  }

  /// Merge two text segments, handling punctuation and sentence structure
  String _mergeSentences(String base, String chunk) {
    if (base.isEmpty) return chunk;
    if (chunk.isEmpty) return base;

    // Add space between base and chunk, handling punctuation
    if (base.endsWith(',') || base.endsWith('.') || base.endsWith('!') || base.endsWith('?')) {
      // Base ends with punctuation - add space and capitalize if needed
      if (chunk[0] == chunk[0].toUpperCase() && chunk[0] != chunk[0].toLowerCase()) {
        return '$base $chunk';
      }
      return '$base ${chunk[0].toUpperCase()}${chunk.substring(1)}';
    }
    
    // Base doesn't end with punctuation - just add space
    return '$base $chunk';
  }

  List<String> _splitWords(String text) {
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  }

  bool _overlapMatches(List<String> baseWords, List<String> chunkWords, int size) {
    final baseStart = baseWords.length - size;
    for (var i = 0; i < size; i++) {
      if (_normalizeWord(baseWords[baseStart + i]) != _normalizeWord(chunkWords[i])) {
        return false;
      }
    }
    return true;
  }

  String _normalizeWord(String input) {
    // Remove punctuation and convert to lowercase for comparison
    return input
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w']"), '') // Keep letters, numbers, apostrophes
        .replaceAll(RegExp(r"'+"), "'"); // Normalize multiple apostrophes
  }
}
