import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconFloatController;
  late AnimationController _titleShimmerController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    _iconFloatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _titleShimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _iconFloatController.dispose();
    _titleShimmerController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2A8A),
      body: Stack(
        children: [
          // Premium background with gradients
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A2A8A),
                  const Color(0xFF0F3BA5),
                  const Color(0xFF0A2A8A),
                ],
              ),
            ),
          ),

          // Floating background circles
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                final t = _particleController.value;
                return Transform.translate(
                  offset: Offset(
                    math.sin(t * 2 * math.pi) * 40,
                    -math.cos(t * 2 * math.pi) * 60,
                  ),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF1E4ED8).withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: -80,
            left: -80,
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                final t = _particleController.value;
                return Transform.translate(
                  offset: Offset(
                    -math.sin(t * 1.5 * math.pi) * 30,
                    math.cos(t * 1.5 * math.pi) * 50,
                  ),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF1E4ED8).withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // Animated Hero Icon Card
                      AnimatedBuilder(
                        animation: _iconFloatController,
                        builder: (context, child) {
                          final t = _iconFloatController.value;
                          final float = math.sin(t * 2 * math.pi) * 8;

                          return Transform.translate(
                            offset: Offset(0, float),
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final pulse = 1 + (0.05 * math.sin(_pulseController.value * 2 * math.pi));

                                return Transform.scale(
                                  scale: pulse,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Radial glow
                                      Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFF1E4ED8).withOpacity(0.30),
                                              const Color(0xFF1E4ED8).withOpacity(0.10),
                                              Colors.transparent,
                                            ],
                                            stops: const [0, 0.7, 1],
                                          ),
                                        ),
                                      ),

                                      // Glassmorphic card
                                      BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white.withOpacity(0.16),
                                                Colors.white.withOpacity(0.08),
                                              ],
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.20),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF1E4ED8)
                                                    .withOpacity(0.25),
                                                blurRadius: 32,
                                                spreadRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              const Icon(
                                                Icons.auto_awesome,
                                                size: 64,
                                                color: Colors.white,
                                              ),
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: CustomPaint(
                                                    painter: _SplashSparklePainter(
                                                      phase: _iconFloatController,
                                                    ),
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
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 60),

                      // Animated title with shimmer
                      AnimatedBuilder(
                        animation: _titleShimmerController,
                        builder: (context, child) {
                          final t = _titleShimmerController.value;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Title text
                              Text(
                                'LectraAI',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),

                              // Shimmer overlay
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.4),
                                      Colors.transparent,
                                    ],
                                    stops: [
                                      t - 0.3,
                                      t,
                                      t + 0.3,
                                    ],
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'LectraAI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Premium subtitle
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.90),
                              Colors.white.withOpacity(0.70),
                            ],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'AI-powered note taking for modern classrooms',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Benefit line
                      Text(
                        'Capture, organize, and learn smarter',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Animated loading indicator
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final t = _pulseController.value;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              final delay = index / 3;
                              final progress = (t - delay).clamp(0.0, 1.0);
                              final expandProgress =
                                  (progress < 0.5) ? progress * 2 : (1 - progress) * 2;

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                width: 8 + (expandProgress * 6),
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color.lerp(
                                    Colors.white.withOpacity(0.40),
                                    const Color(0xFF1E4ED8).withOpacity(0.90),
                                    expandProgress,
                                  ),
                                  boxShadow: [
                                    if (expandProgress > 0.3)
                                      BoxShadow(
                                        color: const Color(0xFF1E4ED8)
                                            .withOpacity(0.40 * expandProgress),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                  ],
                                ),
                              );
                            }),
                          );
                        },
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Optional: Floating hint at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final opacity = 0.4 + (0.4 * math.sin(_pulseController.value * 2 * math.pi));

                return Opacity(
                  opacity: opacity,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Initializing LectraAI',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.60),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_downward_rounded,
                          size: 14,
                          color: Colors.white.withOpacity(0.60),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashSparklePainter extends CustomPainter {
  _SplashSparklePainter({required this.phase});

  final Animation<double> phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final t = phase.value;
    final paint = Paint()..style = PaintingStyle.fill;

    // Sparkle positions around the icon
    final sparkles = [
      const Offset(10, 8),
      const Offset(58, 12),
      const Offset(65, 50),
      const Offset(15, 60),
      const Offset(35, 5),
      const Offset(55, 58),
    ];

    for (final pos in sparkles) {
      final delay = (pos.dx + pos.dy) / 100;
      final phaseOffset = (t * 2 * math.pi + delay) % (2 * math.pi);
      final alpha = (0.25 + 0.60 * ((math.sin(phaseOffset) + 1) / 2)).clamp(0.0, 1.0);

      paint.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(pos, 1.2 + (0.8 * alpha), paint);
    }
  }

  @override
  bool shouldRepaint(_SplashSparklePainter oldDelegate) => true;
}
