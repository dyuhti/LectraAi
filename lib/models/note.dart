import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String subject;
  final String content;
  final String summary;
  final List<String> keyPoints;
  final List<String> formulas;
  final List<String> examples;
  final String cleanedText;
  final DateTime createdAt;

  Note({
    this.id = '',
    required this.title,
    required this.content,
    required this.summary,
    required this.cleanedText,
    this.subject = 'Document',
    required this.createdAt,
    this.keyPoints = const [],
    this.formulas = const [],
    this.examples = const [],
  });

  factory Note.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    final cleanedText = (data['cleanedText'] ?? '').toString();
    final summary = (data['summary'] ?? '').toString();
    final content = (data['content'] ?? summary ?? cleanedText).toString();
    final rawKeyPoints = _readStringList(data['keyPoints']);
    final rawFormulas = _readStringList(data['formulas']);
    final rawExamples = _readStringList(data['examples']);
    final sourceText = _sourceText(summary, cleanedText, content);

    return Note(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      summary: summary,
      cleanedText: cleanedText,
      content: content,
      subject: (data['subject'] ?? 'Document').toString(),
      createdAt: createdAt,
      keyPoints: rawKeyPoints.isEmpty
          ? _extractKeyPoints(summary.isNotEmpty ? summary : sourceText)
          : rawKeyPoints,
      formulas: rawFormulas.isEmpty
          ? _extractFormulas(sourceText)
          : rawFormulas,
      examples: rawExamples.isEmpty
          ? _extractExamples(sourceText)
          : rawExamples,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'summary': summary,
      'keyPoints': keyPoints,
      'formulas': formulas,
      'examples': examples,
      'subject': subject,
      'content': content,
      'cleanedText': cleanedText,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Note withGeneratedStructure() {
    final sourceText = _sourceText(summary, cleanedText, content);
    final generatedKeyPoints = keyPoints.isNotEmpty
        ? keyPoints
        : _extractKeyPoints(summary.isNotEmpty ? summary : sourceText);
    final generatedFormulas = formulas.isNotEmpty
        ? formulas
        : _extractFormulas(sourceText);
    final generatedExamples = examples.isNotEmpty
        ? examples
        : _extractExamples(sourceText);

    return Note(
      id: id,
      title: title,
      subject: subject,
      content: content,
      summary: summary,
      cleanedText: cleanedText,
      createdAt: createdAt,
      keyPoints: generatedKeyPoints,
      formulas: generatedFormulas,
      examples: generatedExamples,
    );
  }

  static String _sourceText(
    String summary,
    String cleanedText,
    String content,
  ) {
    if (summary.trim().isNotEmpty) {
      return summary;
    }
    if (cleanedText.trim().isNotEmpty) {
      return cleanedText;
    }
    return content;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is Iterable) {
      return _uniqueList(
        value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList(),
      );
    }
    return [];
  }

  static List<String> _extractKeyPoints(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return [];
    }

    final lines = normalized
        .split(RegExp(r'\n+'))
        .map((line) => _stripBullet(line))
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length > 1) {
      return _uniqueList(lines, maxItems: 6);
    }

    final sentences = _splitIntoSentences(normalized);
    return _uniqueList(sentences, maxItems: 6);
  }

  static List<String> _extractFormulas(String text) {
    final sentences = _splitIntoSentences(text);
    final formulaPattern = RegExp(r'[A-Za-z0-9]\s*(=|<=|>=|==|->|=>|\+|\*|/|\^)\s*[A-Za-z0-9]');
    final matches = sentences.where((sentence) => formulaPattern.hasMatch(sentence)).toList();
    return _uniqueList(matches, maxItems: 6);
  }

  static List<String> _extractExamples(String text) {
    final sentences = _splitIntoSentences(text);
    final examplePattern = RegExp(
      r'\b(for example|for instance|e\.g\.|such as|example)\b',
      caseSensitive: false,
    );
    final matches = sentences.where((sentence) => examplePattern.hasMatch(sentence)).toList();
    return _uniqueList(matches, maxItems: 6);
  }

  static List<String> _splitIntoSentences(String text) {
    final normalized = text
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return [];
    }
    final parts = normalized.split(RegExp(r'(?<=[.!?])\s+'));
    return parts.map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
  }

  static String _stripBullet(String line) {
    final cleaned = line.trim();
    return cleaned.replaceFirst(RegExp(r'^(\d+[\).\s]+|[-*]\s+)'), '').trim();
  }

  static List<String> _uniqueList(List<String> items, {int maxItems = 6}) {
    final unique = <String>[];
    for (final item in items) {
      if (item.isEmpty) {
        continue;
      }
      if (!unique.contains(item)) {
        unique.add(item);
      }
      if (unique.length >= maxItems) {
        break;
      }
    }
    return unique;
  }
}
