import 'dart:convert';

import 'package:http/http.dart' as http;

class TranscriptionApiService {
  TranscriptionApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'TRANSCRIBE_BASE_URL',
              defaultValue: 'http://192.168.0.191:8001',
            );

  final http.Client _client;
  final String _baseUrl;

  Future<String> transcribeAudio(String filePath) async {
    try {
      print('[API] Sending audio file: $filePath');
      print('[API] Backend URL: $_baseUrl/transcribe');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/transcribe'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      print('[API] Multipart request created, sending...');
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      print('[API] Response status: ${response.statusCode}');
      print('[API] Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('[API] ERROR: Transcription failed with status ${response.statusCode}');
        throw Exception('Transcription failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        print('[API] ERROR: Invalid response format');
        throw Exception('Invalid transcription response');
      }

      final text = data['text'] ?? '';
      if (text.isEmpty) {
        print('[API] WARNING: Empty transcription returned');
      } else {
        print('[API] SUCCESS: Transcribed text: $text');
      }

      return text;
    } catch (e) {
      print('[API] EXCEPTION: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processTranscript(String text) async {
    try {
      print('[API] Processing transcript length: ${text.length}');
      print('[API] Backend URL: $_baseUrl/process-transcript');

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/process-transcript'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 60));

      print('[API] Response status: ${response.statusCode}');
      print('[API] Response body: ${response.body}');

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid processing response');
      }

      if (response.statusCode != 200) {
        final errorMessage = data['error'] ?? 'Transcript processing failed';
        throw Exception(errorMessage);
      }

      return data;
    } catch (e) {
      print('[API] PROCESS TRANSCRIPT EXCEPTION: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
