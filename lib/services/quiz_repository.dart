import 'package:smart_lecture_notes/models/quiz_question.dart';

class QuizRepository {
  QuizRepository._();

  static final QuizRepository instance = QuizRepository._();

  List<QuizQuestion> _questions = [];
  Map<int, int> _selectedAnswers = {};
  int _score = 0;
  String _noteTitle = '';
  int _quizCount = 0;

  List<QuizQuestion> get questions => _questions;
  Map<int, int> get selectedAnswers => _selectedAnswers;
  int get score => _score;
  String get noteTitle => _noteTitle;
  int get quizCount => _quizCount;

  void setQuestions(List<QuizQuestion> questions) {
    _questions = questions;
    _selectedAnswers = {};
    _score = 0;
  }

  void setSelectedAnswer(int questionId, int answerIndex) {
    _selectedAnswers[questionId] = answerIndex;
  }

  void setScore(int score) {
    _score = score;
  }

  void setNoteTitle(String title) {
    _noteTitle = title;
  }

  void setQuizCount(int count) {
    _quizCount = count;
  }

  void clear() {
    _questions = [];
    _selectedAnswers = {};
    _score = 0;
    _noteTitle = '';
    _quizCount = 0;
  }
}
