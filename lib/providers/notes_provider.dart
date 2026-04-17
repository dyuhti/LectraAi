import 'package:flutter/foundation.dart';
import 'package:smart_lecture_notes/models/note.dart';

class NotesProvider extends ChangeNotifier {
  final List<Note> _notes = [];

  List<Note> get notes => List.unmodifiable(_notes);

  void addNote(Note note) {
    _notes.insert(0, note); // newest on top
    notifyListeners();
  }
}
