import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class EditNoteDialog extends StatefulWidget {
  final Note note;
  final Future<void> Function(Note updatedNote) onSave;

  const EditNoteDialog({
    Key? key,
    required this.note,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<EditNoteDialog> {
  late TextEditingController _summaryController;
  late TextEditingController _keyPointsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController(text: widget.note.summary);
    _keyPointsController = TextEditingController(
      text: widget.note.keyPoints.join('\n'),
    );
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _keyPointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.edit_outlined, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Edit Note'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _summaryController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter summary...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Key Points (one per line)',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keyPointsController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Enter key points, one per line...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: AppButtonStyles.primary(radius: 12),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    debugPrint('[EditNoteDialog] Save button pressed');
    
    final keyPoints = _keyPointsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final updatedNote = Note(
      id: widget.note.id,
      title: widget.note.title,
      transcript: widget.note.transcript,
      content: widget.note.content,
      summary: _summaryController.text,
      cleanedText: widget.note.cleanedText,
      subject: widget.note.subject,
      createdAt: widget.note.createdAt,
      keyPoints: keyPoints,
      formulas: widget.note.formulas,
      examples: widget.note.examples,
    );

    setState(() {
      _isSaving = true;
    });
    debugPrint('Saving started');
    debugPrint('[EditNoteDialog] Loading state set to true');

    try {
      debugPrint('[EditNoteDialog] Calling onSave callback');
      await widget.onSave(updatedNote);
      debugPrint('Saving completed');
      debugPrint('[EditNoteDialog] onSave completed successfully');
      
      if (!mounted) {
        debugPrint('[EditNoteDialog] Widget unmounted, skipping close');
        return;
      }
      Navigator.pop(context);
      debugPrint('[EditNoteDialog] Dialog closed');
    } catch (e, stackTrace) {
      debugPrint('[EditNoteDialog] Error saving note: $e');
      debugPrintStack(stackTrace: stackTrace);
      
      if (!mounted) {
        debugPrint('[EditNoteDialog] Widget unmounted, skipping error snackbar');
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update note: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (!mounted) {
        debugPrint('[EditNoteDialog] Widget unmounted in finally block');
        return;
      }
      
      setState(() {
        _isSaving = false;
      });
      debugPrint('[EditNoteDialog] Loading state set to false');
    }
  }
}
