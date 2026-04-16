import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/providers/quiz_provider.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/theme/quiz_theme.dart';

class GenerateQuizScreen extends StatefulWidget {
  const GenerateQuizScreen({Key? key}) : super(key: key);

  @override
  State<GenerateQuizScreen> createState() => _GenerateQuizScreenState();
}

class _GenerateQuizScreenState extends State<GenerateQuizScreen> {
  static const String _apiKey =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

  final List<_QuizNote> _notes = const [
    _QuizNote(
      title: 'Data Structures - Linked Lists',
      subtitle: 'Pointers, nodes, and traversal patterns',
      content:
          'A linked list is a linear data structure where each node points to the next. '
          'Nodes contain data and a reference to the next node. '
          'Linked lists allow efficient insertion and deletion. '
          'A doubly linked list stores references to both previous and next nodes.',
    ),
    _QuizNote(
      title: 'Machine Learning Basics',
      subtitle: 'Supervised, unsupervised, and evaluation metrics',
      content:
          'Supervised learning uses labeled data to train models. '
          'Unsupervised learning discovers patterns without labels. '
          'Accuracy, precision, and recall are common evaluation metrics.',
    ),
    _QuizNote(
      title: 'Operating Systems - Scheduling',
      subtitle: 'CPU scheduling policies and performance goals',
      content:
          'Scheduling decides which process runs next on the CPU. '
          'Round-robin uses time slices to share CPU time fairly. '
          'Shortest job first minimizes average wait time.',
    ),
  ];

  int _selectedNoteIndex = 0;
  int _selectedCount = 10;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();

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
          'Generate AI Quiz',
          style: TextStyle(
            color: QuizColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a lecture note to generate a tailored quiz.',
                  style: TextStyle(
                    color: QuizColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _buildNoteSelector(provider.isLoading),
                const SizedBox(height: 22),
                const Text(
                  'Quiz size',
                  style: TextStyle(
                    color: QuizColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCountChips(provider.isLoading),
                const SizedBox(height: 22),
                _buildInfoCard(),
                const SizedBox(height: 28),
                if (provider.isLoading)
                  const _ShimmerBlock(height: 56)
                else
                  _GradientButton(
                    label: 'Generate Quiz',
                    onTap: () => _generateQuiz(provider),
                  ),
              ],
            ),
          ),
          if (provider.isLoading) const _LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildNoteSelector(bool isLoading) {
    return AbsorbPointer(
      absorbing: isLoading,
      child: Column(
        children: List.generate(_notes.length, (index) {
          final note = _notes[index];
          final selected = index == _selectedNoteIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuizColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? QuizColors.selectedOptionBorder
                    : QuizColors.borderLight,
                width: selected ? 2 : 1.5,
              ),
              boxShadow: selected ? QuizShadows.card : [],
            ),
            child: InkWell(
              onTap: () => setState(() => _selectedNoteIndex = index),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected
                          ? QuizColors.selectedOptionBg
                          : QuizColors.infoBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: selected
                          ? QuizColors.selectedOptionBorder
                          : QuizColors.navy,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: QuizColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          note.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: QuizColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: QuizColors.selectedOptionBorder,
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCountChips(bool isLoading) {
    const counts = [5, 10, 15];

    return AbsorbPointer(
      absorbing: isLoading,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: counts.map((count) {
          final selected = count == _selectedCount;
          return GestureDetector(
            onTap: () => setState(() => _selectedCount = count),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? QuizColors.successButton
                    : QuizColors.cardWhite,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? QuizColors.successButton
                      : QuizColors.borderLight,
                  width: 1.5,
                ),
              ),
              child: Text(
                '$count questions',
                style: TextStyle(
                  color: selected ? Colors.white : QuizColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuizColors.infoBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QuizColors.borderLight, width: 1.2),
      ),
      child: Row(
        children: const [
          Icon(Icons.auto_awesome, color: QuizColors.navy, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'LectraAI generates MCQs with balanced difficulty. Review your notes before starting.',
              style: TextStyle(
                fontSize: 12,
                color: QuizColors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQuiz(QuizProvider provider) async {
    final note = _notes[_selectedNoteIndex];

    await provider.generateQuiz(
      noteTitle: note.title,
      noteText: note.content,
      questionCount: _selectedCount,
      apiKey: _apiKey,
    );

    if (!mounted) return;
    Navigator.of(context).pushNamed(AppRoutes.practiceQuiz);
  }
}

class _QuizNote {
  final String title;
  final String subtitle;
  final String content;

  const _QuizNote({
    required this.title,
    required this.subtitle,
    required this.content,
  });
}

class _GradientButton extends StatefulWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed
        ? 0.98
        : _hovered
            ? 1.02
            : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: QuizGradients.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: QuizShadows.card,
            ),
            child: Center(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          color: QuizColors.softBackground.withOpacity(0.6),
          child: const Center(
            child: _ShimmerBlock(height: 120),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({required this.height});

  final double height;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                QuizColors.cardWhite,
                QuizColors.infoBg,
                QuizColors.cardWhite,
              ],
              stops: [
                (t - 0.2).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.2).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: QuizShadows.card,
          ),
        );
      },
    );
  }
}
