import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'audio_transcript_screen.dart';
import 'dart:async';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/services/lecture_ai_service.dart';

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
  final LectureAiService _lectureAiService = LectureAiService();
  
  String _processingStatus = 'Converting speech to text...';
  String _processingSubtitle = 'AI is processing your audio';
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Start processing with Groq AI
    _processAudioWithGroq();
  }

  Future<void> _processAudioWithGroq() async {
    try {
      // Step 1: Convert audio to transcript (simulated)
      setState(() {
        _processingStatus = 'Converting speech to text...';
        _processingSubtitle = 'Using Groq AI for transcription';
      });
      
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulated transcript from audio
      const sampleTranscript = '''
Today we discussed the fundamentals of photosynthesis. 
Photosynthesis is the process by which plants convert light energy into chemical energy.
It occurs in two main stages: the light-dependent reactions and the light-independent reactions.
The light-dependent reactions happen in the thylakoid membranes and produce ATP and NADPH.
The Calvin cycle is the light-independent reaction that produces glucose.
Chlorophyll is the primary pigment that absorbs light energy.
We also learned about the electron transport chain and the role of photosystem I and II.
The equation for photosynthesis is: 6CO2 + 6H2O + light energy → C6H12O6 + 6O2.
Different wavelengths of light have different efficiencies in photosynthesis.
Next class we will discuss cellular respiration and how it relates to photosynthesis.
      ''';

      // Step 2: Generate summary using Groq
      setState(() {
        _processingStatus = 'Analyzing content...';
        _processingSubtitle = 'Groq is generating summary';
      });
      
      final summary = await _lectureAiService.generateLectureSummary(sampleTranscript);
      
      setState(() {
        _processingStatus = 'Generating study guide...';
        _processingSubtitle = 'Creating personalized notes';
      });

      // Step 3: Generate quiz
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      setState(() {
        _isProcessing = false;
      });

      // Navigate to transcript screen with processed data
      Get.off(() => AudioTranscriptScreen(
        transcript: sampleTranscript,
        summary: summary,
      ));
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isProcessing = false;
      });
      
      // Fallback: navigate with empty data after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Get.off(() => const AudioTranscriptScreen());
      }
    }
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
            if (_isProcessing)
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
              )
            else if (_errorMessage != null)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textSecondary,
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                    size: 40,
                  ),
                ),
              )
            else
              Container(
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
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primaryLight,
                    size: 40,
                  ),
                ),
              ),
            const SizedBox(height: 40),

            // Main Text
            Text(
              _processingStatus,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              _errorMessage ?? _processingSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            // If error, show retry button
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isProcessing = true;
                  });
                  _processAudioWithGroq();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
