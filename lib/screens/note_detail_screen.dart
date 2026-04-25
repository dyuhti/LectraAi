import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/providers/note_provider.dart';
import 'package:smart_lecture_notes/screens/my_notes_screen.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/widgets/edit_note_dialog.dart';
import 'package:smart_lecture_notes/utils/tts_text_builder.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note? note;
  final String? noteTitle;
  final String? categoryName;

  const NoteDetailScreen({
    Key? key,
    this.note,
    this.noteTitle,
    this.categoryName,
  }) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  bool _isDeleting = false;
  Note? _currentNote;

  static const Color _neutralSurface = Colors.white;
  static const Color _neutralTint = Color(0xFFF4F6FA);
  static const Color _neutralBorder = Color(0xFFE5E7EB);
  static const Color _neutralTitle = Color(0xFF0F172A);
  static const Color _neutralBody = Color(0xFF334155);
  static const Color _neutralMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
  }

  Note? _resolvedNote(BuildContext context) {
    final note = _currentNote;
    if (note == null || note.id.trim().isEmpty) {
      return note;
    }

    final notes = context.watch<NoteProvider>().notes;
    final latest = notes.where((item) => item.id == note.id).toList();
    if (latest.isNotEmpty) {
      _currentNote = latest.first;
      return latest.first;
    }

    return note;
  }

  String getScreenText(Note? note) {
    final title = note?.title ?? widget.noteTitle ?? 'Note Details';
    final summary = (note?.summary ?? '').trim();
    final transcript = (note?.cleanedText.isNotEmpty == true
        ? note?.cleanedText
        : note?.content)
      ?.trim() ??
      '';

    final structuredContent = [
      if (summary.isNotEmpty) 'AI Summary. $summary',
      if (transcript.isNotEmpty) 'Transcript. $transcript',
    ].join('\n\n');

    return buildStructuredText(
      title: title,
      content: structuredContent,
      keyPoints: const [],
    );
  }

  void _publishScreenText(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccessibilityProvider>().setScreenTextIfCurrent(context, text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final note = _resolvedNote(context);
    final title = note?.title ?? widget.noteTitle ?? 'Note Details';
    final subject = note?.subject ?? widget.categoryName ?? 'Document';
    final createdAt = note?.createdAt ?? DateTime.now();
    final summary = (note?.summary ?? '').trim();
    final canDelete = note != null && note.id.trim().isNotEmpty && !_isDeleting;
    final canEdit = note != null && note.id.trim().isNotEmpty;
    _publishScreenText(getScreenText(note));

    final sections = <Widget>[];
    if (summary.isNotEmpty) {
      sections.add(
        _buildSectionCard(
          title: 'AI Summary',
          icon: Icons.subject,
          iconColor: _neutralTitle,
          backgroundColor: _neutralSurface,
          child: Text(
            summary,
            style: const TextStyle(
              color: _neutralBody,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final transcriptText = (note?.cleanedText.isNotEmpty == true
        ? note?.cleanedText
        : note?.content)
      ?.trim() ??
      '';
    if (transcriptText.isNotEmpty) {
      sections.add(
        _buildSectionCard(
          title: 'Transcript',
          icon: Icons.receipt_long,
          iconColor: _neutralTitle,
          backgroundColor: _neutralSurface,
          child: Text(
            transcriptText,
            style: const TextStyle(
              color: _neutralBody,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Note Details',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit note',
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: canEdit ? () => _showEditDialog(context) : null,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Delete note',
            icon: const Icon(Icons.delete_outline, color: AppColors.primaryDark),
            onPressed: canDelete ? () => _confirmDelete(context) : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _neutralTint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _neutralBorder, width: 1),
                ),
                child: Text(
                  subject,
                  style: const TextStyle(
                    color: _neutralTitle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatFullDate(context, createdAt),
                style: const TextStyle(
                  color: _neutralMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _neutralTitle,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          if (sections.isEmpty)
            _buildSectionCard(
              title: 'Summary',
              icon: Icons.subject,
              iconColor: _neutralTitle,
              backgroundColor: _neutralSurface,
              child: const Text(
                'No structured content available.',
                style: TextStyle(
                  color: _neutralBody,
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ...sections.expand(
              (section) => [section, const SizedBox(height: 16)],
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isDeleting ? null : () => _exportPDF(context),
              style: AppButtonStyles.primary(radius: 14),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Export as PDF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.delete_outline, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text('Delete Note'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this note? This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: _isDeleting
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              style: AppButtonStyles.primary(radius: 12),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteNote();
    }
  }

  Future<void> _deleteNote() async {
    final note = _currentNote;
    if (note == null || note.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete this note.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await context.read<NoteProvider>().deleteNote(note.id);
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MyNotesScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete note: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      children: items
          .map(
            (item) => Padding(
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
                      item,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _exportPDF(BuildContext context) async {
    final note = _currentNote;
    if (note == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No note available to export.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF file...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final document = PdfDocument();

      final titleFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        20,
        style: PdfFontStyle.bold,
      );
      final headingFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        13,
        style: PdfFontStyle.bold,
      );
      final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
      final mutedFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

      final title = note.title.trim().isEmpty ? 'Note Details' : note.title.trim();
      final subject = note.subject.trim().isEmpty ? 'Document' : note.subject.trim();
      final summary = note.summary.trim().isEmpty ? 'No summary available.' : note.summary.trim();
      final transcript = note.cleanedText.isNotEmpty == true
          ? note.cleanedText.trim()
          : note.content.trim();

      PdfPage page = document.pages.add();
      const double left = 24;
      const double top = 24;
      final contentWidth = page.getClientSize().width - (left * 2);
      double currentTop = top;

      PdfLayoutResult layoutResult = PdfTextElement(
        text: title,
        font: titleFont,
        brush: PdfSolidBrush(PdfColor(15, 23, 42)),
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(left, currentTop, contentWidth, 40),
        format: PdfLayoutFormat(
          layoutType: PdfLayoutType.paginate,
          breakType: PdfLayoutBreakType.fitPage,
        ),
      ) as PdfLayoutResult;

      page = layoutResult.page;
      currentTop = layoutResult.bounds.bottom + 10;

      layoutResult = PdfTextElement(
        text: 'Subject: $subject',
        font: mutedFont,
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(left, currentTop, contentWidth, 24),
        format: PdfLayoutFormat(
          layoutType: PdfLayoutType.paginate,
          breakType: PdfLayoutBreakType.fitPage,
        ),
      ) as PdfLayoutResult;

      page = layoutResult.page;
      currentTop = layoutResult.bounds.bottom + 18;

      layoutResult = PdfTextElement(
        text: 'AI Summary',
        font: headingFont,
        brush: PdfSolidBrush(PdfColor(15, 23, 42)),
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(left, currentTop, contentWidth, 20),
        format: PdfLayoutFormat(
          layoutType: PdfLayoutType.paginate,
          breakType: PdfLayoutBreakType.fitPage,
        ),
      ) as PdfLayoutResult;

      page = layoutResult.page;
      currentTop = layoutResult.bounds.bottom + 8;

      layoutResult = PdfTextElement(
        text: summary,
        font: bodyFont,
        brush: PdfSolidBrush(PdfColor(51, 65, 85)),
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(left, currentTop, contentWidth, 0),
        format: PdfLayoutFormat(
          layoutType: PdfLayoutType.paginate,
          breakType: PdfLayoutBreakType.fitPage,
        ),
      ) as PdfLayoutResult;

      page = layoutResult.page;
      currentTop = layoutResult.bounds.bottom + 18;

      if (transcript.isNotEmpty) {
        layoutResult = PdfTextElement(
          text: 'Transcript',
          font: headingFont,
          brush: PdfSolidBrush(PdfColor(15, 23, 42)),
        ).draw(
          page: page,
          bounds: Rect.fromLTWH(left, currentTop, contentWidth, 20),
          format: PdfLayoutFormat(
            layoutType: PdfLayoutType.paginate,
            breakType: PdfLayoutBreakType.fitPage,
          ),
        ) as PdfLayoutResult;

        page = layoutResult.page;
        currentTop = layoutResult.bounds.bottom + 8;

        PdfTextElement(
          text: transcript,
          font: bodyFont,
          brush: PdfSolidBrush(PdfColor(51, 65, 85)),
        ).draw(
          page: page,
          bounds: Rect.fromLTWH(left, currentTop, contentWidth, 0),
          format: PdfLayoutFormat(
            layoutType: PdfLayoutType.paginate,
            breakType: PdfLayoutBreakType.fitPage,
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final safeTitle = _sanitizeFileName(title);
      final fileName = '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(p.join(directory.path, fileName));
      await file.writeAsBytes(await document.save(), flush: true);
      document.dispose();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF exported successfully to ${file.path}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _sanitizeFileName(String input) {
    final sanitized = input
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return sanitized.isEmpty ? 'note' : sanitized;
  }

  String _formatFullDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatFullDate(date);
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final note = _currentNote;
    if (note == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => EditNoteDialog(
        note: note,
        onSave: _handleNoteUpdate,
      ),
    );
  }

  Future<void> _handleNoteUpdate(Note updatedNote) async {
    debugPrint('[NoteDetailScreen] Update started for note: ${updatedNote.id}');
    
    try {
      debugPrint('[NoteDetailScreen] Calling provider updateNote');
      await context.read<NoteProvider>().updateNote(updatedNote);
      debugPrint('[NoteDetailScreen] Provider updateNote completed');
      
      if (!mounted) {
        debugPrint('[NoteDetailScreen] Widget unmounted after update');
        return;
      }
      
      setState(() {
        _currentNote = updatedNote;
      });
      debugPrint('[NoteDetailScreen] Current note state updated');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note updated successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[NoteDetailScreen] Error updating note: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow; // Let dialog handle the error
    }
  }
}
