import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/widgets/tts_control_widget.dart';

class GlobalAccessibilityOverlay extends StatefulWidget {
  const GlobalAccessibilityOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalAccessibilityOverlay> createState() =>
      _GlobalAccessibilityOverlayState();
}

class _GlobalAccessibilityOverlayState extends State<GlobalAccessibilityOverlay> {
  static const double _overlayPadding = 16;

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.watch<AccessibilityProvider>().isEnabled;
    final screenText = context.watch<AccessibilityProvider>().screenText;
    final showOverlay = isEnabled && screenText.isNotEmpty;

    return Stack(
      children: [
        widget.child,
        if (showOverlay)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(_overlayPadding),
              child: TtsControlWidget(text: screenText),
            ),
          ),
      ],
    );
  }
}