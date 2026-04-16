import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'quiz_results_screen.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  String? selectedAnswer;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

class PracticeQuizScreen extends StatefulWidget {
  const PracticeQuizScreen({Key? key}) : super(key: key);

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  int currentQuestionIndex = 0;
  late PageController _pageController;

  final List<QuizQuestion> questions = [
    QuizQuestion(
      id: 1,
      question: 'What is a linked list?',
      options: [
        'A non-linear data structure',
        'A linear data structure where elements are stored in arrays',
        'A linear data structure where elements are stored in nodes',
        'A data structure with a fixed size',
      ],
      correctAnswer: 'C',
    ),
    QuizQuestion(
      id: 2,
      question: 'What is the time complexity of most operations in a linked list?',
      options: [
        'O(1)',
        'O(log n)',
        'O(n)',
        'O(n log n)',
      ],
      correctAnswer: 'C',
    ),
    QuizQuestion(
      id: 3,
      question: 'What is the main advantage of linked lists?',
      options: [
        'Fast random access',
        'Dynamic size and efficient insertion/deletion',
        'Uses less memory than arrays',
        'Better cache performance',
      ],
      correctAnswer: 'B',
    ),
    QuizQuestion(
      id: 4,
      question: 'Which type of linked list has a pointer to the previous node?',
      options: [
        'Singly linked list',
        'Doubly linked list',
        'Circular linked list',
        'Skip list',
      ],
      correctAnswer: 'B',
    ),
    QuizQuestion(
      id: 5,
      question: 'What is the time complexity for searching in a linked list?',
      options: [
        'O(1)',
        'O(log n)',
        'O(n)',
        'O(n²)',
      ],
      correctAnswer: 'C',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectOption(String option) {
    setState(() {
      questions[currentQuestionIndex].selectedAnswer = option;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitQuiz() {
    int correctCount = 0;
    for (var question in questions) {
      if (question.selectedAnswer == question.correctAnswer) {
        correctCount++;
      }
    }

    Get.off(() => QuizResultsScreen(
          questions: questions,
          correctCount: correctCount,
          totalCount: questions.length,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Practice Quiz',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => currentQuestionIndex = index);
        },
        itemCount: questions.length,
        itemBuilder: (context, index) {
          return _buildQuestionPage(questions[index], index);
        },
      ),
    );
  }

  Widget _buildQuestionPage(QuizQuestion question, int index) {
    const List<String> optionLabels = ['A', 'B', 'C', 'D'];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Number Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Question Text
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // Answer Options
            Column(
              children: List.generate(
                question.options.length,
                (optionIndex) {
                  final optionLabel = optionLabels[optionIndex];
                  final option = question.options[optionIndex];
                  final isSelected =
                      question.selectedAnswer == optionLabel;

                  return GestureDetector(
                    onTap: () => _selectOption(optionLabel),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 2.0 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryLight
                                      .withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.primaryLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                optionLabel,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button (only on last question)
            if (index == questions.length - 1)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      question.selectedAnswer != null ? _submitQuiz : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primaryLight.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Submit Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Navigation Buttons (for other questions)
            if (index != questions.length - 1)
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _previousQuestion,
                          style: AppButtonStyles.primary(radius: 16),
                          child: const Text(
                            'Previous',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (index > 0) const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: AppButtonStyles.primary(radius: 16),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Question Progress
            Center(
              child: Text(
                'Question ${index + 1} of ${questions.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
