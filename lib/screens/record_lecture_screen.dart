import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'audio_processing_screen.dart';
import 'dart:async';
import 'package:smart_lecture_notes/routes/page_transitions.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class RecordLectureScreen extends StatefulWidget {
  const RecordLectureScreen({Key? key}) : super(key: key);

  @override
  State<RecordLectureScreen> createState() => _RecordLectureScreenState();
}

class _RecordLectureScreenState extends State<RecordLectureScreen>
    with TickerProviderStateMixin {
  late final AudioRecorder _audioRecorder;
  late AnimationController _waveformController;
  Timer? _timer;
  int _recordingSeconds = 0;
  bool _isRecording = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveformController.dispose();
    unawaited(_audioRecorder.dispose());
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<String> _createRecordingPath() async {
    final dir = await getTemporaryDirectory();
    final fileName = 'lecture_${DateTime.now().millisecondsSinceEpoch}.m4a';
    return p.join(dir.path, fileName);
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showError('Microphone permission is required to record audio.');
        return;
      }

      final path = await _createRecordingPath();
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
        ),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingSeconds = 0;
      });

      _waveformController.repeat();

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isRecording && !_isPaused) {
          setState(() {
            _recordingSeconds++;
          });
        }
      });
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      if (!mounted) return;
      setState(() {
        _isPaused = true;
      });
      _waveformController.stop();
    } catch (e) {
      _showError('Failed to pause recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      if (!mounted) return;
      setState(() {
        _isPaused = false;
      });
      _waveformController.repeat();
    } catch (e) {
      _showError('Failed to resume recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _timer?.cancel();
      _waveformController.stop();

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      // Navigate to audio processing screen
      if (path != null && path.isNotEmpty) {
        Navigator.of(context).push(
          AppPageTransitions.fadeSlide(
            AudioProcessingScreen(
              audioPath: path,
              duration: Duration(seconds: _recordingSeconds),
            ),
          ),
        );
      } else {
        _showError('No recording file was created.');
      }
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Record Lecture',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Microphone Icon Circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isRecording
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.primaryLight.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.mic,
                    size: 60,
                    color: _isRecording
                        ? AppColors.primary
                        : AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Timer Display
              Text(
                _formatTime(_recordingSeconds),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 30),

              // Waveform Visualization (only show when recording)
              if (_isRecording)
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: _buildWaveform(),
                ),

              // Control Buttons
              if (!_isRecording)
                GestureDetector(
                  onTap: _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary,
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pause/Resume Button
                    GestureDetector(
                      onTap: _isPaused ? _resumeRecording : _pauseRecording,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),

                    // Stop Button
                    GestureDetector(
                      onTap: _stopRecording,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.stop,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              // Status Text
              Text(
                _isRecording
                    ? 'Recording in progress...'
                    : 'Tap to start recording',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 40,
      child: Center(
        child: AnimatedBuilder(
          animation: _waveformController,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(20, (index) {
                final animationValue = _waveformController.value;
                final delay = (index / 20);
                final normalizedValue =
                    ((animationValue - delay) % 1.0).abs() * 2 - 1;
                final height = (normalizedValue.abs() * 20 + 2).clamp(2.0, 20.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 3,
                    height: height.toDouble(),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
