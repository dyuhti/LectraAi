import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'audio_processing_screen.dart';
import 'package:smart_lecture_notes/routes/page_transitions.dart';

class RecordLectureScreen extends StatefulWidget {
  const RecordLectureScreen({Key? key}) : super(key: key);

  @override
  State<RecordLectureScreen> createState() => _RecordLectureScreenState();
}

class _RecordLectureScreenState extends State<RecordLectureScreen>
    with TickerProviderStateMixin {
  static const Color _navy = Color(0xFF0A2A8A);
  static const Color _navyDeep = Color(0xFF071E66);
  static const Color _waveBlue = Color(0xFF8FB6FF);
  static const Color _glowBlue = Color(0xFFBFD4FF);
  static const Color _textMuted = Color(0xFF6F7CAB);
  static const Color _chipGreen = Color(0xFF1FB36B);
  static const Color _chipGreenBg = Color(0xFFE9F8F0);
  static const Color _chipBlueBg = Color(0xFFEFF4FF);

  late final AudioRecorder _audioRecorder;
  late final AnimationController _waveformController;
  late final AnimationController _idlePulseController;
  late final AnimationController _ringController;
  late final AnimationController _ctaRippleController;
  late final AnimationController _particleController;
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
    _idlePulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _ctaRippleController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveformController.dispose();
    _idlePulseController.dispose();
    _ringController.dispose();
    _ctaRippleController.dispose();
    _particleController.dispose();
    unawaited(_audioRecorder.dispose());
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _navy,
      ),
    );
  }

  Future<String> _createRecordingPath() async {
    final dir = await getTemporaryDirectory();
    final fileName = 'lecture_${DateTime.now().millisecondsSinceEpoch}.m4a';
    return p.join(dir.path, fileName);
  }

  void _triggerCtaRipple() {
    _ctaRippleController.forward(from: 0);
  }

  void _handleStartTap() {
    _triggerCtaRipple();
    _startRecording();
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
      _ringController.repeat();
      _particleController.repeat();

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
      _ringController.stop();
      _particleController.stop();
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
      _ringController.repeat();
      _particleController.repeat();
    } catch (e) {
      _showError('Failed to resume recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _timer?.cancel();
      _waveformController.stop();
      _ringController.stop();
      _particleController.stop();

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
    final width = MediaQuery.sizeOf(context).width;
    final contentWidth = math.min(math.max(width - 48, 240.0), 360.0);
    final isActive = _isRecording && !_isPaused;
    final primaryStatus = _isRecording
        ? (_isPaused ? 'Recording paused' : 'Recording in progress...')
        : 'Tap to start AI lecture capture';
    final secondaryStatus = _isRecording
        ? (_isPaused ? 'Ready when you are' : 'Structuring notes in real time')
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Record Lecture',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRecording) _buildMicActiveChip(isActive),
                      if (_isRecording) const SizedBox(height: 16),
                      _buildHeroCard(contentWidth, isActive),
                      const SizedBox(height: 28),
                      _buildTimerDisplay(),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          primaryStatus,
                          key: ValueKey(primaryStatus),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (secondaryStatus != null) ...[
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            secondaryStatus,
                            key: ValueKey(secondaryStatus),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: _isRecording
                            ? _buildWaveform()
                            : const SizedBox(height: 48),
                      ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: _isRecording
                            ? _buildActiveControls()
                            : _buildIdleControl(),
                      ),
                      if (!_isRecording) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Best results when placed near the lecturer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      _buildPoweredByChip(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMicActiveChip(bool isActive) {
    final label = isActive ? 'Mic Active' : 'Paused';
    final chipColor = isActive ? _chipGreenBg : _chipBlueBg;
    final dotColor = isActive ? _chipGreen : _waveBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: dotColor.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(double width, bool isActive) {
    final cardHeight = width * (isActive ? 0.76 : 0.70);
    final micSize = width * (isActive ? 0.36 : 0.32);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      width: width,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _navy.withOpacity(0.06), width: 1),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [
                    Colors.white,
                    _chipBlueBg,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          if (_isRecording && !_isPaused) _buildFloatingParticles(),
          AnimatedBuilder(
            animation: _idlePulseController,
            builder: (context, child) {
              final scale = 0.92 + (_idlePulseController.value * 0.12);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: micSize * 2.0,
                  height: micSize * 2.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _glowBlue.withOpacity(isActive ? 0.45 : 0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              );
            },
          ),
          if (isActive) _buildRecordingRings(micSize + 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            width: micSize,
            height: micSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _glowBlue.withOpacity(0.65),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: _navy.withOpacity(isActive ? 0.30 : 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              Icons.mic_rounded,
              size: micSize * 0.48,
              color: isActive ? _navy : _navyDeep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return SizedBox(
      height: 64,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _formatTime(_recordingSeconds),
            key: ValueKey(_recordingSeconds),
            style: const TextStyle(
              color: _navy,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    const barCount = 18;

    return SizedBox(
      key: const ValueKey('waveform'),
      height: 56,
      child: AnimatedBuilder(
        animation: _waveformController,
        builder: (context, child) {
          final t = _waveformController.value * math.pi * 2;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(barCount, (index) {
              final phase = (index / barCount) * math.pi;
              final v = (math.sin(t + phase) + 1) / 2;
              final height = 10 + (v * 26);
              final opacity = 0.4 + (v * 0.6);

              return Container(
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _waveBlue.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildIdleControl() {
    return AnimatedBuilder(
      key: const ValueKey('idle-control'),
      animation: _idlePulseController,
      builder: (context, child) {
        final floatY = -2 + (_idlePulseController.value * 4);
        return Transform.translate(
          offset: Offset(0, floatY),
          child: child,
        );
      },
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _ctaRippleController,
              builder: (context, child) {
                final value = _ctaRippleController.value;
                if (value == 0) return const SizedBox.shrink();
                return Opacity(
                  opacity: 1 - value,
                  child: Transform.scale(
                    scale: 1 + (value * 1.4),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _waveBlue.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleStartTap,
                customBorder: const CircleBorder(),
                child: Ink(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_navy, _navyDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveControls() {
    return Row(
      key: const ValueKey('active-controls'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          label: _isPaused ? 'Resume' : 'Pause',
          icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          background: Colors.white,
          foreground: _navy,
          glow: _waveBlue,
          onTap: _isPaused ? _resumeRecording : _pauseRecording,
        ),
        const SizedBox(width: 26),
        _buildControlButton(
          label: 'Stop',
          icon: Icons.stop_rounded,
          background: _navy,
          foreground: Colors.white,
          glow: _navy,
          onTap: _stopRecording,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required Color glow,
    required VoidCallback onTap,
  }) {
    final border = background == Colors.white
        ? Border.all(color: _glowBlue.withOpacity(0.7), width: 1.2)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: border,
                boxShadow: [
                  BoxShadow(
                    color: glow.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    color: foreground,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPoweredByChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _chipBlueBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _glowBlue.withOpacity(0.55), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: _navy,
            size: 14,
          ),
          SizedBox(width: 6),
          Text(
            'Powered by LectraAI speech intelligence',
            style: TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingRings(double size) {
    return AnimatedBuilder(
      animation: _ringController,
      builder: (context, child) {
        final t = _ringController.value;
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final progress = (t + (index * 0.2)) % 1.0;
            final scale = 1 + (progress * 0.9);
            final opacity = (1 - progress) * 0.35;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _waveBlue.withOpacity(opacity),
                    width: 2,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final t = _particleController.value;

                Widget particle(double dx, double dy, double phase, double size) {
                  final progress = (t + phase) % 1.0;
                  final y = dy - (progress * 22);
                  final opacity = (1 - progress) * 0.45;
                  return Positioned(
                    left: dx,
                    top: y,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: _glowBlue.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    particle(w * 0.18, h * 0.7, 0.0, 4),
                    particle(w * 0.72, h * 0.6, 0.25, 3.2),
                    particle(w * 0.32, h * 0.55, 0.55, 3.6),
                    particle(w * 0.6, h * 0.76, 0.75, 4),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
