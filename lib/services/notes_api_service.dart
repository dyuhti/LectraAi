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
              defaultValue: 'http://192.168.0.191:5001',
            );

  final http.Client _client;
  final AuthService _authService;
  final String _baseUrl;

  Future<List<Note>> fetchNotes() async {
    final token = await _requireToken();
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/api/notes'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, 'Failed to load notes'));
    }

    final decoded = _decodeJson(response.body);
    if (decoded is! List) {
      throw Exception('Invalid notes response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Note.fromJson)
        .toList();
  }

  Future<Note> createNote(Note note) async {
    final token = await _requireToken();
    final payload = _normalizeCreatePayload(note);
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/notes'),
          headers: _headers(token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 413) {
      throw Exception('Note is too large to save. Please shorten the transcript and try again.');
    }

    if (response.statusCode != 201) {
      throw Exception(_extractError(response.body, 'Failed to save note'));
    }

    final decoded = _decodeJson(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid note response');
    }

    return Note.fromJson(decoded);
  }

  Future<Note> updateNote(Note note) async {
    final token = await _requireToken();
    final response = await _client
        .put(
          Uri.parse('$_baseUrl/api/notes/${note.id}'),
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

    return Note.fromJson(decoded);
  }

  Future<void> deleteNote(String noteId) async {
    final token = await _requireToken();
    final response = await _client
        .delete(
          Uri.parse('$_baseUrl/api/notes/$noteId'),
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
      print('[FEEDBACK] Name: ${name ?? "Not provided"}');
      print('[FEEDBACK] Email: ${email ?? "Not provided"}');
      print('[FEEDBACK] Feedback length: ${feedback.length} characters');

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

      print('[FEEDBACK] Response status: ${response.statusCode}');
      print('[FEEDBACK] Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorMsg = _extractError(response.body, 'Failed to submit feedback');
        print('[FEEDBACK] ERROR: $errorMsg');
        throw Exception(errorMsg);
      }

      print('[FEEDBACK] SUCCESS: Feedback submitted successfully');
    } catch (e) {
      print('[FEEDBACK] EXCEPTION: $e');
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
      final message = decoded['msg'] ?? decoded['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  Map<String, dynamic> _normalizeCreatePayload(Note note) {
    final raw = note.toJson();
    return {
      ...raw,
      'title': _truncate(raw['title']?.toString() ?? '', 140),
      'summary': _truncate(raw['summary']?.toString() ?? '', 2400),
      'content': _truncate(raw['content']?.toString() ?? '', 50000),
      'cleanedText': _truncate(raw['cleanedText']?.toString() ?? '', 50000),
      'keyPoints': _limitStringList(raw['keyPoints'], maxItems: 20, maxChars: 300),
      'formulas': _limitStringList(raw['formulas'], maxItems: 20, maxChars: 220),
      'examples': _limitStringList(raw['examples'], maxItems: 20, maxChars: 300),
    };
  }

  String _truncate(String value, int maxChars) {
    final cleaned = value.trim();
    if (cleaned.length <= maxChars) {
      return cleaned;
    }
    return cleaned.substring(0, maxChars);
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
