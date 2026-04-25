import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_lecture_notes/services/auth_service.dart';

class ReminderApiService {
  ReminderApiService({
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

  Future<void> createReminder({
    required String title,
    String? description,
    required DateTime reminderDateTime,
    String? noteId,
    String repeat = 'none',
  }) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final token = await _authService.getAuthToken();
    print('[ReminderApiService] Sending POST /api/reminders/create for userId: $userId');
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/reminders/create'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'noteId': noteId,
        'title': title,
        'description': description,
        'reminderDateTime': reminderDateTime.toIso8601String(),
        'repeat': repeat,
      }),
    ).timeout(const Duration(seconds: 10));

    print('[ReminderApiService] Response status: ${response.statusCode}');

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create reminder: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchReminders({
    bool upcoming = false,
    bool completed = false,
  }) async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];

    final token = await _authService.getAuthToken();
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/reminders/$userId?upcoming=$upcoming&completed=$completed'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  Future<void> updateReminder(String id, Map<String, dynamic> updates) async {
    final token = await _authService.getAuthToken();
    final response = await _client.put(
      Uri.parse('$_baseUrl/api/reminders/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to update reminder');
    }
  }

  Future<void> deleteReminder(String id) async {
    final token = await _authService.getAuthToken();
    final response = await _client.delete(
      Uri.parse('$_baseUrl/api/reminders/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete reminder');
    }
  }
}
