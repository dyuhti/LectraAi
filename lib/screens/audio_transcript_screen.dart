import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/providers/note_provider.dart';
import 'package:smart_lecture_notes/providers/progress_provider.dart';
import 'package:smart_lecture_notes/services/auth_service.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/utils/tts_text_builder.dart';

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

  static const Color _neutralSurface = Colors.white;
  static const Color _neutralTint = Color(0xFFF8FAFC);
  static const Color _neutralBorder = Color(0xFFE5E7EB);
  static const Color _neutralTitle = Color(0xFF0F172A);
  static const Color _neutralBody = Color(0xFF334155);

  static const TextStyle _sectionBodyStyle = TextStyle(
    fontSize: 14,
    color: _neutralBody,
    height: 1.6,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle _keyPointBodyStyle = TextStyle(
    fontSize: 13.5,
    color: _neutralBody,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle _keyPointLeadStyle = TextStyle(
    fontSize: 13.5,
    color: _neutralTitle,
    height: 1.45,
    fontWeight: FontWeight.w800,
  );

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

  String _cleanDisplayText(String value) {
    return value
        .replaceAll(RegExp(r'^\s*[-*•]+\s*'), '')
        .replaceAll(RegExp(r'^\s*\d+[\.)]\s*'), '')
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    required Color tint,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(color: _neutralSurface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _neutralTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _neutralBorder, width: 1),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _neutralTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryText(String text) {
    return Text(
      _cleanDisplayText(text),
      style: _sectionBodyStyle,
    );
  }

  TextSpan _buildKeyPointSpan(String point) {
    final cleaned = _cleanDisplayText(point);
    final colonIndex = cleaned.indexOf(':');

    if (colonIndex > 0 && colonIndex < cleaned.length - 1) {
      return TextSpan(
        children: [
          TextSpan(text: cleaned.substring(0, colonIndex + 1), style: _keyPointLeadStyle),
          TextSpan(text: ' ${cleaned.substring(colonIndex + 1).trim()}', style: _keyPointBodyStyle),
        ],
      );
    }

    return TextSpan(text: cleaned, style: _keyPointBodyStyle);
  }

  Widget _buildKeyPointItem(String point) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: _buildKeyPointSpan(point),
            ),
          ),
        ],
      ),
    );
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
        backgroundColor: AppColors.primaryDark,
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

      final authService = AuthService();
      final userId = await authService.getUserId() ?? '';
      
      print('[AI_NOTES] Saving note for user: $userId');

      final note = Note(
        userId: userId,
        title: lectureTitle.isNotEmpty
            ? lectureTitle
            : 'Lecture ${DateTime.now().toString().split(' ')[0]}',
        transcript: transcript,
        subject: widget.sourceLabel,
        content: cleanedText,
        cleanedText: cleanedText,
        summary: summary.isNotEmpty ? summary : 'AI generated notes',
        createdAt: DateTime.now(),
        keyPoints: keyPoints,
      );

      await context.read<NoteProvider>().createNote(note);
      await context.read<NoteProvider>().loadNotes();
      
      // Refresh daily progress counts
      if (mounted) {
        await context.read<ProgressProvider>().refreshProgress();
        final progress = context.read<ProgressProvider>().progress;
        print('Updated progress: $progress');
        print('[AI_NOTES] Progress -> notes: ${progress.notesCreated}, audio: ${progress.audioRecorded}, quiz: ${progress.quizzesGenerated}');
        setState(() {});
      }

      print('[AI_NOTES] Note saved successfully to Mongo API');
      
      Get.snackbar(
        'Success',
        'AI notes saved to your notes',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      if (!mounted) {
        return;
      }
      Get.offNamed(AppRoutes.notes);
    } catch (e) {
      print('[AI_NOTES] Error saving note: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to save note: $e',
          backgroundColor: AppColors.primaryDark,
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
    final transcriptText = _safeString(widget.transcript);
    _publishScreenText(
      getScreenText(summaryText, keyPoints, lectureTitle, transcriptText),
    );

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
                  color: _neutralTint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _neutralBorder, width: 1),
                ),
                child: const Text(
                  'AI Notes',
                  style: TextStyle(
                    color: _neutralTitle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (lectureTitle.isNotEmpty) ...[
                Text(
                  lectureTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI-generated lecture summary',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
              ],

              // Summary Section
              _buildSectionCard(
                title: 'Summary',
                icon: Icons.subject_rounded,
                tint: AppColors.primary,
                child: _buildSummaryText(
                  summaryText.isNotEmpty
                      ? summaryText
                      : 'This lecture covers linked list data structures, including types, implementation details, and complexity analysis compared to arrays.',
                ),
              ),
              const SizedBox(height: 28),

              // Key Points Section (if summary available)
              if (keyPoints.isNotEmpty)
                _buildSectionCard(
                  title: 'Key Takeaways',
                  icon: Icons.lightbulb_rounded,
                  tint: AppColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: keyPoints.map(_buildKeyPointItem).toList(),
                  ),
                ),
              if (keyPoints.isNotEmpty) const SizedBox(height: 28),

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
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
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

  String getScreenText(
    String summaryText,
    List<String> keyPoints,
    String lectureTitle,
    String transcriptText,
  ) {
    final structuredContent = [
      if (summaryText.trim().isNotEmpty) 'Summary. ${summaryText.trim()}',
      if (transcriptText.trim().isNotEmpty) 'Full cleaned text. ${transcriptText.trim()}',
    ].join('\n\n');

    return buildStructuredText(
      title: lectureTitle.isNotEmpty ? lectureTitle : 'AI Notes',
      content: structuredContent,
      keyPoints: keyPoints,
    );
  }

  void _publishScreenText(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccessibilityProvider>().setScreenTextIfCurrent(context, text);
    });
  }
}
