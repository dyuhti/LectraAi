import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/providers/document_provider.dart';
import 'package:smart_lecture_notes/screens/my_notes_screen.dart';
import 'package:smart_lecture_notes/providers/note_provider.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/utils/tts_text_builder.dart';

class PreviewDocumentScreen extends StatefulWidget {
  const PreviewDocumentScreen({Key? key}) : super(key: key);

  @override
  State<PreviewDocumentScreen> createState() => _PreviewDocumentScreenState();
}

class _PreviewDocumentScreenState extends State<PreviewDocumentScreen> {
  static String formatSummary(String text) {
    final cleaned = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
    final lines = cleaned
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines.join('\n');
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildNoteContent({
    required String title,
    required String summary,
    required bool isResearchPaper,
    required String authors,
    required String journalInfo,
    required String doi,
    required String abstractText,
    required List<String> detailLines,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln('');
    buffer.writeln('Summary');
    buffer.writeln(summary);

    if (isResearchPaper &&
        (authors.isNotEmpty || journalInfo.isNotEmpty || doi.isNotEmpty || abstractText.isNotEmpty)) {
      buffer.writeln('');
      buffer.writeln('Research Details');
      if (authors.isNotEmpty) {
        buffer.writeln('- Authors: $authors');
      }
      if (journalInfo.isNotEmpty) {
        buffer.writeln('- Source: $journalInfo');
      }
      if (doi.isNotEmpty) {
        buffer.writeln('- DOI: $doi');
      }
      if (abstractText.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Abstract');
        buffer.writeln(abstractText);
      }
    }

    if (detailLines.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Document Details');
      for (final line in detailLines) {
        buffer.writeln('- $line');
      }
    }

    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final documentProvider = context.watch<DocumentProvider>();
    final summary = documentProvider.summary.trim();
    final extractedText = documentProvider.extractedText.trim();
    final title = documentProvider.title.trim();
    final authors = documentProvider.authors.trim();
    final doi = documentProvider.doi.trim();
    final abstractText = documentProvider.abstractText.trim();
    final journalInfo = documentProvider.journalInfo.trim();
    final isResearchPaper = documentProvider.isResearchPaper;
    final formattedSummary = summary.isEmpty ? '' : formatSummary(summary);
    final noteTitle = title.isEmpty ? 'Document Summary' : title;
    final hasResearchFields =
      authors.isNotEmpty || journalInfo.isNotEmpty || doi.isNotEmpty || abstractText.isNotEmpty;
    final canSave =
        formattedSummary.isNotEmpty || extractedText.isNotEmpty;
    final noteContent = _buildNoteContent(
      title: noteTitle,
      summary: formattedSummary.isEmpty ? 'Summary unavailable.' : formattedSummary,
      isResearchPaper: isResearchPaper,
      authors: authors,
      journalInfo: journalInfo,
      doi: doi,
      abstractText: abstractText,
      detailLines: documentProvider.detailLines,
    );
    _publishScreenText(
      getScreenText(
        noteTitle,
        formattedSummary,
        documentProvider.detailLines,
        abstractText,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Preview Document',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              noteTitle.isEmpty ? 'Document Summary' : noteTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: formattedSummary.isEmpty
                  ? const Text(
                      'Summary unavailable.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Text(
                      formattedSummary,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF334155),
                      ),
                    ),
            ),
            if (hasResearchFields) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDCE6FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Research Details',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (journalInfo.isNotEmpty)
                      _buildInfoRow('Source', journalInfo),
                    if (authors.isNotEmpty)
                      _buildInfoRow('Authors', authors),
                    if (doi.isNotEmpty) _buildInfoRow('DOI', doi),
                    if (abstractText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Abstract',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        abstractText,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),

      // Fixed bottom navigation bar with Save/Cancel buttons
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (!canSave) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No extracted text to save.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  final note = Note(
                    title: noteTitle,
                    subject: 'Document',
                    content: noteContent,
                    summary: formattedSummary.isEmpty
                        ? 'Summary unavailable.'
                        : formattedSummary,
                    cleanedText: extractedText,
                    createdAt: DateTime.now(),
                  );

                  try {
                    await context.read<NoteProvider>().createNote(note);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Note saved successfully.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyNotesScreen(),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save note: $e'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Save Note'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getScreenText(
    String title,
    String summary,
    List<String> detailLines,
    String abstractText,
  ) {
    final structuredContent = [
      if (summary.trim().isNotEmpty) 'Summary. ${summary.trim()}',
      if (abstractText.trim().isNotEmpty) 'Abstract. ${abstractText.trim()}',
    ].join('\n\n');

    return buildStructuredText(
      title: title.isNotEmpty ? title : 'Document preview',
      content: structuredContent,
      keyPoints: detailLines,
    );
  }

  void _publishScreenText(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccessibilityProvider>().setScreenTextIfCurrent(context, text);
    });
  }
}
