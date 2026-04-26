import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/services/auth_service.dart';

class NotesApiService {
  NotesApiService({
    http.Client? client,
    AuthService? authService,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _authService = authService ?? AuthService(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'NOTES_BASE_URL',
              defaultValue: 'https://lectraai.onrender.com/api',
            );

  final http.Client _client;
  final AuthService _authService;
  final String _baseUrl;

  Future<List<Note>> fetchNotes() async {
    final token = await _requireToken();
    final userId = await _authService.getUserId();
    if (userId == null || userId.trim().isEmpty) {
      throw Exception('User not authenticated. Please log in.');
    }

    final endpoints = <Uri>[
      Uri.parse('$_baseUrl/notes/${userId.trim()}'),
      Uri.parse('$_baseUrl/notes'),
    ];

    Exception? lastError;
    for (final endpoint in endpoints) {
      final response = await _client
          .get(
            endpoint,
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        lastError = Exception(_extractError(response.body, 'Failed to load notes'));
        continue;
      }

      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, 'Failed to load notes'));
      }

      final decoded = _decodeJson(response.body);
      final notesList = _extractNotesList(decoded);
      if (notesList == null) {
        throw Exception('Invalid notes response');
      }

      return notesList
        .whereType<Map<String, dynamic>>()
        .map(Note.fromJson)
        .toList();
    }

    throw lastError ?? Exception('Failed to load notes');
  }

  Future<Note> createNote(Note note) async {
    final token = await _requireToken();
    
    final payload = {
      'userId': note.userId,
      'title': _truncate(note.title, 140),
      'transcript': _truncate(note.transcript, 50000),
      'summary': _truncate(note.summary, 2400),
      'fileUrl': note.fileUrl,
    };

    print('[NotesApiService] Sending POST /api/notes/save for userId: ${payload['userId']}');
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/notes/save'),
          headers: _headers(token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));
    
    print('[NotesApiService] Response status: ${response.statusCode}');

    if (response.statusCode == 413) {
      throw Exception('Note is too large to save. Please shorten the transcript and try again.');
    }

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_extractError(response.body, 'Failed to save note'));
    }

    final decoded = _decodeJson(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid note response');
    }

    if (decoded.containsKey('data')) {
      return Note.fromJson(decoded['data']);
    }

    return Note.fromJson(decoded);
  }

  Future<Note> updateNote(Note note) async {
    final token = await _requireToken();
    final response = await _client
        .put(
          Uri.parse('$_baseUrl/notes/${note.id}'),
          headers: _headers(token),
          body: jsonEncode(note.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, 'Failed to update note'));
    }

    final decoded = _decodeJson(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid note response');
    }

    if (decoded.containsKey('data')) {
      return Note.fromJson(decoded['data']);
    }

    return Note.fromJson(decoded);
  }

  Future<void> deleteNote(String noteId) async {
    final token = await _requireToken();
    final response = await _client
        .delete(
          Uri.parse('$_baseUrl/notes/$noteId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, 'Failed to delete note'));
    }
  }

  Future<void> submitFeedback({
    required String feedback,
    String? name,
    String? email,
    String? userId,
  }) async {
    try {
      print('[FEEDBACK] Submitting feedback to: $_baseUrl/feedback');
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/feedback'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name ?? '',
              'email': email ?? '',
              'feedback': feedback,
              'userId': userId ?? '',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, 'Failed to submit feedback'));
      }
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<String> _requireToken() async {
    final token = await _authService.getAuthToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('User not authenticated. Please log in.');
    }
    return token.trim();
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _extractError(String body, String fallback) {
    final decoded = _decodeJson(body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'] ?? decoded['msg'] ?? decoded['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  String _truncate(String value, int maxChars) {
    final cleaned = value.trim();
    if (cleaned.length <= maxChars) {
      return cleaned;
    }
    return cleaned.substring(0, maxChars);
  }

  List<dynamic>? _extractNotesList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        return data;
      }
    }

    return null;
  }

  List<String> _limitStringList(
    dynamic value, {
    required int maxItems,
    required int maxChars,
  }) {
    if (value is! Iterable) {
      return const <String>[];
    }

    return value
        .map((item) => _truncate(item.toString(), maxChars))
        .where((item) => item.isNotEmpty)
        .take(maxItems)
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
