import 'package:flutter/material.dart';
import 'dart:math';

class SandstormOverlay extends StatefulWidget {
  const SandstormOverlay({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Sandstorm",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const SandstormOverlay();
      },
    );
  }

  @override
  State<SandstormOverlay> createState() => _SandstormOverlayState();
}

class _SandstormOverlayState extends State<SandstormOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<_SandParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4 second sandstorm
    )..addListener(() {
        _updateParticles();
        setState(() {});
      });

    // Initialize random setup of horizontal streaks
    for (int i = 0; i < 200; i++) {
      _particles.add(
        _SandParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          length: _random.nextDouble() * 0.1 + 0.05,
          speed: _random.nextDouble() * 2.0 + 1.0,
          opacity: _random.nextDouble() * 0.5 + 0.1,
          thickness: _random.nextDouble() * 2 + 1,
        )
      );
    }

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _updateParticles() {
    for (var particle in _particles) {
      // Wind blows backwards from Right to Left!
      particle.x -= (0.02 * particle.speed);
      if (particle.x < -particle.length) {
        particle.x = 1.0;
        particle.y = _random.nextDouble();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fade in and fade out the orange tint
    final fadeVal = (_controller.value < 0.2) 
        ? _controller.value / 0.2 
        : (_controller.value > 0.8) 
            ? (1.0 - _controller.value) / 0.2 
            : 1.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background tint
          Positioned.fill(
            child: Container(
              color: Colors.orange.shade900.withValues(alpha: 0.4 * fadeVal),
            ),
          ),
          
          // Custom painting of dust lines
          Positioned.fill(
            child: Opacity(
              opacity: fadeVal,
              child: CustomPaint(
                painter: _SandPainter(_particles),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SandParticle {
  double x;
  double y;
  double length;
  double speed;
  double opacity;
  double thickness;

  _SandParticle({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.opacity,
    required this.thickness,
  });
}

class _SandPainter extends CustomPainter {
  final List<_SandParticle> particles;

  _SandPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = Color(0xFFE6A44A).withValues(alpha: p.opacity)
        ..strokeWidth = p.thickness
        ..strokeCap = StrokeCap.round;
        
      final startX = p.x * size.width;
      final startY = p.y * size.height;
      
      final endX = (p.x + p.length) * size.width;
      final endY = startY; // perfectly horizontal fierce wind!

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SandPainter oldDelegate) => true;
}
