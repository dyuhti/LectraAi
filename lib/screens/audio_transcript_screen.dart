import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'my_notes_screen.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/providers/note_provider.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class AudioTranscriptScreen extends StatefulWidget {
  final String? transcript;
  final Map<String, dynamic>? summary;
  final String sourceLabel;

  const AudioTranscriptScreen({
    this.transcript,
    this.summary,
    this.sourceLabel = 'AI Notes',
    Key? key,
  }) : super(key: key);

  @override
  State<AudioTranscriptScreen> createState() => _AudioTranscriptScreenState();
}

class _AudioTranscriptScreenState extends State<AudioTranscriptScreen> {
  final TranscriptionApiService _apiService = TranscriptionApiService();
  bool _isSaving = false;

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  String _safeString(dynamic value) {
    return value == null ? '' : value.toString().trim();
  }

  List<String> _normalizeKeyPoints(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String) {
      final lines = value
          .split(RegExp(r'\n+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      return lines.isNotEmpty ? lines : [value.trim()];
    }
    return [];
  }

  void _saveNote() async {
    if (_isSaving) {
      return;
    }

    final transcript = widget.transcript ?? '';
    
    if (transcript.isEmpty) {
      Get.snackbar(
        'Error',
        'No AI notes to save',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      print('[AI_NOTES] Saving note with text length: ${transcript.length}');
      final summaryData = widget.summary ?? {};
      final summaryText = _safeString(summaryData['summary']);
      final existingKeyPoints = _normalizeKeyPoints(
        summaryData['keyPoints'] ?? summaryData['key_points'],
      );

      Map<String, dynamic> processed = {};
      if (summaryText.isEmpty || existingKeyPoints.isEmpty) {
        try {
          processed = await _apiService.processTranscript(transcript);
        } catch (e) {
          print('[AI_NOTES] AI processing failed: $e');
        }
      }

      final processedSummary = _safeString(processed['summary']);
      final processedCleanText = _safeString(processed['clean_text']);
      final processedKeyPoints = _normalizeKeyPoints(
        processed['key_points'] ?? processed['keyPoints'],
      );

      final summary = summaryText.isNotEmpty ? summaryText : processedSummary;
      final keyPoints = existingKeyPoints.isNotEmpty
          ? existingKeyPoints
          : processedKeyPoints;
      final cleanedText =
          processedCleanText.isNotEmpty ? processedCleanText : transcript;
      final lectureTitle = _safeString(summaryData['lectureTitle']);

      final note = Note(
        title: lectureTitle.isNotEmpty
            ? lectureTitle
            : 'Lecture ${DateTime.now().toString().split(' ')[0]}',
        subject: widget.sourceLabel,
        content: cleanedText,
        cleanedText: cleanedText,
        summary: summary.isNotEmpty ? summary : 'AI generated notes',
        createdAt: DateTime.now(),
        keyPoints: keyPoints,
      );

      await context.read<NoteProvider>().createNote(note);

      print('[AI_NOTES] Note saved successfully to Mongo API');
      
      Get.snackbar(
        'Success',
        'AI notes saved to your notes',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyNotesScreen()),
      );
    } catch (e) {
      print('[AI_NOTES] Error saving note: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to save note: $e',
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryText = _safeString(widget.summary?['summary']);
    final keyPoints = _normalizeKeyPoints(
      widget.summary?['keyPoints'] ?? widget.summary?['key_points'],
    );
    final lectureTitle = _safeString(widget.summary?['lectureTitle']);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'AI Notes',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AI Notes',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Summary Section
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.card(
                  color: AppColors.primaryLight.withOpacity(0.08),
                ),
                child: Text(
                  summaryText.isNotEmpty
                      ? summaryText
                      : 'This lecture covers linked list data structures, including types, implementation details, and complexity analysis compared to arrays.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Key Points Section (if summary available)
              if (keyPoints.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Key Points',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...keyPoints.map((point) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin:
                                    const EdgeInsets.only(top: 6, right: 10),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  point,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 28),
                  ],
                ),

              // Full notes section
              const Text(
                'FULL CLEANED TEXT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lectureTitle.isNotEmpty
                          ? lectureTitle
                          : 'AI Notes',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.transcript ?? 'No notes available',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveNote,
                  style: AppButtonStyles.primary(radius: 16),
                  child: _isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Save Note',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => Get.back(),
                  style: AppButtonStyles.primary(radius: 16).copyWith(
                    backgroundColor: WidgetStateProperty.all(
                      AppColors.primaryDark,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
