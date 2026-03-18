import 'package:flutter/material.dart';
import 'dart:math';

class ScarabOverlay extends StatefulWidget {
  const ScarabOverlay({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Scarabs",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const ScarabOverlay();
      },
    );
  }

  @override
  State<ScarabOverlay> createState() => _ScarabOverlayState();
}

class _ScarabOverlayState extends State<ScarabOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<_Scarab> _scarabs = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        _updateScarabs();
        setState(() {});
      });

    // Spawn 15 scarabs
    for (int i = 0; i < 15; i++) {
      _scarabs.add(
        _Scarab(
          x: _random.nextDouble(), // 0.0 to 1.0 (horizontal screen pos)
          y: 1.1 + (_random.nextDouble() * 0.5), // start just below the screen
          speed: _random.nextDouble() * 0.01 + 0.005,
          wobbleFactor: _random.nextDouble() * 10,
          wobbleSpeed: _random.nextDouble() * 0.2 + 0.1,
          size: _random.nextDouble() * 15 + 25, // 25 to 40 size
        )
      );
    }

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _updateScarabs() {
    // Scarabs crawl UP the screen (decreasing Y) with a slight wobble side-to-side
    for (var scarab in _scarabs) {
      scarab.y -= scarab.speed;
      // Wobbles slightly left and right as it crawls upward
      scarab.x += sin(scarab.y * scarab.wobbleFactor) * scarab.wobbleSpeed * 0.01;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IgnorePointer(
        child: Stack(
          children: _scarabs.map((scarab) {
            final w = MediaQuery.of(context).size.width;
            final h = MediaQuery.of(context).size.height;

            return Positioned(
              left: scarab.x * w,
              top: scarab.y * h,
              child: Transform.rotate(
                // Angle slightly based on their wobble to look like they're steering
                angle: cos(scarab.y * scarab.wobbleFactor) * 0.3,
                child: Text(
                  "🪲",
                  style: TextStyle(
                    fontSize: scarab.size,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Scarab {
  double x;
  double y;
  double speed;
  double wobbleFactor;
  double wobbleSpeed;
  double size;

  _Scarab({
    required this.x,
    required this.y,
    required this.speed,
    required this.wobbleFactor,
    required this.wobbleSpeed,
    required this.size,
  });
}
