import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_lecture_notes/models/quiz_question.dart';

class QuizAiService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _missingKeyMessage =
      'Groq API key missing. Run app with --dart-define';

  Future<List<QuizQuestion>> generateQuiz({
    required String noteText,
    required int questionCount,
    String? noteTitle,
  }) async {
    if (_apiKey.isEmpty) {
      throw GroqApiKeyMissingException(_missingKeyMessage);
    }

    if (noteText.trim().isEmpty) {
      throw const FormatException('Cannot generate quiz from empty note text.');
    }

    print('[QuizAiService] Calling Groq API');
    print('[QuizAiService] Endpoint: $_endpoint');
    print('[QuizAiService] Model: $_model');
    print('[QuizAiService] Question count: $questionCount');
    print('[QuizAiService] Note title: ${noteTitle ?? "Not provided"}');

    final prompt = _buildPrompt(
      noteText: noteText,
      questionCount: questionCount,
      noteTitle: noteTitle,
    );
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': 0.7,
        'max_tokens': 2048,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          },
        ],
      }),
    );

    print('[QuizAiService] Response status code: ${response.statusCode}');
    print('[QuizAiService] Raw response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw const FormatException('Groq response missing choices.');
    }

    final content =
        (choices.first as Map<String, dynamic>)['message']?['content']
                ?.toString() ??
            '';

    print('[QuizAiService] Raw content: $content');
    final questions = _parseQuestions(content, questionCount: questionCount);
    print('[QuizAiService] Parsed question count: ${questions.length}');

    if (questions.isEmpty) {
      throw const FormatException('Failed to parse Groq quiz JSON.');
    }

    return questions;
  }

  String _buildPrompt({
    required String noteText,
    required int questionCount,
    String? noteTitle,
  }) {
    final title = noteTitle?.isNotEmpty == true ? 'Title: $noteTitle\n' : '';
    return '${title}Create exactly $questionCount multiple choice questions. '
        'Each question must have 4 options. '
        'Return ONLY raw JSON array starting with [ and ending with ]. '
        'No markdown, no explanation, no extra text. '
        'Schema: [{"id":1,"question":"...","options":["A","B","C","D"],"correctAnswer":0}]. '
        'Use 0-based index for correctAnswer. '
        'Note:\n$noteText';
  }

  List<QuizQuestion> _parseQuestions(
    String content, {
    required int questionCount,
  }) {
    if (content.trim().isEmpty) {
      print('[QuizAiService] Empty content received');
      return [];
    }
    final cleaned = _cleanupContent(content);
    final extracted = _extractJsonSegment(cleaned);
    if (extracted != null) {
      print('[QuizAiService] Cleaned JSON: $extracted');
      final parsed = _parseJsonArray(extracted);
      if (parsed.isNotEmpty) {
        return _finalizeQuestionCount(parsed, questionCount);
      }
    }

    final retryCleaned = _cleanupContent(cleaned);
    final retryExtracted = _extractJsonSegment(retryCleaned);
    if (retryExtracted == null) {
      print('[QuizAiService] Failed to locate JSON array in response');
      return [];
    }

    print('[QuizAiService] Cleaned JSON (retry): $retryExtracted');
    final retryParsed = _parseJsonArray(retryExtracted);
    if (retryParsed.isEmpty) {
      return [];
    }
    return _finalizeQuestionCount(retryParsed, questionCount);
  }

  String _cleanupContent(String input) {
    return input
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();
  }

  String? _extractJsonSegment(String input) {
    final start = input.indexOf('[');
    final end = input.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) {
      return null;
    }
    return input.substring(start, end + 1);
  }

  List<QuizQuestion> _parseJsonArray(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);
      if (parsed is! List) {
        print('[QuizAiService] JSON is not an array');
        return [];
      }

      final questions = <QuizQuestion>[];
      var fallbackId = 1;

      for (final item in parsed) {
        if (item is! Map<String, dynamic>) {
          fallbackId++;
          continue;
        }

        final question = _buildQuestion(item, fallbackId);
        if (question != null) {
          questions.add(question);
        }
        fallbackId++;
      }

      print('[QuizAiService] Valid questions parsed: ${questions.length}');
      return questions;
    } catch (e) {
      print('[QuizAiService] JSON parsing error: $e');
      return [];
    }
  }

  List<QuizQuestion> _finalizeQuestionCount(
    List<QuizQuestion> questions,
    int questionCount,
  ) {
    if (questions.length < questionCount) {
      throw FormatException(
        'Groq returned ${questions.length} questions, expected $questionCount.',
      );
    }
    return questions.take(questionCount).toList();
  }

  QuizQuestion? _buildQuestion(Map<String, dynamic> item, int fallbackId) {
    final question = item['question']?.toString().trim() ?? '';
    if (question.isEmpty) {
      return null;
    }

    final optionsRaw = item['options'];
    if (optionsRaw is! List) {
      return null;
    }

    final options = optionsRaw
        .map((option) => option.toString().trim())
        .where((option) => option.isNotEmpty)
        .toList();

    if (options.length != 4) {
      return null;
    }

    var correctAnswer = _parseInt(item['correctAnswer'], 0);
    if (correctAnswer < 0 || correctAnswer >= options.length) {
      correctAnswer = correctAnswer.clamp(0, options.length - 1);
    }

    final id = _parseInt(item['id'], fallbackId);

    return QuizQuestion(
      id: id,
      question: question,
      options: options,
      correctAnswer: correctAnswer,
    );
  }

  int _parseInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}

class GroqApiKeyMissingException implements Exception {
  GroqApiKeyMissingException(this.message);

  final String message;

  @override
  String toString() => message;
}
