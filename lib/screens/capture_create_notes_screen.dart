import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/providers/document_provider.dart';
import 'package:smart_lecture_notes/providers/progress_provider.dart';
import 'package:smart_lecture_notes/providers/quiz_provider.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/screens/preview_text_screen.dart';
import 'package:smart_lecture_notes/services/ai_service.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CaptureCreateNotesScreen extends StatefulWidget {
  final String? extractedText;
  
  const CaptureCreateNotesScreen({this.extractedText, Key? key}) : super(key: key);

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
  final AiService _aiService = AiService();
  
  // OCR Editor State
  late final TextEditingController _textController;
  bool _isGeneratingNotes = false;
  
  // Speech to Text State
  late final stt.SpeechToText _speechToText;
  bool _isListening = false;
  String _textBeforeListening = '';

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    
    _textController = TextEditingController(text: widget.extractedText ?? '');
    _speechToText = stt.SpeechToText();
  }

  @override
  void dispose() {
    _ambient.dispose();
    _textController.dispose();
    if (_isListening) _speechToText.stop();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _textBeforeListening = _textController.text;
        });
        _speechToText.listen(
          onResult: (result) {
            if (!mounted) return;
            setState(() {
              final separator = _textBeforeListening.isNotEmpty && !_textBeforeListening.endsWith(' ') && !_textBeforeListening.endsWith('\n') ? ' ' : '';
              _textController.text = _textBeforeListening + separator + result.recognizedWords;
              _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
            });
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available on this device.')),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  Future<void> _generateNotes() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text')),
      );
      return;
    }

    setState(() {
      _isGeneratingNotes = true;
    });

    try {
      final summary = await _aiService.generateNotes(text, 'exam');
      
      setState(() {
        _isGeneratingNotes = false;
      });

      // Pass the original text and the new structured fields to the PreviewTextScreen
      Get.to(() => PreviewTextScreen(
        originalText: text,
        title: summary['title']?.toString() ?? 'Generated Notes',
        content: summary['content']?.toString() ?? '',
        keyPoints: List<String>.from(summary['key_points'] ?? []),
      ));
    } catch (e) {
      setState(() {
        _isGeneratingNotes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate notes: $e')),
      );
    }
  }

  Widget _buildOcrEditorView() {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Edit extracted text', style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _navy),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Review and edit extracted text...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 80),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening ? AppColors.primaryLight : _royal.withOpacity(0.1),
                            boxShadow: _isListening ? [
                              BoxShadow(color: AppColors.primaryLight.withOpacity(0.35), blurRadius: 15, spreadRadius: 5)
                            ] : [],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? Colors.white : _royal,
                            ),
                            onPressed: _listen,
                            tooltip: _isListening ? 'Stop listening' : 'Start voice typing',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isGeneratingNotes ? null : _generateNotes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _royal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isGeneratingNotes
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Generate Notes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.extractedText != null) {
      return _buildOcrEditorView();
    }
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 380 ? 18.0 : 24.0;
    final heroHeight = width < 380 ? 200.0 : 220.0;

    final items = <Widget>[
      const SizedBox(height: 12),

      // Mini Progress Chips
      const _FadeInOnBuild(
        delay: Duration(milliseconds: 0),
        child: _ProgressChipsRow(),
      ),

      const SizedBox(height: 18),
      _FadeInOnBuild(
        delay: const Duration(milliseconds: 40),
        child: SizedBox(
          height: heroHeight,
          child: _HeroCaptureCard(
            heroTag: _captureHeroTag,
            onTap: _handleCaptureBoardTap,
            navy: _navy,
            royal: _royal,
            radius: _radius,
            ambient: _ambient,
          ),
        ),
      ),

      const SizedBox(height: 18),
      const SizedBox(height: 8),

      _MosaicFeatureGrid(
        radius: _radius,
        navy: _navy,
        royal: _royal,
        subtitleColor: _subtitle,
        ambient: _ambient,
        staggerBaseMs: 120,
        onUpload: () => Navigator.of(context).pushNamed(AppRoutes.fileUpload),
        onRecord: () => Navigator.of(context).pushNamed(AppRoutes.recordAudio),
        onQuiz: () => Navigator.of(context).pushNamed(AppRoutes.generateQuiz),
        onAnalytics:
            () => Navigator.of(context).pushNamed(AppRoutes.studyAnalytics),
      ),

      const SizedBox(height: 18),
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

      const SizedBox(height: 24),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: _homeHeroTag,
              child: Material(
                color: Colors.transparent,
                child: Text(
                  'Adaptive Notes',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'AI-powered tools for classroom note creation',
              style: TextStyle(
                color: _subtitle,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: _navy.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                icon: const Icon(Icons.settings_outlined, color: _navy),
                tooltip: 'Settings',
              ),
            ),
          ),
        ],
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

  void _handleCaptureBoardTap() {
    Navigator.of(context).pushNamed(AppRoutes.adaptiveLearning);
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

class _HeroCaptureCard extends StatefulWidget {
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
  State<_HeroCaptureCard> createState() => _HeroCaptureCardState();
}

class _HeroCaptureCardState extends State<_HeroCaptureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [widget.navy, widget.royal],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(widget.radius),
      boxShadow: [
        BoxShadow(
          color: widget.royal.withOpacity(0.22),
          blurRadius: 26,
          offset: const Offset(0, 16),
        ),
      ],
    );

    return Hero(
      tag: widget.heroTag,
      child: _PressableSurface(
        onTap: widget.onTap,
        borderRadius: widget.radius,
        scaleDown: 0.985,
        decoration: decoration,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final cardHeight = constraints.maxHeight;
            final minPadding = cardWidth < 300 ? 14.0 : 20.0;
            final topBottomPadding = cardHeight < 140 ? 12.0 : 18.0;

            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.radius),
              child: Stack(
                children: [
                  // Gradient background
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.navy, widget.royal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),

                  // Abstract wave pattern (clipped)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CaptureCardWavePainter(
                        maxSize: cardWidth * 0.4,
                      ),
                    ),
                  ),

                  // Glass/blur overlay
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.03),
                              Colors.white.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Shimmer glow overlay
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      final value = _shimmerController.value;
                      return Opacity(
                        opacity: (math.sin(value * math.pi * 2) + 1) * 0.06,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.transparent,
                                Colors.white.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Floating particles (optional, light accent)
                  Positioned.fill(
                    child: _buildFloatingAccents(cardWidth, cardHeight),
                  ),

                  // Main content
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      minPadding,
                      topBottomPadding,
                      minPadding,
                      topBottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon chip with pulse
                        AnimatedBuilder(
                          animation: widget.ambient,
                          builder: (context, child) {
                            final t = widget.ambient.value * math.pi * 2;
                            final pulse = 1 + 0.05 * math.sin(t);
                            final glowOpacity = 0.10 +
                                0.14 * ((math.sin(t) + 1) / 2);
                            return Transform.scale(
                              scale: pulse,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.royal
                                          .withOpacity(glowOpacity),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Title and subtitle (flex to prevent overflow)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Adaptive Learning',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.15,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: Text(
                                  'Select your saved notes and apply smart learning modes',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.82),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Bottom row: status text + CTA button
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ready in seconds',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildGlassCTAButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassCTAButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Open',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withOpacity(0.88),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAccents(double width, double height) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: widget.ambient,
        builder: (context, child) {
          final t = widget.ambient.value * 0.5;
          return Stack(
            children: [
              Positioned(
                right: width * 0.08,
                top: height * 0.15,
                child: Opacity(
                  opacity: (math.sin(t * math.pi * 2) + 1) * 0.04,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: width * 0.16,
                top: height * 0.65,
                child: Opacity(
                  opacity: (math.sin((t + 0.5) * math.pi * 2) + 1) * 0.03,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CaptureCardWavePainter extends CustomPainter {
  final double maxSize;

  _CaptureCardWavePainter({this.maxSize = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Clipped wave pattern - constrain to safe area
    final safeRadius = math.min(size.width * 0.22, maxSize > 0 ? maxSize : 200);
    final positions = [
      Offset(size.width * 0.25, size.height * 0.55),
      Offset(size.width * 0.7, size.height * 0.35),
      Offset(size.width * 0.5, size.height * 0.8),
    ];

    for (final pos in positions) {
      canvas.drawCircle(pos, safeRadius * 0.85, paint);
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
    required this.onUpload, required this.onRecord, required this.onQuiz, required this.onAnalytics, this.staggerBaseMs = 0,
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
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
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

    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, _) {
        final progress = progressProvider.progress;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _MinProgressChip(
                icon: Icons.note_alt_outlined,
                value: progress.notesCreated.toString(),
                label: 'notes created',
                navy: navy,
                royal: royal,
                subtitle: subtitle,
              ),
              const SizedBox(width: 12),
              _MinProgressChip(
                icon: Icons.mic_none,
                value: progress.audioRecorded.toString(),
                label: 'audio recorded',
                navy: navy,
                royal: royal,
                subtitle: subtitle,
              ),
              const SizedBox(width: 12),
              _MinProgressChip(
                icon: Icons.quiz_outlined,
                value: progress.quizzesGenerated.toString(),
                label: 'quizzes generated',
                navy: navy,
                royal: royal,
                subtitle: subtitle,
              ),
            ],
          ),
        );
      },
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
