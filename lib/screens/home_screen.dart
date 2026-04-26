import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/providers/accessibility_provider.dart';
import 'package:smart_lecture_notes/providers/document_provider.dart';
import 'package:smart_lecture_notes/providers/progress_provider.dart';
import 'package:smart_lecture_notes/providers/quiz_provider.dart';
import 'package:smart_lecture_notes/utils/tts_text_builder.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_lecture_notes/models/progress.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Brand palette (per request)
  static const Color _navy = Color(0xFF0A2A8A);
  static const Color _royal = Color(0xFF1E4ED8);
  static const Color _bg = Color(0xFFF7F9FC);
  static const Color _subtle = Color(0xFF6F7CAB);
  static const double _radius = 28;

  static const String _heroTag = 'home_capture_create_hero';

  late final AnimationController _ambient;
  late final AnimationController _shimmer;
  String _selectedText = '';
  late int _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<ProgressProvider>().refreshProgress();
    });
  }



  @override
  void dispose() {
    _sendStudyTime();
    _ambient.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  void _sendStudyTime() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final durationMinutes = ((now - _startTime) / 60000).round();
    if (durationMinutes > 0) {
      context.read<ProgressProvider>().addStudyTime(durationMinutes);
      debugPrint('[TIMER] Sent $durationMinutes minutes of study time');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 380 ? 18.0 : 24.0;
    final isAccessibilityEnabled = context.watch<AccessibilityProvider>().isEnabled;
    _publishScreenText(_buildScreenText());

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            child: SelectionArea(
              onSelectionChanged: (selectedContent) {
                final selected = selectedContent?.plainText.trim() ?? '';
                if (_selectedText == selected) return;
                setState(() {
                  _selectedText = selected;
                });
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(padding, 20, padding, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _TopHeader(
                            onSettings: () =>
                                Navigator.of(context).pushNamed(AppRoutes.settings),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your AI-powered lecture companion',
                            style: TextStyle(
                              color: _subtle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AccessibilityToggleCard(
                            enabled: isAccessibilityEnabled,
                            onChanged: (value) =>
                                context.read<AccessibilityProvider>().toggle(value),
                            selectedText: _selectedText,
                          ),
                          const SizedBox(height: 18),
                          _FadeInOnBuild(
                            delay: const Duration(milliseconds: 50),
                            child: _HomeHeroCard(
                              heroTag: _heroTag,
                              ambient: _ambient,
                              shimmer: _shimmer,
                              navy: _navy,
                              royal: _royal,
                              radius: _radius,
                              onTap: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.captureNotes),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FadeInOnBuild(
                            delay: const Duration(milliseconds: 200),
                            child: _ViewNotesLayeredCard(
                              navy: _navy,
                              royal: _royal,
                              radius: _radius,
                              onTap: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.viewNotes),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const _FadeInOnBuild(
                            delay: Duration(milliseconds: 260),
                            child: _TodayProgressCard(
                              navy: _navy,
                              royal: _royal,
                              radius: _radius,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  String getScreenText() => _buildScreenText();

  String _buildScreenText() {
    final selectedText = _selectedText.trim();
    if (selectedText.isNotEmpty) {
      return buildStructuredText(
        title: 'Smart Notes home',
        content: 'Selected text. $selectedText',
        keyPoints: const [],
      );
    }

    final progress = context.read<ProgressProvider>().progress;
    final progressText = 'Today study progress includes ${progress.notesCreated} notes created, '
        '${progress.audioRecorded} audio recorded, and ${progress.quizzesGenerated} quiz generated.';

    return buildStructuredText(
      title: 'Smart Notes home',
      content: 'Your AI-powered lecture companion. Capture and create notes. View notes. $progressText',
      keyPoints: const [
        'Capture and create notes',
        'View notes',
        'Today study progress',
      ],
    );
  }

  void _publishScreenText(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccessibilityProvider>().setScreenTextIfCurrent(context, text);
    });
  }

}

class _AccessibilityToggleCard extends StatelessWidget {
  const _AccessibilityToggleCard({
    required this.enabled,
    required this.onChanged,
    required this.selectedText,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String selectedText;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedText.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _HomeScreenState._navy.withOpacity(enabled ? 0.20 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _HomeScreenState._royal.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _HomeScreenState._royal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                '🔊',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accessibility Mode',
                  style: TextStyle(
                    color: _HomeScreenState._navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    // color: Colors.black87, // If you want to use black87 instead, uncomment this line
                  ),
                ),
                if (hasSelection)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Selection ready for read aloud',
                      style: TextStyle(
                        color: _HomeScreenState._subtle.withOpacity(0.95),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: enabled,
              onChanged: onChanged,
              activeColor: _HomeScreenState._navy,
            ),
          ),
        ],
      ),
    );
  }
}





class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: Color(0x55000000),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.96, end: 1.04),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: _HomeScreenState._navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _HomeScreenState._royal.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'assets/logo/home_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Smart Notes',
              style: TextStyle(
                color: _HomeScreenState._navy,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSettings,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _HomeScreenState._royal.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _HomeScreenState._navy.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: _HomeScreenState._navy,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FadeInOnBuild extends StatefulWidget {
  const _FadeInOnBuild({
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<_FadeInOnBuild> createState() => _FadeInOnBuildState();
}

class _FadeInOnBuildState extends State<_FadeInOnBuild> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.05),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _PressableSurface extends StatefulWidget {
  const _PressableSurface({
    required this.onTap,
    required this.child,
    required this.decoration,
    required this.borderRadius,
    this.scaleDown = 0.985,
  });

  final VoidCallback onTap;
  final Widget child;
  final Decoration decoration;
  final double borderRadius;
  final double scaleDown;

  @override
  State<_PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<_PressableSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? widget.scaleDown : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Ink(
            decoration: widget.decoration,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.heroTag,
    required this.ambient,
    required this.shimmer,
    required this.navy,
    required this.royal,
    required this.radius,
    required this.onTap,
  });

  final String heroTag;
  final Animation<double> ambient;
  final Animation<double> shimmer;
  final Color navy;
  final Color royal;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [navy, royal],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: royal.withOpacity(0.22),
          blurRadius: 26,
          offset: const Offset(0, 16),
        ),
      ],
    );

    return Hero(
      tag: heroTag,
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: radius,
        decoration: decoration,
        scaleDown: 0.99,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final cardHeight = (maxWidth / (16 / 9)).clamp(220.0, 290.0);

            return SizedBox(
              height: cardHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Stack(
                  children: [
                    // Abstract background: waves + floating sparkles
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _HeroWavePainter(
                          seed: 7,
                          sparklePhase: ambient,
                          royal: royal,
                        ),
                      ),
                    ),

                    // Glass overlay (subtle)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.10),
                                Colors.white.withOpacity(0.04),
                                Colors.white.withOpacity(0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Shimmer pass
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: shimmer,
                          builder: (context, child) {
                            final t = shimmer.value;
                            return Opacity(
                              opacity: 0.35,
                              child: Transform.translate(
                                offset: Offset((-1 + (2 * t)) * 220, 0),
                                child: Transform.rotate(
                                  angle: -0.25,
                                  child: Container(
                                    width: 170,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(0.30),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _HeroIconChip(
                                ambient: ambient,
                                royal: royal,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Adaptive Notes',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Premium AI workflows for lectures',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.80),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 34),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Start capturing in seconds',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.78),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _CtaChipButton(
                                label: 'Start Now',
                                onTap: onTap,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroIconChip extends StatelessWidget {
  const _HeroIconChip({
    required this.ambient,
    required this.royal,
  });

  final Animation<double> ambient;
  final Color royal;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        final t = ambient.value * math.pi * 2;
        final pulse = 1 + 0.04 * math.sin(t);
        final glow = 0.14 + 0.10 * ((math.sin(t) + 1) / 2);

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: royal.withOpacity(glow),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 30,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SparklePainter(phase: ambient),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CtaChipButton extends StatelessWidget {
  const _CtaChipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: content,
      ),
    );
  }
}

class _ViewNotesLayeredCard extends StatelessWidget {
  const _ViewNotesLayeredCard({
    required this.navy,
    required this.royal,
    required this.radius,
    required this.onTap,
  });

  final Color navy;
  final Color royal;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: navy.withOpacity(0.07), width: 1),
      boxShadow: [
        BoxShadow(
          color: royal.withOpacity(0.10),
          blurRadius: 22,
          offset: const Offset(0, 14),
        ),
      ],
    );

    return SizedBox(
      height: 172,
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: radius,
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _LayeredPaperIcon(royal: royal, navy: navy),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View Notes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Browse, search, and refine your lecture notes.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HomeScreenState._subtle,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: royal.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: navy.withOpacity(0.06),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Library',
                              style: TextStyle(
                                color: navy.withOpacity(0.86),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: royal.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: navy.withOpacity(0.06), width: 1),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayeredPaperIcon extends StatelessWidget {
  const _LayeredPaperIcon({required this.royal, required this.navy});

  final Color royal;
  final Color navy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 12,
            child: Transform.rotate(
              angle: -0.06,
              child: _PaperSheet(
                color: royal.withOpacity(0.06),
                border: navy.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 6,
            child: Transform.rotate(
              angle: 0.05,
              child: _PaperSheet(
                color: royal.withOpacity(0.08),
                border: navy.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _PaperSheet(
              color: Colors.white,
              border: navy.withOpacity(0.10),
              child: Center(
                child: Icon(
                  Icons.note_outlined,
                  color: royal,
                  size: 34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperSheet extends StatelessWidget {
  const _PaperSheet({
    required this.color,
    required this.border,
    this.child,
  });

  final Color color;
  final Color border;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _HomeScreenState._royal.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({
    required this.navy,
    required this.royal,
    required this.radius,
  });

  final Color navy;
  final Color royal;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: navy.withOpacity(0.07), width: 1),
      boxShadow: [
        BoxShadow(
          color: royal.withOpacity(0.10),
          blurRadius: 22,
          offset: const Offset(0, 14),
        ),
      ],
    );

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: royal.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Today's Study Progress",
                style: TextStyle(
                  color: navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Consumer<ProgressProvider>(
            builder: (context, progressProvider, _) {
              final progress = progressProvider.progress;
              if (progressProvider.isLoading) {
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatChip(
                    icon: Icons.note_alt_outlined,
                    text: '${progress.notesCreated} Notes',
                  ),
                  _StatChip(
                    icon: Icons.mic_none_rounded,
                    text: '${progress.audioRecorded} Recordings',
                  ),
                  _StatChip(
                    icon: Icons.quiz_outlined,
                    text: '${progress.quizzesGenerated} Quizzes',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    const navy = _HomeScreenState._navy;
    const royal = _HomeScreenState._royal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: royal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: navy.withOpacity(0.06), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: royal),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: navy.withOpacity(0.86),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.phase});

  final Animation<double> phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final t = phase.value;
    final paint = Paint()..style = PaintingStyle.fill;

    // Tiny sparkles around the icon (bounded inside)
    final points = <Offset, double>{
      const Offset(12, 14): 1.0,
      const Offset(44, 12): 0.9,
      const Offset(50, 42): 0.8,
      const Offset(18, 48): 0.85,
    };

    for (final entry in points.entries) {
      final p = entry.key;
      final base = entry.value;
      final alpha = (0.30 + 0.50 * ((math.sin((t * math.pi * 2) + base) + 1) / 2))
          .clamp(0.0, 1.0);
      paint.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(p, 1.2 + (1.4 * alpha), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}

class _HeroWavePainter extends CustomPainter {
  _HeroWavePainter({
    required this.seed,
    required this.sparklePhase,
    required this.royal,
  }) : super(repaint: sparklePhase);

  final int seed;
  final Animation<double> sparklePhase;
  final Color royal;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final t = sparklePhase.value;
    final safeWidth = size.width;

    // Soft wave bands
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    Path wave(double yBase, double amp, double phase) {
      final path = Path()..moveTo(0, yBase);
      for (double x = 0; x <= safeWidth; x += 14) {
        final y = yBase + amp * math.sin((x / safeWidth) * math.pi * 2 + phase);
        path.lineTo(x, y);
      }
      path.lineTo(safeWidth, size.height);
      path.lineTo(0, size.height);
      path.close();
      return path;
    }

    canvas.drawPath(wave(size.height * 0.55, 10, (t * math.pi * 2) + 0.8), wavePaint);
    canvas.drawPath(
      wave(size.height * 0.70, 14, (t * math.pi * 2) + 1.6),
      wavePaint..color = Colors.white.withOpacity(0.07),
    );

    // Floating sparkles (very subtle)
    final sparkle = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(seed);
    for (int i = 0; i < 10; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final phase = rng.nextDouble() * math.pi * 2;
      final v = (math.sin((t * math.pi * 2) + phase) + 1) / 2;
      sparkle.color = Colors.white.withOpacity(0.06 + (0.10 * v));
      canvas.drawCircle(Offset(x, y), 1.2 + (1.8 * v), sparkle);
    }

    // Corner glow vignette
    final rect = Offset.zero & size;
    final radial = Paint()
      ..shader = RadialGradient(
        colors: [royal.withOpacity(0.18), Colors.transparent],
        stops: const [0, 1],
        center: const Alignment(0.8, -0.9),
        radius: 1.1,
      ).createShader(rect);
    canvas.drawRect(rect, radial);
  }

  @override
  bool shouldRepaint(covariant _HeroWavePainter oldDelegate) => true;
}
