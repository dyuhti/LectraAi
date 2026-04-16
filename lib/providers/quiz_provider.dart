import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/models/quiz_question.dart';
import 'package:smart_lecture_notes/services/quiz_ai_service.dart';
import 'package:smart_lecture_notes/services/quiz_local_generator.dart';
import 'package:smart_lecture_notes/services/quiz_repository.dart';

class QuizProvider extends ChangeNotifier {
  QuizProvider({
    QuizRepository? repository,
    QuizAiService? aiService,
    QuizLocalGenerator? localGenerator,
  })  : _repository = repository ?? QuizRepository.instance,
        _aiService = aiService ?? QuizAiService(),
        _localGenerator = localGenerator ?? QuizLocalGenerator();

  final QuizRepository _repository;
  final QuizAiService _aiService;
  final QuizLocalGenerator _localGenerator;

  bool _isLoading = false;
  String? _errorMessage;
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  String _noteTitle = '';
  int _quizCount = 10;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<QuizQuestion> get questions => _questions;
  int get currentIndex => _currentIndex;
  String get noteTitle => _noteTitle;
  int get quizCount => _quizCount;

  QuizQuestion? get currentQuestion {
    if (_questions.isEmpty) return null;
    return _questions[_currentIndex];
  }

  double get progress {
    if (_questions.isEmpty) return 0;
    return (_currentIndex + 1) / _questions.length;
  }

  bool get isComplete =>
      _questions.isNotEmpty &&
      _questions.every((q) => q.userSelectedAnswer != null);

  int get correctCount => _questions
      .where((q) => q.userSelectedAnswer == q.correctAnswer)
      .length;

  Future<void> generateQuiz({
    required String noteTitle,
    required String noteText,
    required int questionCount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _noteTitle = noteTitle;
    _quizCount = questionCount;

    List<QuizQuestion> generated = [];
    String fallbackReason = '';
    var shouldStore = false;

    // ALWAYS try Groq API first
    try {
      print('[QuizProvider] Starting quiz generation...');
      print('[QuizProvider] Calling Groq API...');

      generated = await _aiService.generateQuiz(
        noteText: noteText,
        questionCount: questionCount,
        noteTitle: noteTitle,
      );

      print('[QuizProvider] ✓ Groq API successful!');
      print('[QuizProvider] Generated ${generated.length} questions from Groq API');
      shouldStore = true;
    } catch (error) {
      if (error is GroqApiKeyMissingException) {
        _errorMessage = error.message;
        print('[QuizProvider] ✗ ${error.message}');
      } else {
        print('[QuizProvider] ✗ Groq API failed: $error');
        fallbackReason = error.toString();

        // FALLBACK: Only use local generator if Groq fails
        try {
          print('[QuizProvider] Activating local fallback generator...');
          generated = _localGenerator.generate(
            noteText: noteText,
            questionCount: questionCount,
          );
          print('[QuizProvider] ✓ Local generator created ${generated.length} questions');
          shouldStore = generated.isNotEmpty;
          _errorMessage =
              'Using offline mode (Groq API unavailable). Reason: $fallbackReason';
        } catch (fallbackError) {
          print('[QuizProvider] ✗ Local generator also failed: $fallbackError');
          _errorMessage = 'Failed to generate quiz. Error: $fallbackError';
        }
      }
    } finally {
      if (shouldStore && generated.isNotEmpty) {
        print('[QuizProvider] Storing ${generated.length} questions in repository...');
        _questions = generated;
        _currentIndex = 0;
        _repository.setQuestions(_questions);
        _repository.setNoteTitle(noteTitle);
        _repository.setQuizCount(questionCount);
        print('[QuizProvider] ✓ Quiz generation complete. Ready for practice.');
      } else {
        if (generated.isEmpty && _errorMessage == null) {
          _errorMessage = 'Failed to generate any questions.';
        }
        _questions = [];
        _currentIndex = 0;
      }

      _isLoading = false;
      print('[QuizProvider] Loading stopped');
      notifyListeners();
    }
  }

  void selectAnswer(int questionIndex, int answerIndex) {
    if (questionIndex < 0 || questionIndex >= _questions.length) {
      return;
    }

    final question = _questions[questionIndex];
    _questions[questionIndex] = question.copyWith(
      userSelectedAnswer: answerIndex,
    );
    _repository.setSelectedAnswer(question.id, answerIndex);
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  int finalizeQuiz() {
    final score = correctCount;
    _repository.setScore(score);
    return score;
  }

  void resetQuiz() {
    _isLoading = false;
    _errorMessage = null;
    _questions = [];
    _currentIndex = 0;
    _noteTitle = '';
    _quizCount = 10;
    _repository.clear();
    notifyListeners();
  }
}
