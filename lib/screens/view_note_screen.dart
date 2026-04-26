import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/providers/note_provider.dart';
import 'package:smart_lecture_notes/screens/edit_note_screen.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/utils/tts_text_builder.dart';
import 'package:smart_lecture_notes/widgets/tts_control_widget.dart';

class ViewNoteScreen extends StatefulWidget {
  final Note note;
  final String? noteTitle;
  final String? categoryName;

  const ViewNoteScreen({
    Key? key,
    required this.note,
    this.noteTitle,
    this.categoryName,
  }) : super(key: key);

  @override
  State<ViewNoteScreen> createState() => _ViewNoteScreenState();
}

class _ViewNoteScreenState extends State<ViewNoteScreen> {
  bool _isDeleting = false;
  Note? _currentNote;

  static const Color _surface = Colors.white;
  static const Color _softSurface = Color(0xFFF7F9FC);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _titleColor = Color(0xFF0F172A);
  static const Color _bodyColor = Color(0xFF334155);
  static const Color _mutedColor = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
  }

  String _heroTag(Note note) {
    final noteId = note.id.trim();
    if (noteId.isNotEmpty) {
      return 'note-$noteId';
    }

    return 'note-${note.title.trim()}-${note.createdAt.millisecondsSinceEpoch}';
  }

  Note? _resolvedNote(List<Note> notes) {
    final current = _currentNote;
    if (current == null) {
      return null;
    }

    final noteId = current.id.trim();
    if (noteId.isNotEmpty) {
      final latestById = notes.where((item) => item.id == noteId).toList();
      if (latestById.isNotEmpty) {
        _currentNote = latestById.first;
        return latestById.first;
      }
    }

    return current;
  }

  String _resolvedContent(Note? note) {
    final content = (note?.content ?? '').trim();
    if (content.isNotEmpty) {
      return content;
    }

    final cleanedText = (note?.cleanedText ?? '').trim();
    if (cleanedText.isNotEmpty) {
      return cleanedText;
    }

    return (note?.transcript ?? '').trim();
  }

  String _screenText(Note? note) {
    final title = note?.title.trim().isNotEmpty == true
        ? note!.title.trim()
        : (widget.noteTitle?.trim().isNotEmpty == true
            ? widget.noteTitle!.trim()
            : 'View Note');
    final summary = (note?.summary ?? '').trim();
    final content = _resolvedContent(note);

    final structuredContent = [
      if (summary.isNotEmpty) 'Summary. $summary',
      if (content.isNotEmpty) 'Content. $content',
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

  Future<void> _openEditScreen(Note note) async {
    if (_isDeleting) {
      return;
    }

    final updatedNote = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(note: note),
      ),
    );

    if (!mounted || updatedNote == null) {
      return;
    }

    setState(() {
      _currentNote = updatedNote;
    });
  }

  Future<void> _confirmDelete() async {
    if (_isDeleting) {
      return;
    }

    final note = _currentNote ?? widget.note;
    if (note == null || note.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete this note.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Expanded(child: Text('Delete Note')),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this note?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: _isDeleting ? null : () => Navigator.pop(dialogContext, true),
              style: AppButtonStyles.primary(radius: 12),
              icon: _isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteNote(note);
    }
  }

  Future<void> _deleteNote(Note note) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await context.read<NoteProvider>().deleteNote(note.id);
      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

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
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1),
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
                  color: AppColors.primaryLight.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
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

  @override
  Widget build(BuildContext context) {
    final latestNotes = context.watch<NoteProvider>().notes;
    final note = _resolvedNote(latestNotes) ?? widget.note;
    final title = note.title.trim().isNotEmpty ? note.title.trim() : 'View Note';
    final subject = note.subject.trim().isNotEmpty ? note.subject.trim() : 'Document';
    final createdAt = note.createdAt;
    final summary = note.summary.trim();
    final content = _resolvedContent(note);
    final ttsText = _screenText(note);
    _publishScreenText(ttsText);

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
          'View Note',
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
            onPressed: _isDeleting ? null : () => _openEditScreen(note),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Delete note',
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                    ),
                  )
                : const Icon(Icons.delete_outline, color: AppColors.primaryDark),
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              children: [
                Hero(
                  tag: _heroTag(note),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _softSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _border, width: 1),
                                ),
                                child: Text(
                                  subject,
                                  style: const TextStyle(
                                    color: _titleColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                MaterialLocalizations.of(context).formatFullDate(createdAt),
                                style: const TextStyle(
                                  color: _mutedColor,
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
                              color: _titleColor,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Full note details',
                            style: TextStyle(
                              color: _mutedColor.withOpacity(0.9),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (summary.isNotEmpty)
                  _buildSectionCard(
                    title: 'Summary',
                    icon: Icons.subject,
                    child: Text(
                      summary,
                      softWrap: true,
                      style: const TextStyle(
                        color: _bodyColor,
                        fontSize: 14,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (summary.isNotEmpty) const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Content',
                  icon: Icons.description_outlined,
                  child: Text(
                    content.isNotEmpty ? content : 'No content available.',
                    softWrap: true,
                    style: const TextStyle(
                      color: _bodyColor,
                      fontSize: 14,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!context.watch<AccessibilityProvider>().isEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TtsControlWidget(text: ttsText),
            ),
        ],
      ),
    );
  }
}