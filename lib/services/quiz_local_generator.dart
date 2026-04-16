import 'dart:math';

import 'package:smart_lecture_notes/models/quiz_question.dart';

class QuizLocalGenerator {
  List<QuizQuestion> generate({
    required String noteText,
    required int questionCount,
  }) {
    final sentences = _splitSentences(noteText);
    final definitions = _extractDefinitions(sentences);
    final keywords = _extractKeywords(noteText);
    final random = Random();
    final questions = <QuizQuestion>[];

    var id = 1;
    for (final definition in definitions) {
      if (questions.length >= questionCount) {
        break;
      }

      final distractors = definitions
          .where((item) => item.term != definition.term)
          .map((item) => item.definition)
          .toList();
      final options = _buildOptions(
        correct: definition.definition,
        pool: distractors.isNotEmpty ? distractors : keywords,
        random: random,
      );

      questions.add(
        QuizQuestion(
          id: id++,
          question: 'What is ${definition.term}?',
          options: options,
          correctAnswer: options.indexOf(definition.definition),
        ),
      );
    }

    while (questions.length < questionCount) {
      final fallback = _buildKeywordQuestion(
        sentences: sentences,
        keywords: keywords,
        random: random,
        id: id++,
      );
      questions.add(fallback);
    }

    return questions.take(questionCount).toList();
  }

  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.length > 20)
        .toList();
  }

  List<_Definition> _extractDefinitions(List<String> sentences) {
    final definitions = <_Definition>[];
    final pattern = RegExp(r'^(.+?)\s+(is|are)\s+(.+?)([.?!]|$)');

    for (final sentence in sentences) {
      final match = pattern.firstMatch(sentence);
      if (match == null) continue;

      final term = match.group(1)?.trim() ?? '';
      final definition = match.group(3)?.trim() ?? '';
      if (term.length < 3 || definition.length < 8) continue;
      if (term.split(' ').length > 5) continue;

      definitions.add(_Definition(term: term, definition: definition));
    }

    return definitions;
  }

  List<String> _extractKeywords(String text) {
    final words = RegExp(r'[A-Za-z][A-Za-z\-]{3,}')
        .allMatches(text)
        .map((match) => match.group(0)!.toLowerCase())
        .toSet()
        .toList();
    words.shuffle(Random());
    return words.take(30).map(_capitalize).toList();
  }

  QuizQuestion _buildKeywordQuestion({
    required List<String> sentences,
    required List<String> keywords,
    required Random random,
    required int id,
  }) {
    final sentence = sentences.isNotEmpty
        ? sentences[random.nextInt(sentences.length)]
        : 'This concept is an important part of the lecture.';
    final clueWords = sentence.split(' ').take(12).join(' ');

    final options = <String>[];
    final keywordPool = keywords.isNotEmpty
        ? keywords
        : ['Concept', 'Definition', 'Theory', 'Principle'];

    while (options.length < 4) {
      final option = keywordPool[random.nextInt(keywordPool.length)];
      if (!options.contains(option)) {
        options.add(option);
      }
    }

    final correctAnswer = random.nextInt(options.length);

    return QuizQuestion(
      id: id,
      question: 'Which term best fits: "$clueWords..."?',
      options: options,
      correctAnswer: correctAnswer,
    );
  }

  List<String> _buildOptions({
    required String correct,
    required List<String> pool,
    required Random random,
  }) {
    final options = <String>[correct];
    final available = pool.where((item) => item != correct).toList();
    available.shuffle(random);

    for (final option in available) {
      if (options.length >= 4) break;
      if (!options.contains(option)) {
        options.add(option);
      }
    }

    const fallbackOptions = [
      'Not applicable',
      'None of the above',
      'Insufficient data',
      'Not mentioned',
    ];
    var fallbackIndex = 0;
    while (options.length < 4 && fallbackIndex < fallbackOptions.length) {
      final fallback = fallbackOptions[fallbackIndex++];
      if (!options.contains(fallback)) {
        options.add(fallback);
      }
    }

    options.shuffle(random);
    return options;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _Definition {
  final String term;
  final String definition;

  const _Definition({required this.term, required this.definition});
}
