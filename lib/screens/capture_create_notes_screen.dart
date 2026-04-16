import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';

class CaptureCreateNotesScreen extends StatefulWidget {
  const CaptureCreateNotesScreen({Key? key}) : super(key: key);

  @override
  State<CaptureCreateNotesScreen> createState() =>
      _CaptureCreateNotesScreenState();
}

class _CaptureCreateNotesScreenState extends State<CaptureCreateNotesScreen>
    with TickerProviderStateMixin {
  static const String _captureHeroTag = 'capture_board_hero';
  static const String _homeHeroTag = 'home_capture_create_hero';

  // Brand palette (per request)
  static const Color _navy = Color(0xFF0A2A8A);
  static const Color _royal = Color(0xFF1E4ED8);
  static const Color _bg = Color(0xFFF7F9FC);
  static const Color _subtitle = Color(0xFF6F7CAB);
  static const double _radius = 24;

  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 380 ? 18.0 : 24.0;

    final items = <Widget>[
      const SizedBox(height: 12),

      // Mini Progress Chips
      _FadeInOnBuild(
        delay: const Duration(milliseconds: 0),
        child: const _ProgressChipsRow(),
      ),

      const SizedBox(height: 24),
      const _SectionLabel(title: 'Capture'),
      _FadeInOnBuild(
        delay: const Duration(milliseconds: 40),
        child: _HeroCaptureCard(
          heroTag: _captureHeroTag,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.smartCamera),
          navy: _navy,
          royal: _royal,
          radius: _radius,
          ambient: _ambient,
        ),
      ),

      const SizedBox(height: 18),
      const _FlowHintRow(),
      const SizedBox(height: 14),

      _MosaicFeatureGrid(
        radius: _radius,
        navy: _navy,
        royal: _royal,
        subtitleColor: _subtitle,
        ambient: _ambient,
        staggerBaseMs: 120,
        onUpload: () => Navigator.of(context).pushNamed(AppRoutes.fileUpload),
        onRecord: () => Navigator.of(context).pushNamed(AppRoutes.recordAudio),
        onQuiz: () => Navigator.of(context).pushNamed(AppRoutes.practiceQuiz),
        onAnalytics:
            () => Navigator.of(context).pushNamed(AppRoutes.studyAnalytics),
      ),

      const SizedBox(height: 18),
      const _SectionLabel(title: 'Insights'),
      _FadeInOnBuild(
        delay: const Duration(milliseconds: 180),
        child: _FeatureCard(
          height: 130,
          radius: _radius,
          navy: _navy,
          royal: _royal,
          subtitleColor: _subtitle,
          stage: 'Insights',
          icon: Icons.notifications_none,
          title: 'Enable Revision Reminder',
          subtitle: 'Spaced repetition-based notifications',
          actionLabel: 'Configure',
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.revisionReminder),
        ),
      ),

      const SizedBox(height: 16),
      _FadeInOnBuild(
        delay: const Duration(milliseconds: 240),
        child: _ProgressDashboardCard(
          radius: _radius,
          navy: _navy,
          royal: _royal,
        ),
      ),

      const SizedBox(height: 32),
    ];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: _homeHeroTag,
              child: const Material(
                color: Colors.transparent,
                child: Text(
                  'Capture & Create Notes',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'AI-powered tools for classroom note creation',
              style: TextStyle(
                color: _subtitle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => items[index],
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _CaptureCreateNotesScreenState._royal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: _CaptureCreateNotesScreenState._navy,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowHintRow extends StatelessWidget {
  const _FlowHintRow();

  @override
  Widget build(BuildContext context) {
    const color = _CaptureCreateNotesScreenState._subtitle;

    Widget step(String text) {
      return Text(
        text,
        style: const TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          step('Capture'),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, size: 16, color: color),
          const SizedBox(width: 10),
          step('Process'),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, size: 16, color: color),
          const SizedBox(width: 10),
          step('Practice'),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, size: 16, color: color),
          const SizedBox(width: 10),
          step('Insights'),
        ],
      ),
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
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _PressableSurface extends StatefulWidget {
  const _PressableSurface({
    required this.child,
    required this.onTap,
    required this.decoration,
    this.borderRadius = 24,
    this.scaleDown = 0.985,
  });

  final Widget child;
  final VoidCallback onTap;
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

class _HeroCaptureCard extends StatelessWidget {
  const _HeroCaptureCard({
    required this.heroTag,
    required this.onTap,
    required this.navy,
    required this.royal,
    required this.radius,
    required this.ambient,
  });

  final String heroTag;
  final VoidCallback onTap;
  final Color navy;
  final Color royal;
  final double radius;
  final Animation<double> ambient;

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
    final width = MediaQuery.sizeOf(context).width;
    final aspectRatio = width < 360 ? 1.6 : 16 / 9;

    return Hero(
      tag: heroTag,
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: radius,
        scaleDown: 0.99,
        decoration: decoration,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // Abstract background pattern with subtle waves
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CaptureCardWavePainter(),
                  ),
                ),

                  // Glass overlay
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: ambient,
                          builder: (context, child) {
                            final t = ambient.value * math.pi * 2;
                            final pulse = 1 + 0.04 * math.sin(t);
                            final glow = 0.12 + 0.12 * ((math.sin(t) + 1) / 2);
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
                                child: child,
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Capture Board Image',
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
                          'Scan classroom board using AI-powered OCR',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.80),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ready in seconds',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.76),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: _PillActionButton(
                                label: 'Open Camera',
                                background: Colors.white.withOpacity(0.16),
                                foreground: Colors.white,
                                border: Colors.white.withOpacity(0.22),
                                onTap: onTap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _CaptureCardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    // Soft wave pattern on background
    for (int i = 0; i < 3; i++) {
      final offset = Offset(
        size.width * (0.3 + i * 0.3),
        size.height * (0.5 - i * 0.1),
      );
      canvas.drawCircle(offset, size.width * (0.25 - i * 0.05), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MosaicFeatureGrid extends StatelessWidget {
  const _MosaicFeatureGrid({
    required this.radius,
    required this.navy,
    required this.royal,
    required this.subtitleColor,
    required this.ambient,
    this.staggerBaseMs = 0,
    required this.onUpload,
    required this.onRecord,
    required this.onQuiz,
    required this.onAnalytics,
  });

  final double radius;
  final Color navy;
  final Color royal;
  final Color subtitleColor;
  final Animation<double> ambient;
  final int staggerBaseMs;
  final VoidCallback onUpload;
  final VoidCallback onRecord;
  final VoidCallback onQuiz;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isSingleColumn = w < 520;
        final gap = w < 380 ? 12.0 : 16.0;

        Widget stagger(int offsetMs, Widget child) {
          return _FadeInOnBuild(
            delay: Duration(milliseconds: staggerBaseMs + offsetMs),
            child: child,
          );
        }

        if (isSingleColumn) {
          return Column(
            children: [
              stagger(
                0,
                _FeatureCard(
                  height: 132,
                  radius: radius,
                  navy: navy,
                  royal: royal,
                  subtitleColor: subtitleColor,
                  stage: 'Process',
                  icon: Icons.description,
                  title: 'Upload PDF or Image',
                  subtitle: 'Extract and process text from files',
                  actionLabel: 'Upload',
                  onTap: onUpload,
                ),
              ),
              SizedBox(height: gap),
              stagger(
                70,
                _RecordingFeatureCard(
                  height: 182,
                  radius: radius,
                  navy: navy,
                  royal: royal,
                  subtitleColor: subtitleColor,
                  ambient: ambient,
                  onTap: onRecord,
                ),
              ),
              SizedBox(height: gap),
              stagger(
                140,
                _FeatureCard(
                  height: 132,
                  radius: radius,
                  navy: navy,
                  royal: royal,
                  subtitleColor: subtitleColor,
                  stage: 'Practice',
                  icon: Icons.quiz_outlined,
                  title: 'Generate Practice Quiz',
                  subtitle: 'MCQs + short questions from your notes',
                  actionLabel: 'Generate',
                  onTap: onQuiz,
                ),
              ),
              SizedBox(height: gap),
              stagger(
                210,
                _FeatureCard(
                  height: 150,
                  radius: radius,
                  navy: navy,
                  royal: royal,
                  subtitleColor: subtitleColor,
                  stage: 'Insights',
                  icon: Icons.bar_chart,
                  title: 'Study Analytics Dashboard',
                  subtitle: 'Track progress and study patterns',
                  actionLabel: 'Open',
                  onTap: onAnalytics,
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  stagger(
                    0,
                    _FeatureCard(
                      height: 142,
                      radius: radius,
                      navy: navy,
                      royal: royal,
                      subtitleColor: subtitleColor,
                      stage: 'Process',
                      icon: Icons.description,
                      title: 'Upload PDF or Image',
                      subtitle: 'Extract & process text from files',
                      actionLabel: 'Upload',
                      onTap: onUpload,
                    ),
                  ),
                  SizedBox(height: gap),
                  stagger(
                    140,
                    _FeatureCard(
                      height: 142,
                      radius: radius,
                      navy: navy,
                      royal: royal,
                      subtitleColor: subtitleColor,
                      stage: 'Practice',
                      icon: Icons.quiz_outlined,
                      title: 'Generate Practice Quiz',
                      subtitle: 'MCQs + short questions',
                      actionLabel: 'Generate',
                      onTap: onQuiz,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: Column(
                children: [
                  stagger(
                    70,
                    _RecordingFeatureCard(
                      height: 206,
                      radius: radius,
                      navy: navy,
                      royal: royal,
                      subtitleColor: subtitleColor,
                      ambient: ambient,
                      onTap: onRecord,
                    ),
                  ),
                  SizedBox(height: gap),
                  stagger(
                    210,
                    _FeatureCard(
                      height: 164,
                      radius: radius,
                      navy: navy,
                      royal: royal,
                      subtitleColor: subtitleColor,
                      stage: 'Insights',
                      icon: Icons.bar_chart,
                      title: 'Study Analytics Dashboard',
                      subtitle: 'Your focus & consistency trends',
                      actionLabel: 'Open',
                      onTap: onAnalytics,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.height,
    required this.radius,
    required this.navy,
    required this.royal,
    required this.subtitleColor,
    required this.stage,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final double height;
  final double radius;
  final Color navy;
  final Color royal;
  final Color subtitleColor;
  final String stage;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
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
      height: height,
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: radius,
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconChip(
                    icon: icon,
                    royal: royal,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _StagePill(stage: stage, navy: navy, royal: royal),
                  const Spacer(),
                  _PillActionButton(
                    label: actionLabel,
                    background: navy,
                    foreground: Colors.white,
                    border: Colors.transparent,
                    onTap: null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordingFeatureCard extends StatelessWidget {
  const _RecordingFeatureCard({
    required this.height,
    required this.radius,
    required this.navy,
    required this.royal,
    required this.subtitleColor,
    required this.ambient,
    required this.onTap,
  });

  final double height;
  final double radius;
  final Color navy;
  final Color royal;
  final Color subtitleColor;
  final Animation<double> ambient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: navy.withOpacity(0.07), width: 1),
      boxShadow: [
        BoxShadow(
          color: royal.withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    );

    return SizedBox(
      height: height,
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: radius,
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: ambient,
                    builder: (context, child) {
                      final t = ambient.value * math.pi * 2;
                      final scale = 1 + 0.04 * math.sin(t);
                      final glow = 0.10 + 0.10 * ((math.sin(t) + 1) / 2);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: royal.withOpacity(0.12),
                            boxShadow: [
                              BoxShadow(
                                color: royal.withOpacity(glow),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.mic,
                            color: royal,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Lecture Audio',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Convert speech to structured notes',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 28,
                child: _WaveformBars(
                  ambient: ambient,
                  color: royal,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _StagePill(stage: 'Process', navy: navy, royal: royal),
                  const Spacer(),
                  _PillActionButton(
                    label: 'Record',
                    background: navy,
                    foreground: Colors.white,
                    border: Colors.transparent,
                    onTap: null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformBars extends StatelessWidget {
  const _WaveformBars({
    required this.ambient,
    required this.color,
  });

  final Animation<double> ambient;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        final t = ambient.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(11, (i) {
            final phase = (i / 11) * math.pi * 2;
            final v = (math.sin((t * math.pi * 2) + phase) + 1) / 2;
            final h = 10 + (v * 16);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 4,
                height: h,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25 + (0.55 * v)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.royal,
  });

  final IconData icon;
  final Color royal;

  @override
  Widget build(BuildContext context) {
    const navy = _CaptureCreateNotesScreenState._navy;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: royal.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: navy.withOpacity(0.06), width: 1),
      ),
      child: Icon(icon, color: navy, size: 22),
    );
  }
}

class _StagePill extends StatelessWidget {
  const _StagePill({
    required this.stage,
    required this.navy,
    required this.royal,
  });

  final String stage;
  final Color navy;
  final Color royal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: royal.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: navy.withOpacity(0.06), width: 1),
      ),
      child: Text(
        stage,
        style: TextStyle(
          color: navy.withOpacity(0.85),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  const _PillActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Ink(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: foreground,
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

class _ProgressDashboardCard extends StatelessWidget {
  const _ProgressDashboardCard({
    required this.radius,
    required this.navy,
    required this.royal,
  });

  final double radius;
  final Color navy;
  final Color royal;

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

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
                    "Today's progress",
                    style: TextStyle(
                      color: navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _StatChip(
                    icon: Icons.note_alt_outlined,
                    text: '3 notes created',
                  ),
                  _StatChip(
                    icon: Icons.quiz_outlined,
                    text: '1 quiz generated',
                  ),
                  _StatChip(
                    icon: Icons.graphic_eq,
                    text: '25 min processed',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    const navy = _CaptureCreateNotesScreenState._navy;
    const royal = _CaptureCreateNotesScreenState._royal;

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

class _ProgressChipsRow extends StatelessWidget {
  const _ProgressChipsRow();

  @override
  Widget build(BuildContext context) {
    const navy = _CaptureCreateNotesScreenState._navy;
    const royal = _CaptureCreateNotesScreenState._royal;
    const subtitle = _CaptureCreateNotesScreenState._subtitle;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MinProgressChip(
            icon: Icons.image_outlined,
            value: '12',
            label: 'images captured',
            navy: navy,
            royal: royal,
            subtitle: subtitle,
          ),
          const SizedBox(width: 12),
          _MinProgressChip(
            icon: Icons.mic_none,
            value: '4',
            label: 'audio recorded',
            navy: navy,
            royal: royal,
            subtitle: subtitle,
          ),
          const SizedBox(width: 12),
          _MinProgressChip(
            icon: Icons.quiz_outlined,
            value: '8',
            label: 'quizzes generated',
            navy: navy,
            royal: royal,
            subtitle: subtitle,
          ),
        ],
      ),
    );
  }
}

class _MinProgressChip extends StatelessWidget {
  const _MinProgressChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.navy,
    required this.royal,
    required this.subtitle,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color navy;
  final Color royal;
  final Color subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: navy.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: royal.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [navy, royal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: subtitle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
