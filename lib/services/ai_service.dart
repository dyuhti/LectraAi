import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // We use 10.0.2.2 as the default for Android Emulators to reach the host machine.
  // Note: Your app.py FastAPI server runs on port 8003 based on your .env
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8003',
  );

  /// Connects to the Gemini backend endpoint to generate structured notes based on mode.
  /// Returns a Map containing 'title', 'content', and 'key_points'.
  Future<Map<String, dynamic>> generateNotes(String text, String mode) async {
    if (text.trim().isEmpty) {
      throw Exception('Text cannot be empty.');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-notes'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'mode': mode,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          
          if (decoded is Map<String, dynamic>) {
            final keyPointsRaw = decoded['key_points'];
            List<String> parsedKeyPoints = [];
            
            if (keyPointsRaw is List) {
              parsedKeyPoints = keyPointsRaw.map((e) => e.toString()).toList();
            } else if (keyPointsRaw is String) {
              parsedKeyPoints = [keyPointsRaw];
            }

            return {
              'title': decoded['title']?.toString() ?? 'Notes',
              'content': decoded['content']?.toString() ?? '',
              'key_points': parsedKeyPoints,
            };
          } else {
            throw const FormatException('Response is not a valid JSON object');
          }
        } catch (e) {
          throw FormatException('Failed to parse JSON response: $e');
        }
      } else {
        // Attempt to parse the exact backend error message
        String errorMessage = 'Server error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (_) {
          // Fallback if not JSON
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        rethrow;
      }
      throw Exception('Network error: Failed to connect to AI service. Ensure backend is running. ($e)');
    }
  }
}
