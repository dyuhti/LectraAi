import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'practice_quiz_screen.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class ReviewAnswersScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final int correctCount;

  const ReviewAnswersScreen({
    required this.questions, required this.correctCount, Key? key,
  }) : super(key: key);

  @override
  State<ReviewAnswersScreen> createState() => _ReviewAnswersScreenState();
}

class _ReviewAnswersScreenState extends State<ReviewAnswersScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getOptionLabel(int index) {
    const labels = ['A', 'B', 'C', 'D'];
    return labels[index];
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
          'Review Answers',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You scored ${widget.correctCount} out of ${widget.questions.length} (${((widget.correctCount / widget.questions.length) * 100).toInt()}%)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Questions Review
              Column(
                children: List.generate(
                  widget.questions.length,
                  (index) {
                    final question = widget.questions[index];
                    final isCorrect =
                        question.selectedAnswer == question.correctAnswer;

                    return _buildQuestionReview(
                      index: index,
                      question: question,
                      isCorrect: isCorrect,
                    );
                  },
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => Get.back(),
            style: AppButtonStyles.primary(radius: 16),
            child: const Text(
              'Back to Results',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionReview({
    required int index,
    required QuizQuestion question,
    required bool isCorrect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.primaryLight.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      isCorrect ? Icons.check : Icons.close,
                      color: isCorrect
                          ? AppColors.primary
                          : AppColors.primaryLight,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Options with Highlighting
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: List.generate(
                question.options.length,
                (optionIndex) {
                  final optionLabel = _getOptionLabel(optionIndex);
                  final option = question.options[optionIndex];
                  final isSelectedByUser =
                      question.selectedAnswer == optionLabel;
                  final isCorrectAnswer = question.correctAnswer == optionLabel;

                  Color borderColor = AppColors.border;
                  Color backgroundColor = Colors.white;
                  Color textColor = AppColors.textSecondary;

                  if (isCorrectAnswer) {
                    borderColor = AppColors.primary;
                    backgroundColor =
                        AppColors.primaryLight.withOpacity(0.12);
                    textColor = AppColors.primary;
                  } else if (isSelectedByUser && !isCorrect) {
                    borderColor = AppColors.primaryLight;
                    backgroundColor =
                        AppColors.primaryLight.withOpacity(0.12);
                    textColor = AppColors.primaryLight;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(
                        color: borderColor,
                        width: (isCorrectAnswer || isSelectedByUser) ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: borderColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              optionLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: borderColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (isCorrectAnswer)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
