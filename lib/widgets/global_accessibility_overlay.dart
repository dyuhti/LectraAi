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

  final GlobalKey _overlayKey = GlobalKey();
  double _overlayHeight = 0;

  void _measureOverlayHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _overlayKey.currentContext;
      if (context == null) return;

      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox) return;

      final measured = renderObject.size.height;
      if ((measured - _overlayHeight).abs() < 1) {
        return;
      }

      setState(() {
        _overlayHeight = measured;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.watch<AccessibilityProvider>().isEnabled;
    final screenText = context.watch<AccessibilityProvider>().screenText;
    final showOverlay = isEnabled && screenText.isNotEmpty;

    if (showOverlay) {
      _measureOverlayHeight();
    } else if (_overlayHeight != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_overlayHeight == 0) return;
        setState(() {
          _overlayHeight = 0;
        });
      });
    }

    final reservedBottomSpace = showOverlay
      ? (_overlayHeight > 0 ? _overlayHeight + (_overlayPadding * 2) : 220.0)
        : 0.0;

    return Stack(
      children: [
        AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: reservedBottomSpace),
          child: widget.child,
        ),
        if (showOverlay)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(_overlayPadding),
              child: KeyedSubtree(
                key: _overlayKey,
                child: Container(
                  margin: const EdgeInsets.all(0),
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TtsControlWidget(text: screenText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}