import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'shell.dart';

// Portada: portal verde + logo. A los 2s pasa al Shell.
// Si la API falla, igual entra (cada pantalla carga sola).
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _a;

  @override
  void initState() {
    super.initState();
    _a = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Shell()),
        );
      }
    });
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _a,
                builder: (context, _) => SizedBox(
                  width: 148,
                  height: 148,
                  child: CustomPaint(
                    painter: _Portal(_a.value),
                    child: Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              C.neon.withValues(alpha: .95),
                              C.neon.withValues(alpha: .5),
                              C.neon.withValues(alpha: .1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: C.neon.withValues(alpha: .5),
                              blurRadius: 36 + _a.value * 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Rickpedia', style: T.logo),
              const SizedBox(height: 8),
              const Text(
                'Multiverse Character Directory',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: C.muted,
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Portal extends CustomPainter {
  final double t;
  _Portal(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(
        c,
        size.width / 2 * (.55 + i * .14) + t * 6,
        Paint()
          ..color = C.neon.withValues(alpha: .1 / i + .03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    for (var k = 0; k < 24; k++) {
      final a = k / 24 * math.pi * 2 + t * math.pi * 2;
      canvas.drawCircle(
        Offset(
          c.dx + math.cos(a) * size.width / 2 * .98,
          c.dy + math.sin(a) * size.width / 2 * .98,
        ),
        2.2,
        Paint()..color = C.neon.withValues(alpha: .5),
      );
    }
  }

  @override
  bool shouldRepaint(_Portal o) => o.t != t;
}
