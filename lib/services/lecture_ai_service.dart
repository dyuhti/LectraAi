import 'package:http/http.dart' as http;
import 'dart:convert';

class LectureAiService {
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _model = 'llama-3.1-70b-versatile';
  static const String _missingKeyMessage =
      'Groq API key missing. Run app with --dart-define';

  /// Generate lecture summary and study notes from transcript
  Future<Map<String, dynamic>> generateLectureSummary(
    String transcript, {
    String? lectureTitle,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(_missingKeyMessage);
    }

    if (transcript.isEmpty) {
      return {
        'summary': 'No transcript provided',
        'keyPoints': [],
        'definitions': [],
      };
    }

    final prompt = '''
Analyze this lecture transcript and provide the following in JSON format:
{
  "summary": "2-3 sentence main topic summary",
  "keyPoints": ["point1", "point2", "point3", "point4", "point5"],
  "definitions": ["term1: definition1", "term2: definition2"],
  "lectureTitle": "suggested lecture title"
}

Lecture Transcript:
$transcript
''';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Extract JSON from markdown code blocks if present
        final jsonMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(content);
        final jsonContent = jsonMatch != null ? jsonMatch.group(1)! : content;
        
        return jsonDecode(jsonContent);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid Groq API key. Please check your credentials.');
      } else {
        throw Exception('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      return _getLocalFallbackSummary(transcript);
    }
  }

  /// Generate quiz questions from lecture
  Future<List<Map<String, dynamic>>> generateQuizFromLecture(
    String transcript,
  ) async {
    if (_apiKey.isEmpty) {
      throw Exception(_missingKeyMessage);
    }

    if (transcript.isEmpty) {
      return [];
    }

    final prompt = '''
Generate 5 multiple choice questions from this lecture transcript.
Return as JSON array:
[
  {
    "question": "question text",
    "options": ["option1", "option2", "option3", "option4"],
    "correctAnswer": 0
  }
]

Transcript:
$transcript
''';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.5,
          'max_tokens': 1200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Extract JSON array
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(content);
        if (jsonMatch != null) {
          return List<Map<String, dynamic>>.from(jsonDecode(jsonMatch.group(0)!));
        }
        return [];
      } else {
        throw Exception('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      return _getLocalFallbackQuiz(transcript);
    }
  }

  /// Generate study guide from lecture
  Future<String> generateStudyGuide(String transcript) async {
    if (_apiKey.isEmpty) {
      throw Exception(_missingKeyMessage);
    }

    if (transcript.isEmpty) {
      return 'No transcript available';
    }

    final prompt = '''
Create a structured study guide from this lecture transcript with:
- **Main Topic**: One-line summary
- **Key Concepts**: 5-7 important concepts
- **Learning Objectives**: What students should learn
- **Important Formulas/Facts**: Any key information
- **Review Questions**: 3 questions for review

Format as markdown with clear sections.

Transcript:
$transcript
''';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      return _getLocalFallbackGuide(transcript);
    }
  }

  // Fallback methods for when API is unavailable
  Map<String, dynamic> _getLocalFallbackSummary(String transcript) {
    final sentences = transcript.split(RegExp(r'[.!?]')).where((s) => s.trim().isNotEmpty).toList();
    final words = transcript.split(RegExp(r'\s+'));
    
    return {
      'summary': sentences.isNotEmpty 
          ? '${sentences.first.trim()}. ${sentences.length > 1 ? sentences[1].trim() : ''}'
          : 'Lecture transcript summary',
      'keyPoints': words
          .where((w) => w.length > 5)
          .toSet()
          .take(5)
          .toList(),
      'definitions': ['Note: Using local fallback. Connect to Groq API for better results.'],
      'lectureTitle': 'Untitled Lecture',
    };
  }

  List<Map<String, dynamic>> _getLocalFallbackQuiz(String transcript) {
    return [
      {
        'question': 'What was the main topic discussed in this lecture?',
        'options': ['Option A', 'Option B', 'Option C', 'Option D'],
        'correctAnswer': 0,
      },
    ];
  }

  String _getLocalFallbackGuide(String transcript) {
    return '''
# Study Guide
## Status: Offline Mode
This is a local fallback version. To get AI-powered study guides, please:
1. Run app with --dart-define=GROQ_API_KEY=...
2. Ensure internet connection
3. Regenerate the study guide

## Your Lecture Content:
${transcript.substring(0, (transcript.length / 3).toInt())}...

## Recommendations:
- Review the transcript multiple times
- Identify key terms and concepts
- Create flashcards for important points
- Practice explaining concepts out loud
''';
  }
}
