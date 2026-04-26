import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_lecture_notes/models/progress.dart';
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
              defaultValue: 'https://lectraai.onrender.com/api',
            );

  final http.Client _client;
  final AuthService _authService;
  final String _baseUrl;

  Future<DailyProgress> fetchTodayProgress() async {
    final userId = await _authService.getUserId();
    if (userId == null) {
      return DailyProgress.empty();
    }

    try {
      final token = await _authService.getAuthToken();
      final response = await _client.get(
        Uri.parse('$_baseUrl/progress/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('[ProgressApiService] Fetch response: ${response.statusCode}');
      print('[ProgressApiService] Fetch body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DailyProgress.fromJson(data);
      }
      return DailyProgress.empty();
    } catch (e) {
      print('[ProgressApiService] Error fetching progress: $e');
      return DailyProgress.empty();
    }
  }

  Future<List<DailyProgress>> fetchHistory() async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];

    try {
      final token = await _authService.getAuthToken();
      final response = await _client.get(
        Uri.parse('$_baseUrl/progress/history/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DailyProgress.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[ProgressApiService] Error fetching history: $e');
      return [];
    }
  }

  Future<List<DailyProgress>> fetchWeeklyProgress() async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];

    try {
      final token = await _authService.getAuthToken();
      final response = await _client.get(
        Uri.parse('$_baseUrl/dashboard/weekly/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print("Dashboard data: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DailyProgress.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[ProgressApiService] Error fetching weekly dashboard: $e');
      return [];
    }
  }

  Future<void> updateProgress(String type, {int? duration}) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    try {
      final token = await _authService.getAuthToken();
      final response = await _client.post(
        Uri.parse('$_baseUrl/progress/update'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'type': type,
          if (duration != null) 'duration': duration,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('[ProgressApiService] Failed to update progress: ${response.body}');
      }
    } catch (e) {
      print('[ProgressApiService] Error updating progress: $e');
    }
  }

  Future<void> syncDashboard() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    try {
      final token = await _authService.getAuthToken();
      final response = await _client.post(
        Uri.parse('$_baseUrl/dashboard/sync/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print("Sync dashboard response: ${response.body}");
    } catch (e) {
      print('[ProgressApiService] Error syncing dashboard: $e');
    }
  }

  Future<void> storeProgress(int progressScore) async {
    // This is now handled by backend sync, but keeping as a placeholder if needed
    print('[ProgressApiService] storeProgress called with $progressScore (redundant due to backend sync)');
  }

  void dispose() {
    _client.close();
  }
}
