import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_lecture_notes/models/study_dashboard.dart';
import 'package:smart_lecture_notes/services/auth_service.dart';

class ProgressApiService {
  ProgressApiService({
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

  Future<StudyDashboardData> fetchTodayProgress() async {
    final userId = await _authService.getUserId();
    if (userId == null) {
      return StudyDashboardData.empty();
    }

    try {
      final token = await _authService.getAuthToken();
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/progress/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('[ProgressApiService] Fetch response: ${response.statusCode}');
      print('[ProgressApiService] Fetch body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StudyDashboardData.fromJson(data);
      }
      return StudyDashboardData.empty();
    } catch (e) {
      print('[ProgressApiService] Error fetching progress: $e');
      return StudyDashboardData.empty();
    }
  }

  Future<List<StudyDashboardData>> fetchHistory() async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];

    try {
      final token = await _authService.getAuthToken();
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/progress/history/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => StudyDashboardData.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[ProgressApiService] Error fetching history: $e');
      return [];
    }
  }

  Future<void> updateAudioProgress() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    try {
      final token = await _authService.getAuthToken();
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/audio/process'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('[ProgressApiService] Failed to update audio progress: ${response.body}');
      }
    } catch (e) {
      print('[ProgressApiService] Error updating audio progress: $e');
    }
  }

  Future<void> updateQuizProgress() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    try {
      final token = await _authService.getAuthToken();
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/quiz/generate'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('[ProgressApiService] Failed to update quiz progress: ${response.body}');
      }
    } catch (e) {
      print('[ProgressApiService] Error updating quiz progress: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
