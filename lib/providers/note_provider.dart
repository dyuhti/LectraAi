import 'package:flutter/foundation.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/services/notes_api_service.dart';

class NoteProvider extends ChangeNotifier {
  NoteProvider({NotesApiService? notesService})
      : _notesService = notesService ?? NotesApiService() {
    loadNotes();
  }

  final NotesApiService _notesService;
  final List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  List<Note> get notes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final notes = await _notesService.fetchNotes();
      _notes
        ..clear()
        ..addAll(notes);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Note> createNote(Note note) async {
    final created = await _notesService.createNote(note);
    _notes.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<void> updateNote(Note updatedNote) async {
    debugPrint('Saving started');
    debugPrint('[NoteProvider] updateNote called for: ${updatedNote.id}');

    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index == -1) {
      debugPrint('[NoteProvider] Note not found in local list');
      return;
    }

    final originalNote = _notes[index];
    _notes[index] = updatedNote;
    notifyListeners();

    try {
      final saved = await _notesService.updateNote(updatedNote);
      _notes[index] = saved;
      debugPrint('Saving completed');
      notifyListeners();
    } catch (e) {
      _notes[index] = originalNote;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index == -1) {
      return;
    }

    final removed = _notes.removeAt(index);
    notifyListeners();

    try {
      await _notesService.deleteNote(noteId);
    } catch (e) {
      _notes.insert(index, removed);
      notifyListeners();
      rethrow;
    }
  }
}
