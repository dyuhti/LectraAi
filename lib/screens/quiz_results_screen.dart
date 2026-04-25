import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/providers/quiz_provider.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/theme/quiz_theme.dart';
import 'package:smart_lecture_notes/utils/tts_text_builder.dart';

class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({Key? key}) : super(key: key);

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final totalCount = provider.questions.length;
    final correctCount = provider.correctCount;
    final scorePercentage = totalCount == 0
        ? 0
        : ((correctCount / totalCount) * 100).round();
    _publishScreenText(
      getScreenText(scorePercentage, correctCount, totalCount),
    );

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
          'Quiz Results',
          style: TextStyle(
            color: QuizColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0)
                  .animate(_scaleController),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: QuizColors.cardWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: QuizColors.shadowColor,
                      blurRadius: 22,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: scorePercentage / 100,
                        ),
                        duration: const Duration(milliseconds: 900),
                        builder: (context, value, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: value,
                                strokeWidth: 8,
                                backgroundColor: QuizColors.infoBg,
                                color: QuizColors.royalStart,
                              ),
                              Text(
                                '$scorePercentage%',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: QuizColors.navy,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your score',
                      style: TextStyle(
                        color: QuizColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$correctCount out of $totalCount correct',
                      style: const TextStyle(
                        color: QuizColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _FeedbackChip(scorePercentage: scorePercentage),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.reviewAnswers),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuizColors.successButton,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Review Answers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.home,
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: QuizColors.textPrimary,
                  side: const BorderSide(
                    color: QuizColors.borderLight,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getScreenText(int scorePercentage, int correctCount, int totalCount) {
    final feedback = scorePercentage >= 80
        ? 'Excellent performance. Keep pushing higher.'
        : scorePercentage >= 60
            ? 'Solid progress. Review a few key concepts.'
            : scorePercentage >= 40
                ? 'Keep practicing to strengthen recall.'
                : 'Review the lecture notes and try again.';

    return buildStructuredText(
      title: 'Quiz results',
      content: 'Score. $scorePercentage percent. Correct answers. $correctCount out of $totalCount. $feedback',
      keyPoints: const [],
    );
  }

  void _publishScreenText(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccessibilityProvider>().setScreenTextIfCurrent(context, text);
    });
  }
}

class _FeedbackChip extends StatelessWidget {
  const _FeedbackChip({required this.scorePercentage});

  final int scorePercentage;

  @override
  Widget build(BuildContext context) {
    final message = scorePercentage >= 80
        ? 'Excellent performance. Keep pushing higher.'
        : scorePercentage >= 60
            ? 'Solid progress. Review a few key concepts.'
            : scorePercentage >= 40
                ? 'Keep practicing to strengthen recall.'
                : 'Review the lecture notes and try again.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuizColors.infoBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QuizColors.borderLight, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: QuizColors.navy, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: QuizColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
