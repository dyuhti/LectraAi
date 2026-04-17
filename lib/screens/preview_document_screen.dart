import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/providers/document_provider.dart';
import 'package:smart_lecture_notes/providers/notes_provider.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class PreviewDocumentScreen extends StatefulWidget {
  const PreviewDocumentScreen({Key? key}) : super(key: key);

  @override
  State<PreviewDocumentScreen> createState() => _PreviewDocumentScreenState();
}

class _PreviewDocumentScreenState extends State<PreviewDocumentScreen> {
  /// Convert raw OCR text into structured, readable notes.
  static String structureText(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'\n(?=[a-z])'), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    if (cleaned.isEmpty) {
      return '';
    }

    final words = cleaned.split(' ');
    final buffer = StringBuffer();
    buffer.writeln('Document Summary');
    buffer.writeln('');

    String? currentSection;
    final bulletWords = <String>[];

    void flushBullet() {
      if (bulletWords.isEmpty) {
        return;
      }
      buffer.writeln('- ${bulletWords.join(' ')}');
      bulletWords.clear();
    }

    void startSection(String title) {
      if (currentSection == title) {
        return;
      }
      flushBullet();
      buffer.writeln('');
      buffer.writeln(title);
      currentSection = title;
    }

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final lower = word.toLowerCase();

      if (lower.contains('name')) {
        startSection('Patient Details');
      } else if (lower.contains('date')) {
        startSection('Date Information');
      } else if (lower.contains('type')) {
        startSection('Surgery Details');
      } else if (lower.contains('flow')) {
        startSection('Parameters');
      }

      if (word.endsWith(':') && i + 1 < words.length) {
        flushBullet();
        final key = word.substring(0, word.length - 1);
        final value = words[i + 1];
        buffer.writeln('- $key: $value');
        i += 1;
        continue;
      }

      bulletWords.add(word);

      if (bulletWords.length >= 10 || word.endsWith('.') || word.endsWith(';')) {
        flushBullet();
      }
    }

    flushBullet();
    return buffer.toString().trim();
  }

  static String formatSummary(String text) {
    return text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  List<Widget> _buildStructuredWidgets(String structuredText) {
    final lines = structuredText.split('\n');
    final widgets = <Widget>[];
    var hasContent = false;

    for (var i = 0; i < lines.length; i++) {
      if (i == 0) {
        // Title is rendered separately.
        continue;
      }

      final line = lines[i].trim();
      if (line.isEmpty) {
        if (hasContent) {
          widgets.add(const SizedBox(height: 10));
        }
        continue;
      }

      hasContent = true;

      if (_isSectionHeader(line)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Row(
              children: [
                Icon(
                  _iconForSection(line),
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  line,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      if (line.startsWith('- ')) {
        final bulletText = line.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bulletText,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  static bool _isSectionHeader(String line) {
    return line == 'Patient Details' ||
        line == 'Date Information' ||
        line == 'Surgery Details' ||
        line == 'Parameters' ||
        line == 'Document Summary';
  }

  static IconData _iconForSection(String line) {
    switch (line) {
      case 'Patient Details':
        return Icons.person_outline;
      case 'Date Information':
        return Icons.calendar_today_outlined;
      case 'Surgery Details':
        return Icons.local_hospital_outlined;
      case 'Parameters':
        return Icons.tune_outlined;
      case 'Document Summary':
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentProvider = context.watch<DocumentProvider>();
    final summary = documentProvider.summary.trim();
    final extractedText = documentProvider.extractedText.trim();
    final structuredText = structureText(extractedText);
    final formattedSummary =
        summary.isEmpty ? '' : formatSummary(summary);
    final noteTitle = structuredText.isEmpty
        ? 'Document Summary'
        : structuredText.split('\n').first.trim();

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
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE6FF)),
              ),
              child: structuredText.isEmpty
                  ? const Text(
                      'No extracted text available.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF1E293B),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildStructuredWidgets(structuredText),
                    ),
            ),
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
                onPressed: () {
                  if (structuredText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No extracted text to save.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  final title = structuredText.split('\n').first.trim();
                  final note = Note(
                    title: title.isEmpty ? 'Document Summary' : title,
                    subject: 'Document',
                    content: structuredText,
                    summary: formattedSummary.isEmpty
                        ? 'Summary unavailable.'
                        : formattedSummary,
                    createdAt: DateTime.now(),
                  );

                  Provider.of<NotesProvider>(context, listen: false).addNote(note);

                  Navigator.pushReplacementNamed(context, '/notes');
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
}
