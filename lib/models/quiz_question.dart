class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final int? userSelectedAnswer;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.userSelectedAnswer,
  });

  QuizQuestion copyWith({
    int? id,
    String? question,
    List<String>? options,
    int? correctAnswer,
    int? userSelectedAnswer,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      userSelectedAnswer: userSelectedAnswer ?? this.userSelectedAnswer,
    );
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>? ?? [])
        .map((option) => option.toString())
        .toList();
    final correctAnswerRaw = json['correctAnswer'];
    final correctAnswer = correctAnswerRaw is int
      ? correctAnswerRaw
      : int.tryParse(correctAnswerRaw.toString()) ?? 0;

    final userSelectedRaw = json['userSelectedAnswer'];
    final userSelectedAnswer = userSelectedRaw == null
        ? null
        : userSelectedRaw is int
            ? userSelectedRaw
            : int.tryParse(userSelectedRaw.toString());

    final maxIndex = options.isEmpty ? 0 : options.length - 1;

    return QuizQuestion(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      question: json['question']?.toString() ?? '',
      options: options,
        correctAnswer: options.isEmpty
          ? 0
          : correctAnswer.clamp(0, maxIndex).toInt(),
      userSelectedAnswer: userSelectedAnswer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'userSelectedAnswer': userSelectedAnswer,
    };
  }
}
