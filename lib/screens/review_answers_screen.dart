import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/models/quiz_question.dart';
import 'package:smart_lecture_notes/providers/quiz_provider.dart';
import 'package:smart_lecture_notes/theme/quiz_theme.dart';
import 'package:smart_lecture_notes/widgets/quiz_option_tile.dart';

class ReviewAnswersScreen extends StatelessWidget {
  const ReviewAnswersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final total = provider.questions.length;
    final correct = provider.correctCount;

    return Scaffold(
      backgroundColor: QuizColors.softBackground,
      appBar: AppBar(
        backgroundColor: QuizColors.softBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: QuizColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Review Answers',
          style: TextStyle(
            color: QuizColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuizColors.infoBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: QuizColors.borderLight, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: QuizColors.navy, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You scored $correct out of $total (${_percentage(correct, total)}%)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: QuizColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(provider.questions.length, (index) {
            final question = provider.questions[index];
            return _QuestionReviewCard(
              index: index,
              question: question,
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: BoxDecoration(
            color: QuizColors.cardWhite,
            boxShadow: [
              BoxShadow(
                color: QuizColors.shadowColor.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: QuizColors.successButton,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Back to Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.index,
    required this.question,
  });

  final int index;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final isCorrect = question.userSelectedAnswer == question.correctAnswer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuizColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuizColors.borderLight, width: 1.4),
        boxShadow: QuizShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCorrect
                      ? QuizColors.correctBg
                      : QuizColors.wrongBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCorrect
                        ? QuizColors.correctBorder
                        : QuizColors.wrongBorder,
                  ),
                ),
                child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  color: isCorrect
                      ? QuizColors.correctBorder
                      : QuizColors.wrongBorder,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: QuizColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: QuizColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(question.options.length, (optionIndex) {
            final optionLabel = String.fromCharCode(65 + optionIndex);
            final isCorrectAnswer = optionIndex == question.correctAnswer;
            final isSelected = optionIndex == question.userSelectedAnswer;
            final state = isCorrectAnswer
                ? QuizOptionState.correct
                : isSelected
                    ? QuizOptionState.wrongSelected
                    : QuizOptionState.neutral;

            return QuizOptionTile(
              label: optionLabel,
              text: question.options[optionIndex],
              state: state,
              onTap: () {},
            );
          }),
        ],
      ),
    );
  }
}

int _percentage(int correct, int total) {
  if (total == 0) return 0;
  return ((correct / total) * 100).round();
}
