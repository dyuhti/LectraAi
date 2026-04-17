import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/providers/quiz_provider.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';

const Color _background = Color(0xFFF7F9FC);
const Color _navy = Color(0xFF0A2A8A);
const Color _gradientStart = Color(0xFF1E4ED8);
const Color _gradientEnd = Color(0xFF3B82F6);
const Color _white = Colors.white;
const Color _border = Color(0xFFDCE6FF);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textSecondary = Color(0xFF64748B);
const Color _infoCard = Color(0xFFEEF4FF);

class GenerateQuizScreen extends StatefulWidget {
  const GenerateQuizScreen({Key? key}) : super(key: key);

  @override
  State<GenerateQuizScreen> createState() => _GenerateQuizScreenState();
}

class _GenerateQuizScreenState extends State<GenerateQuizScreen> {
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

  static const List<int> _quickSelectOptions = [5, 10, 15, 20];

  int _selectedNoteIndex = 0;
  int _selectedCount = 10;
  String? _countError;
  late TextEditingController _questionCountController;

  @override
  void initState() {
    super.initState();
    _questionCountController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _questionCountController.dispose();
    super.dispose();
  }

  void _handleQuickSelect(int count) {
    setState(() {
      _selectedCount = count;
      _countError = null;
      _questionCountController.text = count.toString();
    });
  }

  void _handleCustomCountChange(String value) {
    setState(() {
      if (value.isEmpty) {
        _countError = null;
        return;
      }

      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 1 || parsed > 25) {
        _countError = 'Enter a number between 1-25';
        return;
      }

      _countError = null;
      _selectedCount = parsed;
    });
  }

  Future<void> _generateQuiz(QuizProvider provider) async {
    if (_countError != null || _selectedCount < 1 || _selectedCount > 25) {
      _showSnackBar('Please enter a number between 1-25.');
      return;
    }

    final note = _notes[_selectedNoteIndex];

    print('[GenerateQuizScreen] Starting quiz generation...');
    print('[GenerateQuizScreen] Selected note: ${note.title}');
    print('[GenerateQuizScreen] Question count: $_selectedCount');

    await provider.generateQuiz(
      noteTitle: note.title,
      noteText: note.content,
      questionCount: _selectedCount,
    );

    if (!mounted) return;

    if (provider.questions.isEmpty) {
      final message = provider.errorMessage ?? 'Failed to generate quiz.';
      print('[GenerateQuizScreen] Generation failed: $message');
      _showSnackBar(message);
      return;
    }

    if (provider.errorMessage != null) {
      print('[GenerateQuizScreen] Generation completed with warning: ${provider.errorMessage}');
      _showSnackBar(provider.errorMessage ?? 'Quiz generated (offline mode)');
    } else {
      print('[GenerateQuizScreen] Generation completed successfully!');
    }

    Navigator.of(context).pushNamed(AppRoutes.practiceQuiz);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final canGenerate = !provider.isLoading && _countError == null;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Generate AI Quiz',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Note',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _notes[_selectedNoteIndex].title,
                icon: const Icon(Icons.keyboard_arrow_down, color: _textSecondary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _border,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _border,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _gradientStart,
                      width: 2,
                    ),
                  ),
                ),
                items: _notes
                    .map(
                      (note) => DropdownMenuItem<String>(
                        value: note.title,
                        child: Text(
                          note.title,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: provider.isLoading
                    ? null
                    : (value) {
                        if (value == null) return;
                        final index = _notes.indexWhere(
                          (note) => note.title == value,
                        );
                        if (index == -1) return;
                        setState(() => _selectedNoteIndex = index);
                      },
              ),
              const SizedBox(height: 24),
              const Text(
                'Number of Questions',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _quickSelectOptions
                    .map(
                      (count) => Padding(
                        padding: EdgeInsets.only(
                          right: count == _quickSelectOptions.last ? 0 : 10,
                        ),
                        child: _QuickSelectChip(
                          count: count,
                          selected: _selectedCount == count,
                          onTap: provider.isLoading
                              ? null
                              : () => _handleQuickSelect(count),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Or enter custom number (1-25):',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionCountController,
                onChanged: _handleCustomCountChange,
                keyboardType: TextInputType.number,
                enabled: !provider.isLoading,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _white,
                  hintText: 'Enter 1-25 questions',
                  hintStyle: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  errorText: _countError,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _border,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _border,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _gradientStart,
                      width: 2,
                    ),
                  ),
                ),
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _infoCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: _navy, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'LectraAI will generate multiple-choice questions based on your selected note.',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: canGenerate ? 1 : 0.6,
                child: GestureDetector(
                  onTap: canGenerate ? () => _generateQuiz(provider) : null,
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_gradientStart, _gradientEnd],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: provider.isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'LectraAI is generating quiz with Groq...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Generate Quiz',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

class _QuickSelectChip extends StatefulWidget {
  const _QuickSelectChip({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_QuickSelectChip> createState() => _QuickSelectChipState();
}

class _QuickSelectChipState extends State<_QuickSelectChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.96 : 1.0;
    final background = widget.selected ? _gradientStart : _white;
    final textColor = widget.selected ? _white : _textPrimary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: 70,
          height: 48,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected ? background : _border,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.count.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
