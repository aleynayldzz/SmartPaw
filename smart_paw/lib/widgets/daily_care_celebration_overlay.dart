import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Günlük bakım tamamlandığında konfeti, balon ve tebrik mesajı gösterir.
class DailyCareCelebrationOverlay extends StatefulWidget {
  const DailyCareCelebrationOverlay({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<DailyCareCelebrationOverlay> createState() =>
      _DailyCareCelebrationOverlayState();
}

class _DailyCareCelebrationOverlayState extends State<DailyCareCelebrationOverlay>
    with TickerProviderStateMixin {
  static const Duration _celebrationDuration = Duration(milliseconds: 3200);

  late final ConfettiController _confettiController;
  late final AnimationController _fadeController;
  late final AnimationController _balloonController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 2800),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _balloonController = AnimationController(
      vsync: this,
      duration: _celebrationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _confettiController.play();
    _fadeController.forward();
    _balloonController.forward();

    Future<void>.delayed(_celebrationDuration, () async {
      if (!mounted) return;
      await _fadeController.reverse();
      if (!mounted) return;
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    _balloonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.08,
                numberOfParticles: 18,
                maxBlastForce: 22,
                minBlastForce: 8,
                gravity: 0.18,
                colors: const [
                  Color(0xFFE89AA3),
                  Color(0xFFE9B23F),
                  Color(0xFF7BC67E),
                  Color(0xFF6EB5FF),
                  Color(0xFFB388FF),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _balloonController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _BalloonPainter(progress: _balloonController.value),
                  size: Size.infinite,
                );
              },
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 22,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🎉',
                          style: TextStyle(fontSize: 42),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tebrikler!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2C2825),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bugünkü tüm bakım görevlerini tamamladın.\nHarika iş çıkardın! 🐾',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5C524E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalloonPainter extends CustomPainter {
  _BalloonPainter({required this.progress});

  final double progress;

  static const List<_BalloonSpec> _balloons = [
    _BalloonSpec(
      color: Color(0xFFE89AA3),
      startX: 0.12,
      drift: 0.04,
      size: 34,
      delay: 0.0,
    ),
    _BalloonSpec(
      color: Color(0xFFE9B23F),
      startX: 0.32,
      drift: -0.05,
      size: 40,
      delay: 0.08,
    ),
    _BalloonSpec(
      color: Color(0xFF6EB5FF),
      startX: 0.68,
      drift: 0.06,
      size: 36,
      delay: 0.04,
    ),
    _BalloonSpec(
      color: Color(0xFF7BC67E),
      startX: 0.86,
      drift: -0.04,
      size: 32,
      delay: 0.12,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final balloon in _balloons) {
      final local = ((progress - balloon.delay) / (1 - balloon.delay))
          .clamp(0.0, 1.0);
      if (local <= 0) continue;

      final eased = Curves.easeOutCubic.transform(local);
      final x = size.width * balloon.startX +
          math.sin(eased * math.pi * 2) * size.width * balloon.drift;
      final y = size.height + balloon.size -
          eased * (size.height * 0.72 + balloon.size);

      _paintBalloon(
        canvas,
        Offset(x, y),
        balloon.size,
        balloon.color,
        eased,
      );
    }
  }

  void _paintBalloon(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double eased,
  ) {
    final stringPaint = Paint()
      ..color = const Color(0xFF9A8E88).withValues(alpha: 0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final tail = Offset(center.dx, center.dy + radius * 1.15);
    final stringEnd = Offset(
      center.dx + math.sin(eased * math.pi) * 6,
      center.dy + radius * 2.4,
    );
    canvas.drawLine(tail, stringEnd, stringPaint);

    final balloonRect = Rect.fromCenter(
      center: center,
      width: radius * 1.35,
      height: radius * 1.65,
    );
    final balloonPaint = Paint()..color = color;
    canvas.drawOval(balloonRect, balloonPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.22, -radius * 0.28),
        width: radius * 0.35,
        height: radius * 0.55,
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BalloonPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BalloonSpec {
  const _BalloonSpec({
    required this.color,
    required this.startX,
    required this.drift,
    required this.size,
    required this.delay,
  });

  final Color color;
  final double startX;
  final double drift;
  final double size;
  final double delay;
}
