import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/services/auth_service.dart';

class NotesFirestoreService {
  NotesFirestoreService({
    FirebaseFirestore? firestore,
    AuthService? authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  Future<void> saveNote(Note note) async {
    final userId = await _authService.getUserId();
    if (userId == null || userId.trim().isEmpty) {
      throw Exception('User not authenticated. Please log in.');
    }

    final structuredNote = note.withGeneratedStructure();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .add(structuredNote.toFirestore());
  }

  Future<void> deleteNote(String noteId) async {
    final userId = await _authService.getUserId();
    if (userId == null || userId.trim().isEmpty) {
      throw Exception('User not authenticated. Please log in.');
    }
    if (noteId.trim().isEmpty) {
      throw Exception('Missing note id.');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  Stream<List<Note>> streamNotes() async* {
    final userId = await _authService.getUserId();
    if (userId == null || userId.trim().isEmpty) {
      yield* Stream.error('User not authenticated. Please log in.');
      return;
    }

    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Note.fromFirestore(doc))
              .toList(),
        );
  }
}
