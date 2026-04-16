import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/theme/quiz_theme.dart';

enum QuizOptionState {
  neutral,
  selected,
  correct,
  wrongSelected,
}

class QuizOptionTile extends StatefulWidget {
  const QuizOptionTile({
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  final String label;
  final String text;
  final QuizOptionState state;
  final VoidCallback onTap;

  @override
  State<QuizOptionTile> createState() => _QuizOptionTileState();
}

class _QuizOptionTileState extends State<QuizOptionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final style = _OptionStyle.fromState(widget.state);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.98 : 1,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: style.border,
              width: style.borderWidth,
            ),
            boxShadow: style.shadow,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: style.pillBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: style.pillText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: style.text,
                    height: 1.4,
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

class _OptionStyle {
  final Color background;
  final Color border;
  final double borderWidth;
  final Color text;
  final Color pillBackground;
  final Color pillText;
  final List<BoxShadow> shadow;

  const _OptionStyle({
    required this.background,
    required this.border,
    required this.borderWidth,
    required this.text,
    required this.pillBackground,
    required this.pillText,
    required this.shadow,
  });

  factory _OptionStyle.fromState(QuizOptionState state) {
    switch (state) {
      case QuizOptionState.selected:
        return _OptionStyle(
          background: QuizColors.selectedOptionBg,
          border: QuizColors.selectedOptionBorder,
          borderWidth: 2,
          text: QuizColors.textPrimary,
          pillBackground: QuizColors.selectedOptionBorder,
          pillText: Colors.white,
          shadow: [
            const BoxShadow(
              color: QuizColors.shadowColor,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        );
      case QuizOptionState.correct:
        return _OptionStyle(
          background: QuizColors.correctBg,
          border: QuizColors.correctBorder,
          borderWidth: 2,
          text: QuizColors.textPrimary,
          pillBackground: QuizColors.correctBorder,
          pillText: Colors.white,
          shadow: [],
        );
      case QuizOptionState.wrongSelected:
        return _OptionStyle(
          background: QuizColors.wrongBg,
          border: QuizColors.wrongBorder,
          borderWidth: 2,
          text: QuizColors.textPrimary,
          pillBackground: QuizColors.wrongBorder,
          pillText: Colors.white,
          shadow: [],
        );
      case QuizOptionState.neutral:
      default:
        return _OptionStyle(
          background: QuizColors.cardWhite,
          border: QuizColors.borderLight,
          borderWidth: 1.5,
          text: QuizColors.textSecondary,
          pillBackground: QuizColors.infoBg,
          pillText: QuizColors.navy,
          shadow: [],
        );
    }
  }
}
