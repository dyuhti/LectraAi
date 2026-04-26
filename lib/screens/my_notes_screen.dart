import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/providers/note_provider.dart';
import 'package:smart_lecture_notes/screens/note_detail_screen.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/widgets/tts_control_widget.dart';
import 'package:smart_lecture_notes/utils/tts_text_builder.dart';

class MyNotesScreen extends StatefulWidget {
  const MyNotesScreen({Key? key}) : super(key: key);

  @override
  State<MyNotesScreen> createState() => _MyNotesScreenState();
}

class _MyNotesScreenState extends State<MyNotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterNotes);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NoteProvider>().loadNotes();
    });
  }

  void _filterNotes() {
    setState(() {
      _query = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'My Notes',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primaryLight,
                ),
                filled: true,
                fillColor: AppColors.primaryLight.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Consumer<NoteProvider>(
              builder: (context, notesProvider, _) {
                final notes = notesProvider.notes;
                final filteredNotes = _query.isEmpty
                    ? notes
                    : notes
                        .where((note) =>
                            note.title.toLowerCase().contains(_query) ||
                            note.summary.toLowerCase().contains(_query))
                        .toList();

                return filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 64,
                              color: AppColors.primaryLight.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No notes found',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Create your first note'
                                  : 'Try different search terms',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          return _buildNoteCard(filteredNotes[index]);
                        },
                      );
              },
            ),
          ),
          if (!context.watch<AccessibilityProvider>().isEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TtsControlWidget(
                text: _getScreenText(),
              ),
            ),
        ],
      ),
    );
  }

  String _getScreenText() {
    final notes = context.read<NoteProvider>().notes;
    final filteredNotes = _query.isEmpty
        ? notes
        : notes
            .where((note) =>
                note.title.toLowerCase().contains(_query) ||
                note.summary.toLowerCase().contains(_query))
            .toList();

    if (filteredNotes.isEmpty) {
      return buildStructuredText(
        title: 'My Notes',
        content: _query.isEmpty
            ? 'No notes yet. Create your first note.'
            : 'No notes found for \"$_query\".',
        keyPoints: const [],
      );
    }

    final titles = filteredNotes.take(3).map((note) => note.title).toList();
    return buildStructuredText(
      title: 'My Notes',
      content: '${filteredNotes.length} notes available. Browse and open a note to see summary.',
      keyPoints: titles,
    );
  }

  Widget _buildNoteCard(Note note) {
    final summaryText = note.summary.trim().isEmpty
        ? 'Summary unavailable.'
        : note.summary.trim().replaceAll('\n', ' ');
    final createdDate = MaterialLocalizations.of(context)
        .formatMediumDate(note.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoteDetailScreen(note: note),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  createdDate,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              summaryText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
