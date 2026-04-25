import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/widgets/tts_control_widget.dart';

class GlobalAccessibilityOverlay extends StatelessWidget {
  const GlobalAccessibilityOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.watch<AccessibilityProvider>().isEnabled;
    final screenText = context.watch<AccessibilityProvider>().screenText;

    return Stack(
      children: [
        child,
        if (isEnabled && screenText.isNotEmpty)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TtsControlWidget(text: screenText),
            ),
          ),
      ],
    );
  }
}