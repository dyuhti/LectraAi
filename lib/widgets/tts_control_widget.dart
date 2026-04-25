import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/services/accessibility_tts_service.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

/// Reusable TTS control widget. Drop into any screen with:
///   TtsControlWidget(text: "your content here")
class TtsControlWidget extends StatefulWidget {
  final String text;

  const TtsControlWidget({Key? key, required this.text}) : super(key: key);

  @override
  State<TtsControlWidget> createState() => _TtsControlWidgetState();
}

class _TtsControlWidgetState extends State<TtsControlWidget> {
  final TtsService _tts = TtsService();
  double _speechRate = 0.5;
  String _voiceGender = 'female';
  bool _isPlaying = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onPlay() async {
    if (!mounted) return;
    setState(() => _isPlaying = true);
    await _tts.speak(widget.text);
  }

  Future<void> _onPause() async {
    await _tts.pause();
    if (!mounted) return;
    setState(() => _isPlaying = false);
  }

  Future<void> _onStop() async {
    await _tts.stop();
    if (!mounted) return;
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Voice Controls',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),
              // Speed slider section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Playback Speed',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_speechRate.toStringAsFixed(1)}x',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        thumbShape: RoundSliderThumbShape(
                          elevation: 2,
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: _speechRate,
                        min: 0.25,
                        max: 2.0,
                        divisions: 7,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.primary.withOpacity(0.2),
                        onChanged: (val) {
                          setState(() => _speechRate = val);
                          _tts.setSpeechRate(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Voice gender section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voice Selection',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child:
                              _buildVoiceChip('female', 'Female', Icons.female_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildVoiceChip('male', 'Male', Icons.male_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    Icons.stop_circle_rounded,
                    AppColors.textSecondary,
                    44,
                    _onStop,
                    tooltip: 'Stop',
                  ),
                  const SizedBox(width: 20),
                  _buildControlButton(
                    _isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    AppColors.primary,
                    60,
                    _isPlaying ? _onPause : _onPlay,
                    tooltip: _isPlaying ? 'Pause' : 'Play',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    Color color,
    double size,
    VoidCallback onPressed, {
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              icon,
              color: color,
              size: size,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceChip(String gender, String label, IconData icon) {
    final isActive = _voiceGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() => _voiceGender = gender);
        _tts.setVoiceGender(gender);
        if (_isPlaying) {
          _tts.stop().then((_) => _tts.speak(widget.text));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
