import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_lecture_notes/models/quiz_question.dart';

class QuizAiService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-70b-versatile';

  Future<List<QuizQuestion>> generateQuiz({
    required String apiKey,
    required String noteText,
    required int questionCount,
    String? noteTitle,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError('Groq API key is required.');
    }

    final prompt = _buildPrompt(
      noteText: noteText,
      questionCount: questionCount,
      noteTitle: noteTitle,
    );
    final retryPrompt = _buildRetryPrompt(
      noteText: noteText,
      questionCount: questionCount,
      noteTitle: noteTitle,
    );

    for (var attempt = 0; attempt < 2; attempt++) {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'temperature': 0.2,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a quiz generator that returns strict JSON only.',
            },
            {
              'role': 'user',
              'content': attempt == 0 ? prompt : retryPrompt,
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        continue;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? [];
      if (choices.isEmpty) {
        continue;
      }

      final content =
          (choices.first as Map<String, dynamic>)['message']?['content']
                  ?.toString() ??
              '';
      final questions = _parseQuestions(content);
      if (questions.isNotEmpty) {
        return questions;
      }
    }

    throw const FormatException('Failed to parse Groq quiz JSON.');
  }

  String _buildPrompt({
    required String noteText,
    required int questionCount,
    String? noteTitle,
  }) {
    final title = noteTitle?.isNotEmpty == true ? 'Title: $noteTitle\n' : '';
    return '${title}Create $questionCount multiple choice questions from the note. '
      'Return ONLY valid JSON with this schema: '
      '{"questions":[{"id":1,"question":"...","options":["A","B","C","D"],"correctAnswer":0}]} '
      'Use 0-based index for correctAnswer. '
      'Note:\n$noteText';
  }

  String _buildRetryPrompt({
    required String noteText,
    required int questionCount,
    String? noteTitle,
  }) {
    final title = noteTitle?.isNotEmpty == true ? 'Title: $noteTitle\n' : '';
    return '${title}Return ONLY strict JSON. No markdown, no extra text. '
      'Schema: {"questions":[{"id":1,"question":"...","options":["A","B","C","D"],"correctAnswer":0}]} '
      'Generate $questionCount questions from:\n$noteText';
  }

  List<QuizQuestion> _parseQuestions(String content) {
    if (content.trim().isEmpty) {
      return [];
    }

    var normalized = content
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    String? jsonString = _extractJson(normalized);
    if (jsonString == null) {
      return [];
    }

    try {
      final dynamic parsed = jsonDecode(jsonString);
      final List<dynamic> rawQuestions;

      if (parsed is List) {
        rawQuestions = parsed;
      } else if (parsed is Map && parsed['questions'] is List) {
        rawQuestions = parsed['questions'] as List<dynamic>;
      } else {
        return [];
      }

      return rawQuestions
          .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String? _extractJson(String input) {
    final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(input);
    final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(input);

    if (objectMatch != null) {
      return objectMatch.group(0);
    }
    if (arrayMatch != null) {
      return arrayMatch.group(0);
    }
    return null;
  }
}
