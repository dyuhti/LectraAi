class Note {
  final String id;
  final String title;
  final String transcript;
  final String summary;
  final String fileUrl;
  final DateTime createdAt;
  final String userId;
  final String subject;
  final String content;
  final String cleanedText;
  final List<String> keyPoints;
  final List<String> formulas;
  final List<String> examples;

  Note({
    this.id = '',
    required this.title,
    required this.transcript,
    required this.summary,
    this.fileUrl = '',
    required this.createdAt,
    this.userId = '',
    this.subject = 'Document',
    this.content = '',
    this.cleanedText = '',
    this.keyPoints = const [],
    this.formulas = const [],
    this.examples = const [],
  });

  factory Note.fromJson(Map<String, dynamic> data) {
    final createdAt = _parseCreatedAt(data['createdAt']);
    
    return Note(
      id: (data['_id'] ?? data['id'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      transcript: (data['transcript'] ?? data['content'] ?? data['cleanedText'] ?? '').toString(),
      summary: (data['summary'] ?? '').toString(),
      fileUrl: (data['fileUrl'] ?? '').toString(),
      createdAt: createdAt,
      subject: (data['subject'] ?? 'Document').toString(),
      content: (data['content'] ?? '').toString(),
      cleanedText: (data['cleanedText'] ?? '').toString(),
      keyPoints: _readStringList(data['keyPoints']),
      formulas: _readStringList(data['formulas']),
      examples: _readStringList(data['examples']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'userId': userId,
      'title': title,
      'subject': subject,
      'transcript': transcript,
      'content': content,
      'cleanedText': cleanedText,
      'summary': summary,
      'keyPoints': keyPoints,
      'formulas': formulas,
      'examples': examples,
      'fileUrl': fileUrl,
      'createdAt': createdAt.toIso8601String(),
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
      transcript: transcript,
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

  static DateTime _parseCreatedAt(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
