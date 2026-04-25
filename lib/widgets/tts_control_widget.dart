import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/services/tts_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tts.initialize(onStateChanged: () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  void _onPlay() => _tts.speak(widget.text);
  void _onPause() => _tts.pause();
  void _onStop() => _tts.stop();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speed slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Speed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  '${_speechRate.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Slider(
              value: _speechRate,
              min: 0.25,
              max: 2.0,
              divisions: 7,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _speechRate = val);
                _tts.setSpeechRate(val);
              },
            ),

            // Voice gender toggle
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Voice:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
                _buildVoiceChip('female', 'Female', Icons.female_rounded),
                const SizedBox(width: 8),
                _buildVoiceChip('male', 'Male', Icons.male_rounded),
              ],
            ),
            const SizedBox(height: 12),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  Icons.stop_circle_rounded,
                  Colors.redAccent,
                  40,
                  _onStop,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  _tts.isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  AppColors.primary,
                  56,
                  _tts.isPlaying ? _onPause : _onPlay,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
      IconData icon, Color color, double size, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      color: color,
      iconSize: size,
      onPressed: onPressed,
    );
  }

  Widget _buildVoiceChip(String gender, String label, IconData icon) {
    final isActive = _voiceGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() => _voiceGender = gender);
        _tts.setVoiceGender(gender);
        if (_tts.isPlaying) {
          _tts.stop().then((_) => _tts.speak(widget.text));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? Colors.white : AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
