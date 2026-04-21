import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/providers/note_provider.dart';
import 'package:smart_lecture_notes/screens/my_notes_screen.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/widgets/edit_note_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
  }

  @override
  Widget build(BuildContext context) {
    final note = _currentNote;
    final title = note?.title ?? widget.noteTitle ?? 'Note Details';
    final subject = note?.subject ?? widget.categoryName ?? 'Document';
    final createdAt = note?.createdAt ?? DateTime.now();
    final summary = (note?.summary ?? '').trim();
    final keyPoints = note?.keyPoints ?? const [];
    final formulas = note?.formulas ?? const [];
    final examples = note?.examples ?? const [];
    final canDelete = note != null && note.id.trim().isNotEmpty && !_isDeleting;
    final canEdit = note != null && note.id.trim().isNotEmpty;

    final sections = <Widget>[];
    if (summary.isNotEmpty) {
      sections.add(
        _buildSectionCard(
          title: 'Summary',
          icon: Icons.subject,
          iconColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight.withOpacity(0.08),
          child: Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (keyPoints.isNotEmpty) {
      sections.add(
        _buildSectionCard(
          title: 'Key Points',
          icon: Icons.lightbulb,
          iconColor: const Color(0xFFF59E0B),
          backgroundColor: const Color(0xFFFFF7E6),
          child: _buildBulletList(keyPoints),
        ),
      );
    }

    if (formulas.isNotEmpty) {
      sections.add(
        _buildSectionCard(
          title: 'Formulas',
          icon: Icons.calculate,
          iconColor: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFFF3F4FF),
          child: _buildFormulaList(formulas),
        ),
      );
    }

    if (examples.isNotEmpty) {
      sections.add(
        _buildSectionCard(
          title: 'Examples',
          icon: Icons.science,
          iconColor: const Color(0xFF10B981),
          backgroundColor: const Color(0xFFECFDF5),
          child: _buildBulletList(examples),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
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
                  color: AppColors.primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subject,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatFullDate(context, createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
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
              color: AppColors.primary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          if (sections.isEmpty)
            _buildSectionCard(
              title: 'Summary',
              icon: Icons.subject,
              iconColor: AppColors.primary,
              backgroundColor: AppColors.primaryLight.withOpacity(0.08),
              child: const Text(
                'No structured content available.',
                style: TextStyle(
                  color: Color(0xFF334155),
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

  Widget _buildFormulaList(List<String> items) {
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                item,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _exportPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF file...'),
        duration: Duration(seconds: 2),
      ),
    );
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
