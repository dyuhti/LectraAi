import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'audio_transcript_screen.dart';
import 'dart:async';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class AudioProcessingScreen extends StatefulWidget {
  final String audioPath;
  final Duration duration;

  const AudioProcessingScreen({
    required this.audioPath, required this.duration, Key? key,
  }) : super(key: key);

  @override
  State<AudioProcessingScreen> createState() => _AudioProcessingScreenState();
}

class _AudioProcessingScreenState extends State<AudioProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Timer _navigationTimer;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Auto-navigate after 3 seconds
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      Get.off(() => const AudioTranscriptScreen());
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _navigationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rotating Loader
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryLight,
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Main Text
            const Text(
              'Converting speech to text...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'AI is processing your audio',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
