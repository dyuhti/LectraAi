import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/models/quiz_question.dart';
import 'package:smart_lecture_notes/providers/quiz_provider.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/theme/quiz_theme.dart';
import 'package:smart_lecture_notes/widgets/quiz_option_tile.dart';

class PracticeQuizScreen extends StatelessWidget {
  const PracticeQuizScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final question = provider.currentQuestion;

    if (provider.isLoading) {
      return const _QuizLoadingScaffold();
    }

    if (question == null) {
      return _QuizEmptyScaffold(
        onGenerate: () => Navigator.of(context).pushNamed(
          AppRoutes.generateQuiz,
        ),
      );
    }

    final isLast = provider.currentIndex == provider.questions.length - 1;

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
          'Practice Quiz',
          style: TextStyle(
            color: QuizColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.noteTitle,
                  style: const TextStyle(
                    color: QuizColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: provider.progress,
                  ),
                  duration: const Duration(milliseconds: 320),
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: QuizColors.borderLight,
                        color: QuizColors.selectedOptionBorder,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Question ${provider.currentIndex + 1} of ${provider.questions.length}',
                  style: const TextStyle(
                    color: QuizColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              child: _QuestionBody(
                key: ValueKey(question.id),
                question: question,
                onSelect: (index) =>
                    provider.selectAnswer(provider.currentIndex, index),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _QuizBottomBar(
        isLast: isLast,
        isComplete: provider.isComplete,
        onNext: provider.nextQuestion,
        onSubmit: () {
          provider.finalizeQuiz();
          Navigator.of(context).pushNamed(AppRoutes.quizResults);
        },
      ),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({
    required this.question,
    required this.onSelect,
    Key? key,
  }) : super(key: key);

  final QuizQuestion question;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: QuizColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: QuizShadows.card,
            border: Border.all(color: QuizColors.borderLight, width: 1.5),
          ),
          child: Text(
            question.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: QuizColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(question.options.length, (index) {
          final optionLabel = String.fromCharCode(65 + index);
          final isSelected = question.userSelectedAnswer == index;
          final state = isSelected
              ? QuizOptionState.selected
              : QuizOptionState.neutral;

          return QuizOptionTile(
            label: optionLabel,
            text: question.options[index],
            state: state,
            onTap: () => onSelect(index),
          );
        }),
      ],
    );
  }
}

class _QuizBottomBar extends StatelessWidget {
  const _QuizBottomBar({
    required this.isLast,
    required this.isComplete,
    required this.onNext,
    required this.onSubmit,
  });

  final bool isLast;
  final bool isComplete;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final label = isLast ? 'Submit Quiz' : 'Next Question';
    final enabled = isLast ? isComplete : true;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        decoration: BoxDecoration(
          color: QuizColors.cardWhite,
          boxShadow: [
            BoxShadow(
              color: QuizColors.shadowColor.withOpacity(0.8),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? (isLast ? onSubmit : onNext) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: QuizColors.successButton,
              disabledBackgroundColor: QuizColors.successButton.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizLoadingScaffold extends StatelessWidget {
  const _QuizLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.softBackground,
      appBar: AppBar(
        backgroundColor: QuizColors.softBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: QuizColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Practice Quiz',
          style: TextStyle(
            color: QuizColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: const Center(
        child: CircularProgressIndicator(color: QuizColors.royalStart),
      ),
    );
  }
}

class _QuizEmptyScaffold extends StatelessWidget {
  const _QuizEmptyScaffold({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.softBackground,
      appBar: AppBar(
        backgroundColor: QuizColors.softBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: QuizColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Practice Quiz',
          style: TextStyle(
            color: QuizColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: QuizColors.infoBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  color: QuizColors.navy,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No quiz generated yet.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: QuizColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate a quiz to start practicing with LectraAI.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: QuizColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuizColors.successButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Generate Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
