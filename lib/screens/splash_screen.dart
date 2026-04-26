
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _dotsController;
  
  // Waveform animation
  List<double> _waveHeights = [];
  Timer? _waveTimer;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Initialize waveform heights
    _waveHeights = _generateRandomHeights();
    
    // Start waveform animation
    _waveTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _waveHeights = _generateRandomHeights();
        });
      }
    });

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _textController.forward());
    _navigateToHome();
  }

  List<double> _generateRandomHeights() {
    return List.generate(5, (index) => 12 + _random.nextDouble() * 28);
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _dotsController.dispose();
    _waveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Subtle wave at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: size.height * 0.22,
              width: size.width,
              child: CustomPaint(
                painter: _WavePainter(),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with fade-in and scale
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.15),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ripple effect behind logo
                            _RippleEffect(controller: _logoController),
                            // Main logo
                            Image.asset(
                              'assets/images/logo.png',
                              width: 120,
                              height: 120,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Animated Voice Waveform
                  _AnimatedWaveform(heights: _waveHeights),
                  const SizedBox(height: 24),

                  // App name with slide-up
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      final slide = 32 * (1 - _textController.value);
                      return Opacity(
                        opacity: _textController.value,
                        child: Transform.translate(
                          offset: Offset(0, slide),
                          child: const Text(
                            'LectraAI',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tagline 1
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      final slide = 18 * (1 - _textController.value);
                      return Opacity(
                        opacity: _textController.value,
                        child: Transform.translate(
                          offset: Offset(0, slide),
                          child: const Text(
                            'Accessibility meets intelligent learning',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),

                  // Tagline 2
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      final slide = 10 * (1 - _textController.value);
                      return Opacity(
                        opacity: _textController.value,
                        child: Transform.translate(
                          offset: Offset(0, slide),
                          child: const Text(
                            'AI that listens, understands, and supports you',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.05,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Page indicator dots
          Positioned(
            bottom: size.height * 0.08,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _dotsController,
              builder: (context, child) {
                final t = _dotsController.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final active = i == 0;
                    final pulse = active
                        ? 1.0 + 0.18 * math.sin(t * 2 * math.pi)
                        : 1.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      width: 10 * pulse,
                      height: 10,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white38,
                        shape: BoxShape.circle,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.25),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Subtle wave painter for bottom decoration
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blueAccent.withOpacity(0.18),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.18, size.height * 0.45,
      size.width * 0.38, size.height * 0.95,
      size.width * 0.5, size.height * 0.7,
    );
    path.cubicTo(
      size.width * 0.68, size.height * 0.45,
      size.width * 0.82, size.height * 0.95,
      size.width, size.height * 0.7,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}

// Animated Voice Waveform Widget
class _AnimatedWaveform extends StatelessWidget {
  final List<double> heights;
  
  const _AnimatedWaveform({required this.heights});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(heights.length, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + index * 100),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 4,
          height: heights[index],
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      }),
    );
  }
}

// Ripple Effect Widget behind logo
class _RippleEffect extends StatefulWidget {
  final AnimationController controller;
  
  const _RippleEffect({required this.controller});

  @override
  State<_RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<_RippleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  
  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }
  
  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(2, (index) {
            final delay = index * 0.4;
            final value = (_rippleController.value + delay) % 1.0;
            final scale = 0.8 + value * 0.6;
            final opacity = (1.0 - value) * 0.3;
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(opacity),
                    width: 2,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
